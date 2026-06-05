INSERT INTO audit_logs (tenant_id, user_id, request_id, idempotency_key, action, metadata)
VALUES
  ('demo-tenant', 'demo-user', 'seed-001', 'seed-key-001', 'seed_initialize', '{"message": "initial seed"}');

INSERT INTO projects (tenant_id, user_id, name, project_type, domain, description)
VALUES
  ('demo-tenant', 'demo-user', 'CRM 客户画像项目', 'CRM', '客户管理', '为销售与运营团队构建客户画像、标签管理与订单自动同步能力。'),
  ('demo-tenant', 'demo-user', 'OA 移动审批项目', 'OA', '审批流程', '实现移动审批、流程监控与移动通知，提升审批效率。'),
  ('demo-tenant', 'demo-user', 'ERP+CDP 协同项目', 'ERP+CDP', '供应链与营销', '打通 ERP 与 CDP，支持订单同步、库存分析与客户行为洞察。');

INSERT INTO requirements (tenant_id, user_id, project_id, scope, description, priority, acceptance_criteria)
VALUES
  ('demo-tenant', 'demo-user', 1, '客户画像标签管理', '支持在 CRM 中创建、编辑、分类客户标签，并生成客户画像视图。', 'high', '["可以创建标签","可以按标签筛选客户","支持标签画像展示"]'),
  ('demo-tenant', 'demo-user', 2, '移动审批提醒', 'OA 系统需支持移动端审批提醒并可在手机上完成审批流程。', 'high', '["审批消息及时推送","审批操作支持一键完成"]'),
  ('demo-tenant', 'demo-user', 3, 'ERP 订单同步', 'ERP 与 CDP 系统之间实现订单和客户数据的自动同步。', 'high', '["完成订单同步","数据一致性校验通过"]');

INSERT INTO risk_snapshots (tenant_id, user_id, project_id, risks)
VALUES
  ('demo-tenant', 'demo-user', 1, '[{"risk": "标签定义不一致", "impact": "画像数据失真", "mitigation": "制定统一标签规范"}]'),
  ('demo-tenant', 'demo-user', 2, '[{"risk": "审批流程复杂", "impact": "用户使用率低", "mitigation": "简化审批步骤并提供默认模板"}]'),
  ('demo-tenant', 'demo-user', 3, '[{"risk": "系统接口不稳定", "impact": "数据同步延迟", "mitigation": "增加接口重试与告警机制"}]');

INSERT INTO knowledge_documents (tenant_id, user_id, project_id, title, source, excerpt, content)
VALUES
  ('demo-tenant', 'demo-user', 1, '客户画像设计要点', 'CRM 访谈', '需要支持标签管理、画像维度与客户分群。', '{"notes": "标签分群、画像维度、营销洞察"}'),
  ('demo-tenant', 'demo-user', 2, '移动审批最佳实践', 'OA 访谈', '移动审批需包含提醒、记录与审批权限控制。', '{"notes": "提醒机制、审批记录、权限校验"}'),
  ('demo-tenant', 'demo-user', 3, 'ERP-CDP 数据同步策略', 'ERP/CDP 访谈', '数据同步需要同步订单、客户信息，并保障实时性。', '{"notes": "订单同步、客户信息、实时分析"}');

INSERT INTO artifacts (tenant_id, user_id, project_id, artifact_type, content)
VALUES
  ('demo-tenant', 'demo-user', 1, 'project_artifacts', '{"prd": [{"title": "CRM 客户画像目标","description": "构建客户画像和标签管理能力。","acceptance_criteria": ["能创建标签","能查看画像"],"priority": "high"}], "user_stories": [{"as_a": "销售","i_want": "管理客户标签","so_that": "提升营销精准度","acceptance_criteria": ["标签可创建","画像可展示"]}], "risk_radar": [{"risk": "标签不一致","impact": "数据混乱","mitigation": "标签治理机制"}], "knowledge_base": [{"title": "CRM 访谈摘要","source": "客户会议","excerpt": "需要支持标签管理与自动同步订单数据。"}], "retrospective": [{"lesson": "早期明确标签定义","category": "improvement"}]}'),
  ('demo-tenant', 'demo-user', 2, 'project_artifacts', '{"prd": [{"title": "OA 移动审批目标","description": "实现移动审批与提醒流程。","acceptance_criteria": ["支持审批提醒","支持一键审批"],"priority": "high"}], "user_stories": [{"as_a": "主管","i_want": "在手机上审批请求","so_that": "减少审批延迟","acceptance_criteria": ["移动提醒","审批记录"]}], "risk_radar": [{"risk": "流程复杂","impact": "拒绝使用","mitigation": "精简审批环节"}], "knowledge_base": [{"title": "OA 访谈摘要","source": "项目调研","excerpt": "移动审批需支持提醒和简单操作。"}], "retrospective": [{"lesson": "优先优化用户体验","category": "improvement"}]}'),
  ('demo-tenant', 'demo-user', 3, 'project_artifacts', '{"prd": [{"title": "ERP+CDP 数据协同目标","description": "打通订单与客户数据，实现营销与库存策略。","acceptance_criteria": ["订单同步准确","客户数据一致"],"priority": "high"}], "user_stories": [{"as_a": "运营","i_want": "实时查看订单与客户行为","so_that": "快速决策","acceptance_criteria": ["订单数据更新","客户画像同步"]}], "risk_radar": [{"risk": "接口异常","impact": "同步失败","mitigation": "增加重试机制"}], "knowledge_base": [{"title": "ERP-CDP 访谈摘要","source": "系统调研","excerpt": "需要同步订单、库存和客户行为数据。"}], "retrospective": [{"lesson": "优先稳定接口","category": "improvement"}]}');
