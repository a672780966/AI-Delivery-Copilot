# AI Delivery Copilot

AI Delivery Copilot 是面向 ERP/CRM/CDP/OA 项目交付的 AI 中控系统，支持客户访谈文本导入、结构化需求提取、需求池构建、PRD/用户故事/验收标准生成、项目风险雷达、RAG 知识库和项目复盘。

## 目录结构

- `web/`: Next.js + TypeScript 前端
- `backend/`: FastAPI 后端
- `infra/`: Docker Compose、PostgreSQL、Redis、SQL migration、seed 数据
- `contracts/`: OpenAPI、JSON Schema、Prompt 模板
- `tests/`: pytest、Playwright、Prompt Eval 测试

## 快速启动

```bash
cd infra
docker compose up --build
```

然后访问：

- 前端: `http://localhost:3000`
- 后端文档: `http://localhost:8000/docs`

## 设计原则

- 所有 LLM 输出必须通过 JSON Schema 校验后才能入库
- 所有写操作必须包含 `tenant_id`、`user_id`、`request_id`、`idempotency_key`
- 所有 mutating tool call 必须写审计日志
- 所有跨系统写入均使用 mock connector
