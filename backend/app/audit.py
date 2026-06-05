import logging
from app.repository import Repository

logger = logging.getLogger("audit")
logger.setLevel(logging.INFO)
handler = logging.StreamHandler()
formatter = logging.Formatter("%(asctime)s [AUDIT] %(message)s")
handler.setFormatter(formatter)
logger.handlers = [handler]

repo = Repository()


def audit_log(action: str, tenant_id: str, user_id: str, request_id: str, idempotency_key: str, metadata: dict) -> None:
    logger.info(
        "action=%s tenant=%s user=%s request=%s idempotency=%s metadata=%s",
        action,
        tenant_id,
        user_id,
        request_id,
        idempotency_key,
        metadata,
    )
    repo.save_audit(
        tenant_id=tenant_id,
        user_id=user_id,
        request_id=request_id,
        idempotency_key=idempotency_key,
        action=action,
        metadata=metadata,
    )
