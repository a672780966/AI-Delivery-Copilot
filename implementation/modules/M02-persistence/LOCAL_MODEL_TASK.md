# 给本地 Codex 的任务：M02 PostgreSQL 持久化与迁移

你是本模块的 **Implementer**。主审模型负责规划和最终审查；你负责严格按计划编码、自测、自评估并提交。不要实现 M03 或后续模块。

## 第一步：只读确认

在修改文件前依次执行并报告：

```bash
git status --short --branch
git rev-parse HEAD
find .. -name AGENTS.md -print
sed -n '1,260p' implementation/modules/M02-persistence/PLAN.md
```

若工作区不干净、起始 commit 与用户确认基线不一致、或存在未读取的 AGENTS.md，停止。

然后先输出不超过 12 步的执行计划，每步必须包含：目标文件、要实现的行为、对应测试。计划输出后直接继续实施，除非命中 PLAN 的停止条件。

## 唯一目标

实现 `PLAN.md` 定义的 PostgreSQL Harness 持久化基线：迁移、ORM、tenant-scoped repositories 和验证测试。不得实现 API、状态机、Agent、Provider、RAG 查询、安全认证或 Worker。

## 目录约束

只允许修改 `PLAN.md` 的“允许修改”列表。开始编码后，每次准备创建新文件前，先确认其位于允许路径；不在列表就停止。

## 强制生成步骤

1. 先写失败的 migration contract tests。
2. 实现 `002_harness_core.sql`，不得改写 `001_create_tables.sql`。
3. 写失败的 ORM contract tests，再实现 ORM。
4. 写失败的 repository 行为测试，再实现 repository。
5. 实现 PostgreSQL 集成验证脚本。
6. 执行局部测试；失败时修复根因，不得删除/放宽测试。
7. 执行全量回归和 diff 检查。
8. 填写 `IMPLEMENTATION_MANIFEST.yaml` 和 `LOCAL_REPORT.md`。
9. 将 roadmap 的 M02 状态从 `PLAN_READY` 改为 `LOCAL_SUBMITTED`。
10. 提交，commit message：`M02: implement harness persistence baseline`。

## 强制检查与验证

至少运行：

```bash
python -m compileall -q backend/app
pytest -q tests/persistence
pytest -q
bash scripts/test_migrations.sh
bash scripts/test_persistence.sh
git diff --check
git status --short
```

如果 Docker/PostgreSQL 命令因环境限制无法执行，不能把模块自评为通过；在报告中标记 `BLOCKED_FOR_REVIEW` 并保留失败输出摘要。

## 6B 模型特别约束

- 不要用内存 dict/SQLite 行为冒充 PostgreSQL 验收。
- 不要捕获 `Exception` 后返回空值。
- 不要在 repository 内自动 commit。
- 不要遗漏 `tenant_id` 查询条件。
- 不要为了测试通过硬编码表名列表或返回值。
- 不要把 SQL migration 与 ORM 写成两套不同字段。
- 不要删除现有测试、降低断言或加无理由的 `skip`。
- 不要声称“已支持 RLS/状态机/RAG”；本模块没有实现这些目标。

## 必须随提交附带的目录说明

复制 `IMPLEMENTATION_MANIFEST.template.yaml` 为 `IMPLEMENTATION_MANIFEST.yaml` 并填写。每个 changed file 都必须列出：

- 所属目录和层级职责；
- 实现了哪个目标；
- 关键类/函数/表；
- 对应测试；
- 已知限制。

缺少 Manifest 或 Manifest 与 `git diff --name-only` 不一致，最终审查直接退回。

## 本地自评估

在 `LOCAL_REPORT.md` 中按 100 分自评：

- 数据模型与迁移一致性：25
- tenant/事务/约束正确性：25
- PostgreSQL 真实验证：20
- 测试质量：15
- 目录与代码可维护性：10
- 范围纪律：5

低于 90 分不得提交为 `LOCAL_SUBMITTED`。本地评分仅供参考，最终是否通过由主审模型决定。

## 最终回复

只报告：

1. commit hash；
2. changed file 目录树；
3. 各目标对应文件；
4. 验证命令及真实结果；
5. 自评分和扣分；
6. 阻塞与剩余风险。
