from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_import_notes_endpoint_returns_requirement_pool():
    response = client.post(
        "/api/v1/import-notes",
        json={
            "tenant_id": "demo-tenant",
            "user_id": "demo-user",
            "request_id": "req-1",
            "idempotency_key": "id-1",
            "transcript": "客户希望CRM支持客户画像标签管理，自动同步订单数据，并提供审批提醒。",
        },
    )
    assert response.status_code == 200
    body = response.json()
    assert "record_id" in body
    assert body["pool"]["project_summary"].startswith("客户希望CRM支持客户画像标签管理")
    assert len(body["pool"]["requirements"]) > 0


def test_generate_artifacts_endpoint_returns_project_artifacts():
    response = client.post(
        "/api/v1/generate-artifacts",
        json={
            "tenant_id": "demo-tenant",
            "user_id": "demo-user",
            "request_id": "req-2",
            "idempotency_key": "art-1",
            "requirement_summary": "生成客户画像标签管理和审批提醒功能。",
        },
    )
    assert response.status_code == 200
    body = response.json()
    assert body["record_id"] > 0
    assert isinstance(body["prd"], list)
    assert isinstance(body["user_stories"], list)
    assert isinstance(body["risk_radar"], list)
    assert isinstance(body["knowledge_base"], list)
    assert isinstance(body["retrospective"], list)
