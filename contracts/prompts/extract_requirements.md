# Extract Requirements Prompt

从客户访谈或会议纪要文本中提取结构化需求。输出必须符合 `requirement_pool` JSON Schema。

输入示例：
```
客户希望CRM支持客户画像标签管理，自动同步订单数据，支持移动审批流程。
```

输出要求：
- `requirements` 数组
- 每个需求包含 `scope`、`description`、`priority`、`acceptance_criteria`
- `project_summary` 概要客户目标
