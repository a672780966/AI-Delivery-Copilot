import json
from app.ai import validate_ai_output
from app.schemas import RequirementPool


def test_requirement_pool_schema_passes():
    sample = {
        "requirements": [
            {
                "scope": "需求 1",
                "description": "支持客户画像标签管理",
                "priority": "high",
                "acceptance_criteria": ["能够保存标签", "可按标签筛选客户"],
            }
        ],
        "project_summary": "客户需要 CRM 支持标签管理和自动同步订单数据。",
    }

    validation = validate_ai_output(sample, "requirement_pool")
    assert validation["schema_type"] == "requirement_pool"


def test_project_artifacts_schema_passes():
    sample = {
        "prd": [
            {
                "title": "客户标签管理",
                "description": "支持客户画像标签管理和标签分组。",
                "acceptance_criteria": ["可以创建标签", "可以分配标签"],
                "priority": "high",
            }
        ],
        "user_stories": [
            {
                "as_a": "销售人员",
                "i_want": "管理客户标签",
                "so_that": "可以更精准地推送活动",
                "acceptance_criteria": ["标签可归档", "标签可检索"],
            }
        ],
        "risk_radar": [
            {
                "risk": "标签标准不一致",
                "impact": "客户画像失真",
                "mitigation": "制定标签治理规则",
            }
        ],
        "knowledge_base": [
            {
                "title": "访谈摘要",
                "source": "会议纪要",
                "excerpt": "用户希望 CRM 能够分组标签并同步订单数据。",
            }
        ],
        "retrospective": [
            {
                "lesson": "在初期确认标签定义和业务规则",
                "category": "improvement",
            }
        ],
    }
    validation = validate_ai_output(sample, "project_artifacts")
    assert validation["schema_type"] == "project_artifacts"
