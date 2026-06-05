from typing import Any


class MockExternalSystemConnector:
    """用于跨系统写入的 mock connector，禁止直接写入真实 ERP/CRM/OA/CDP。"""

    def write(self, system: str, payload: Any) -> dict:
        return {
            "system": system,
            "status": "mocked",
            "payload": payload,
        }


mock_connector = MockExternalSystemConnector()
