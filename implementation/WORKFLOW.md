# AI Delivery Copilot 分工与交付流程

本目录只承载实施计划、约束、交接清单和审查结果，不承载产品运行时代码。

## 固定角色

| 角色 | 负责人 | 可以做 | 不可以做 |
| --- | --- | --- | --- |
| Planner | 主审模型（ChatGPT） | 阅读仓库、拆模块、定义目录、约束、验收、测试与回滚计划 | 代替本地模型实现业务代码 |
| Implementer | 本地 6B Codex | 严格按单个模块任务包修改代码、自测、自评估、提交代码 | 修改任务包外目录、改变架构目标、同时实现后续模块 |
| Reviewer | 主审模型（ChatGPT） | 在本地模型提交后检查 diff、架构、标准、测试、风险并决定通过/返工 | 未审查就把模块标记为完成 |

同一模块必须按顺序经历：

```text
PLAN_READY → LOCAL_IMPLEMENTING → LOCAL_SUBMITTED → REVIEWING
           → APPROVED
           → CHANGES_REQUESTED → LOCAL_IMPLEMENTING
```

## 每个新聊天窗口的正确用法

### 1. 规划窗口（交给主审模型）

用户只需说：

> 规划模块 Mxx，不要写业务代码。

主审模型必须：

1. 检查当前分支、提交和依赖模块审查结果。
2. 阅读相关现有代码，不凭报告假设仓库结构。
3. 生成或更新该模块目录中的四个文件：
   - `PLAN.md`
   - `LOCAL_MODEL_TASK.md`
   - `IMPLEMENTATION_MANIFEST.template.yaml`
   - `REVIEW_CHECKLIST.md`
4. 明确本地模型允许修改和禁止修改的目录。
5. 给出生成步骤、逐步测试、全量回归、失败回滚和提交格式。
6. **不实现该模块产品代码。**

### 2. 本地模型编码窗口

把模块的 `LOCAL_MODEL_TASK.md` 原样交给本地 Codex。它必须：

1. 先输出自己的执行计划和起始 commit。
2. 只修改允许目录。
3. 边写边运行最小测试，最后运行任务包中的全量命令。
4. 填写 `IMPLEMENTATION_MANIFEST.yaml`，逐文件说明目录、职责、目标和测试。
5. 填写 `LOCAL_REPORT.md`，记录真实命令、结果、自评分和残留风险。
6. 提交代码，并把 commit hash 返回给用户。

### 3. 最终审查窗口（交给主审模型）

用户提供本地模型的 commit hash，或说明代码已上传。主审模型必须：

1. 比较规划起始 commit 与本地提交的完整 diff。
2. 先检查越界文件，再检查目录结构和 Manifest 是否与 diff 一致。
3. 阅读实现代码，重点寻找 6B 模型常见问题：伪实现、硬编码、吞异常、测试只测 mock、缺少事务、租户泄漏、幂等缺失、错误状态跳转。
4. 独立运行测试和静态检查，不能只相信 `LOCAL_REPORT.md`。
5. 按 `REVIEW_CHECKLIST.md` 给出逐项结论：`PASS`、`FAIL` 或 `NEEDS_EVIDENCE`。
6. 将结果写入 `implementation/reviews/Mxx-review.md`。
7. 只有主审模型可以把 roadmap 状态改为 `APPROVED`；否则标记 `CHANGES_REQUESTED` 并给出最小返工清单。

## 目录可见性要求

每个模块必须有自己的目录：

```text
implementation/modules/Mxx-name/
├── PLAN.md                              # 主审模型编写
├── LOCAL_MODEL_TASK.md                  # 主审模型交给本地 Codex
├── IMPLEMENTATION_MANIFEST.template.yaml# 主审模型定义字段
├── IMPLEMENTATION_MANIFEST.yaml         # 本地模型填写并提交
├── LOCAL_REPORT.md                      # 本地模型填写并提交
└── REVIEW_CHECKLIST.md                  # 主审模型最终审查依据
```

产品代码继续放在正常业务目录。Manifest 必须把产品目录映射到模块目标，使主审模型可以快速判断“在哪里实现了什么、由什么测试证明”。
