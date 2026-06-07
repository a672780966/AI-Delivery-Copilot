# Reviewer 输出目录

每次本地模型提交后，主审模型在这里创建 `Mxx-review.md`。审查报告至少包含：

- 规划起始 commit 与本地提交 commit；
- diff 范围和 Manifest 一致性；
- 目录/架构检查；
- 关键代码问题，按严重度排序并引用文件行号；
- 独立执行的命令和真实结果；
- 每条验收标准的 `PASS/FAIL/NEEDS_EVIDENCE`；
- `APPROVED` 或 `CHANGES_REQUESTED` 结论；
- 如果返工，只给最小修复清单，不替本地模型直接重写模块。
