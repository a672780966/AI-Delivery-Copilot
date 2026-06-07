# AI Delivery Copilot

AI Delivery Copilot 是面向 ERP/CRM/CDP/OA 项目交付的 AI 中控系统。

## 本项目的 AI 编码分工

本项目明确采用三段式分工，而不是让主审模型直接完成所有代码：

1. **主审模型做计划**：拆模块、指定目录、约束、生成步骤、验收和回滚，不代写模块产品代码。
2. **本地 6B Codex 编码**：读取模块任务包，小步生成、回测、自评估，提交 Manifest、Local Report 和代码 commit。
3. **主审模型最终审查**：独立检查 diff、目录、代码标准和测试，决定 `APPROVED` 或 `CHANGES_REQUESTED`。

完整流程见 [`implementation/WORKFLOW.md`](implementation/WORKFLOW.md)，模块状态见 [`implementation/roadmap.yaml`](implementation/roadmap.yaml)。

## 下一步：把 M02 交给本地模型

M02 规划包已经准备好：

```text
implementation/modules/M02-persistence/
├── PLAN.md
├── LOCAL_MODEL_TASK.md
├── IMPLEMENTATION_MANIFEST.template.yaml
└── REVIEW_CHECKLIST.md
```

在本地 Codex 的新窗口中，将 `LOCAL_MODEL_TASK.md` 原样交给模型。它完成并推送/提交后，在新的主审窗口中提供 commit hash，并说：

> 审查本地模型提交的 M02，不要替它扩展功能。

主审模型将依据 Manifest、Review Checklist 和独立回测完成最终审查。

## 原有仓库结构

- `web/`: Next.js + TypeScript 前端
- `backend/`: FastAPI 后端
- `infra/`: Docker Compose、PostgreSQL、Redis、SQL migration、seed 数据
- `contracts/`: OpenAPI、JSON Schema、Prompt 模板
- `tests/`: pytest、Playwright、Prompt Eval 测试
- `implementation/`: 计划、本地模型任务包、实现清单和最终审查报告

## 快速启动现有原型

```bash
cd infra
docker compose up --build
```

- 前端：`http://localhost:3000`
- 后端文档：`http://localhost:8000/docs`

## 设计原则

- 所有 LLM 输出必须通过 JSON Schema 校验后才能入库。
- 所有写操作必须包含 `tenant_id`、`user_id`、`request_id`、`idempotency_key`。
- 所有 mutating tool call 必须写审计日志。
- 所有跨系统写入均使用 mock connector，直到对应模块经主审批准替换。
- 本地模型不得自行把模块标记为 `APPROVED`。
