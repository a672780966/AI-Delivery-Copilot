# M02 计划：PostgreSQL 持久化与迁移

> 本文件由 Planner 编写。它是实施计划，不是完成声明。本模块产品代码必须由本地 Codex 实现，最终由 Reviewer 审查。

## 1. 基线与目标

- 规划基线 commit：`695c869`
- 前置模块：M01（规划与交接规范，`APPROVED`）
- 当前事实：仓库已有业务原型表、SQLAlchemy 模型和 `001_create_tables.sql`，但 Harness 的 run/node/attempt/memory/document chunk 数据模型尚未实现。
- 唯一目标：为后续状态机、Agent Loop、记忆和 RAG 建立真实 PostgreSQL 持久化基线，不实现状态机迁移、模型调用、RAG 检索、JWT/RLS 或 API 路由。

## 2. 允许与禁止范围

### 允许修改

```text
backend/app/models.py
backend/app/db.py
backend/app/persistence/             # 新建
infra/migrations/002_harness_core.sql# 新建
infra/apply_migrations.sh
infra/docker-compose.yml             # 仅在 pgvector 镜像确有必要时修改
backend/requirements.txt             # 仅增加本模块直接依赖
backend/requirements-dev.txt         # 如测试工具需要可新建
scripts/test_migrations.sh           # 可新建
scripts/test_persistence.sh          # 可新建
tests/persistence/                   # 新建
implementation/modules/M02-persistence/IMPLEMENTATION_MANIFEST.yaml
implementation/modules/M02-persistence/LOCAL_REPORT.md
implementation/roadmap.yaml          # 本地模型只能改为 LOCAL_SUBMITTED
```

### 禁止修改

```text
backend/app/main.py
backend/app/repository.py            # 既有业务 repository 本模块不重构
backend/app/ai.py
backend/app/schemas.py
web/
contracts/openapi.yaml
blueprints/
implementation/modules/M03-*/ 及后续模块
```

如果实现必须越界，停止编码，在 `LOCAL_REPORT.md` 中写明阻塞，不得自行扩大范围。

## 3. 预期产品目录

```text
backend/app/persistence/
├── __init__.py
├── harness_models.py        # Harness ORM 模型；不得放业务服务逻辑
├── repositories.py          # Run/Node/Attempt/Memory/Document 的持久化操作
└── types.py                 # 仅在共享枚举/类型确有必要时建立

infra/migrations/
└── 002_harness_core.sql     # PostgreSQL/pgvector DDL、索引、约束

tests/persistence/
├── test_harness_models.py
├── test_harness_repositories.py
└── test_migration_contract.py
```

本地模型可少建文件，但必须在 Manifest 中解释；不得把所有 ORM、repository 和测试塞进单个大文件。

## 4. 数据模型约束

本模块至少建立：

1. `harness_runs`
   - UUID 主键；`tenant_id`、`blueprint_name`、`goal`、`status`、`repo_ref`、`provider_route`、`created_by`、时间戳。
   - 状态只允许 `queued/running/succeeded/failed/rolled_back`。
2. `harness_nodes`
   - UUID 主键；外键到 run 并 `ON DELETE CASCADE`。
   - `phase`、目标、作用域、验收、重试次数、checkpoint、时间戳。
   - `retry_count >= 0`，`max_retries` 合理限定；本模块只存储 phase，不实现迁移规则。
3. `harness_node_attempts`
   - UUID 主键；node 外键；`phase`、`attempt_no`、request/response/provider meta、eval/verify 结果、时间戳。
   - `(node_id, phase, attempt_no)` 唯一。
4. `harness_memory_short`
   - tenant/run/node 关联、key、summary、payload、expires_at、created_at。
5. `harness_memory_long`
   - tenant、scope、topic、summary、evidence、confidence、embedding、embedding_model、时间戳。
6. `harness_documents`
   - tenant、project_code、source_type、title、external_ref、metadata、raw_text、parse_status、时间戳。
7. `harness_document_chunks`
   - document 外键、tenant、element_id、chunk_index/kind/text、metadata、tsvector、embedding、embedding_model。
   - `(document_id, element_id, chunk_index)` 唯一。
8. `harness_audit_logs`
   - tenant、actor、action、resource、outcome、脱敏 details、IP、user-agent、时间戳。

### 命名与兼容

- 新表统一使用 `harness_` 前缀，避免与现有 `audit_logs`、`projects` 等原型表冲突。
- PostgreSQL 使用 `jsonb`；SQLite 测试可由 SQLAlchemy JSON 兼容，但 PostgreSQL 专有 DDL 必须由迁移契约测试检查。
- 向量维度读取环境变量/配置时必须有单一明确来源；迁移文件可使用 MVP 固定 1024，但 ORM 和报告必须说明维度变更需要新迁移，不能静默混用。
- 所有时间使用 timezone-aware UTC。

## 5. Repository 行为约束

Repository 必须：

- 由调用方注入 `Session`，禁止模块 import 时创建全局 Session。
- 写操作使用 `flush`，事务提交/回滚由调用方或明确的 transaction context 管理；禁止每写一行就隐式 commit。
- 所有读取方法必须显式接收 `tenant_id` 并在 SQL 查询中使用，不允许查出后在 Python 过滤。
- `get_*` 越租户访问返回 `None`，不暴露资源存在性。
- 创建 node 前由数据库外键保证 run 存在；repository 不吞 `IntegrityError`。
- 为 run、node、attempt 提供最小 create/get/list；memory/document 只实现后续模块所需的 create/get 基础方法，不提前实现检索或蒸馏。

## 6. 本地模型生成顺序

1. **基线检查**：记录 `git rev-parse HEAD`、`git status --porcelain`，读取现有 migration/model/db 测试。
2. **先写迁移契约测试**：检查表名、外键、唯一/check 约束、关键索引、pgvector/tsvector 声明。
3. **编写 `002_harness_core.sql`**：可重复执行扩展创建；不得修改 `001`。
4. **编写 ORM 模型测试与模型**：表名、字段、外键、默认值与 SQL migration 对齐。
5. **编写 repository 测试与实现**：重点覆盖 tenant 隔离、事务不自动提交、唯一约束、级联删除。
6. **补充 PostgreSQL 集成脚本**：启动临时数据库、顺序执行 `001` 与 `002`、二次执行迁移或验证幂等策略、检查关键表/约束。
7. **全量回归**：运行本计划全部命令，修复而不是跳过。
8. **填写 Manifest 与 Local Report**：每个 changed file 必须映射目标和测试。
9. **提交**：仅提交 M02，roadmap 状态改为 `LOCAL_SUBMITTED`，不得改为 `APPROVED`。

## 7. 验收标准

- [ ] 新迁移可在干净 PostgreSQL 上接续 `001` 成功执行。
- [ ] 8 类 Harness 表全部存在，关键外键、唯一/check 约束与索引可查询证明。
- [ ] pgvector 扩展和 1024 维 embedding 列存在；chunk 全文索引存在。
- [ ] ORM metadata 与迁移的核心字段一致，无运行时 `create_all` 代替迁移的声明。
- [ ] Repository 查询全部 tenant scoped，并有跨租户不可见测试。
- [ ] Repository 不自行 commit，调用方 rollback 后数据不可见。
- [ ] node attempt 唯一性与 run→node→attempt 级联删除有测试。
- [ ] 现有 5 项或更多原型测试全部回归通过。
- [ ] Manifest 覆盖所有 changed file，目录职责清晰。
- [ ] 无 M03 及以后逻辑。

## 8. 停止条件

出现以下情况应停止并报告，不要猜测：

- 需要改变现有业务表含义或破坏兼容。
- 本机无法运行 Docker/PostgreSQL，且无法提供迁移集成证据。
- pgvector 镜像或版本与环境冲突。
- 需要修改禁止路径才能完成。
- 全量回归出现与本模块无关但无法解释的失败。
