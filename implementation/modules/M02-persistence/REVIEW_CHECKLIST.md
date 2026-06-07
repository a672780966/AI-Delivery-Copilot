# M02 最终审查清单

> 由主审模型在本地 Codex 提交后填写。任何硬失败均返回 `CHANGES_REQUESTED`。

## A. 提交与目录

- [ ] 起始 commit 与计划基线/用户确认一致。
- [ ] `git diff --name-only <start>..<submitted>` 全部位于允许路径。
- [ ] Manifest 覆盖全部 changed file，没有幽灵文件或遗漏文件。
- [ ] 目录遵循 persistence / migration / tests 分层，没有单文件堆叠。
- [ ] roadmap 仅为 `LOCAL_SUBMITTED`，本地模型未自行标记 `APPROVED`。

## B. DDL 与 ORM

- [ ] `002` 接续而非改写 `001`。
- [ ] 8 类表、关键字段、外键、check、unique 和索引齐全。
- [ ] pgvector 扩展、vector(1024)、tsvector/GIN 或等效全文索引真实存在。
- [ ] PostgreSQL jsonb 与 ORM JSON 类型映射合理。
- [ ] ORM 与 migration 无字段名、nullable、默认值、级联策略漂移。
- [ ] 时间字段 timezone-aware。

## C. Repository 正确性

- [ ] Session 由外部注入，无全局 Session。
- [ ] 写方法不隐式 commit。
- [ ] 所有读取在 SQL 层带 tenant 条件。
- [ ] 跨租户 get/list 不泄漏数据或资源存在性。
- [ ] IntegrityError 未被吞掉。
- [ ] 未提前实现状态机、检索或业务决策。

## D. 测试与独立验证

- [ ] Reviewer 独立运行 `pytest -q tests/persistence`。
- [ ] Reviewer 独立运行 `pytest -q`。
- [ ] Reviewer 独立运行 PostgreSQL migration script。
- [ ] rollback、tenant isolation、unique、cascade 均有行为测试，不只是检查属性存在。
- [ ] 没有新增无理由 skip、弱化断言或删除既有测试。

## E. 6B 常见缺陷扫描

- [ ] 无 TODO/pass/NotImplemented 占位。
- [ ] 无内存数据结构冒充持久化。
- [ ] 无硬编码测试结果。
- [ ] 无 broad exception swallowing。
- [ ] 无逐行 commit。
- [ ] 无无租户查询。
- [ ] 无 Manifest 与代码不一致。

## 判定

- 审查结论：`PENDING`
- 硬失败：`PENDING`
- 必须返工项：`PENDING`
- 可选改进：`PENDING`
- Reviewer 独立命令结果：`PENDING`
- Roadmap 状态更新：只有全部硬门通过后改为 `APPROVED`。
