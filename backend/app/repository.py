from typing import Any, Dict, List, Optional
from sqlalchemy import func
from app.db import SessionLocal
from app.models import (
    AIRecord,
    AuditLog,
    Artifact,
    KnowledgeDocument,
    Project,
    Requirement,
    RequirementDraft,
    RiskSnapshot,
)


class Repository:
    def __init__(self):
        self._session = SessionLocal()

    def save_record(self, tenant_id: str, user_id: str, request_id: str, idempotency_key: str, record_type: str, payload: Any) -> AIRecord:
        record = AIRecord(
            tenant_id=tenant_id,
            user_id=user_id,
            request_id=request_id,
            idempotency_key=idempotency_key,
            record_type=record_type,
            payload=payload,
        )
        self._session.add(record)
        self._session.commit()
        self._session.refresh(record)
        return record

    def save_audit(self, tenant_id: str, user_id: str, request_id: str, idempotency_key: str, action: str, metadata: Any) -> AuditLog:
        audit = AuditLog(
            tenant_id=tenant_id,
            user_id=user_id,
            request_id=request_id,
            idempotency_key=idempotency_key,
            action=action,
            metadata_payload=metadata,
        )
        self._session.add(audit)
        self._session.commit()
        self._session.refresh(audit)
        return audit

    def create_project(self, tenant_id: str, user_id: str, name: str, project_type: str, description: str, domain: Optional[str] = None) -> Project:
        project = Project(
            tenant_id=tenant_id,
            user_id=user_id,
            name=name,
            project_type=project_type,
            domain=domain,
            description=description,
        )
        self._session.add(project)
        self._session.commit()
        self._session.refresh(project)
        return project

    def list_projects(self) -> List[Project]:
        return self._session.query(Project).order_by(Project.id).all()

    def get_project(self, project_id: int) -> Optional[Project]:
        return self._session.query(Project).filter(Project.id == project_id).first()

    def save_requirement_draft(self, tenant_id: str, user_id: str, project_id: int, draft_text: str, generated_requirements: Any) -> RequirementDraft:
        draft = RequirementDraft(
            tenant_id=tenant_id,
            user_id=user_id,
            project_id=project_id,
            draft_text=draft_text,
            generated_requirements=generated_requirements,
        )
        self._session.add(draft)
        self._session.commit()
        self._session.refresh(draft)
        return draft

    def save_requirement(self, tenant_id: str, user_id: str, project_id: int, requirement_data: Dict[str, Any]) -> Requirement:
        requirement = Requirement(
            tenant_id=tenant_id,
            user_id=user_id,
            project_id=project_id,
            scope=requirement_data['scope'],
            description=requirement_data['description'],
            priority=requirement_data['priority'],
            acceptance_criteria=requirement_data['acceptance_criteria'],
        )
        self._session.add(requirement)
        self._session.commit()
        self._session.refresh(requirement)
        return requirement

    def list_requirements(self) -> List[Requirement]:
        return self._session.query(Requirement).order_by(Requirement.id).all()

    def list_risk_snapshots(self) -> List[RiskSnapshot]:
        return self._session.query(RiskSnapshot).order_by(RiskSnapshot.id).all()

    def save_artifact(self, tenant_id: str, user_id: str, project_id: int, artifact_type: str, content: Any) -> Artifact:
        artifact = Artifact(
            tenant_id=tenant_id,
            user_id=user_id,
            project_id=project_id,
            artifact_type=artifact_type,
            content=content,
        )
        self._session.add(artifact)
        self._session.commit()
        self._session.refresh(artifact)
        return artifact

    def save_risk_snapshot(self, tenant_id: str, user_id: str, project_id: int, risks: Any) -> RiskSnapshot:
        snapshot = RiskSnapshot(
            tenant_id=tenant_id,
            user_id=user_id,
            project_id=project_id,
            risks=risks,
        )
        self._session.add(snapshot)
        self._session.commit()
        self._session.refresh(snapshot)
        return snapshot

    def save_knowledge_document(self, tenant_id: str, user_id: str, project_id: int, title: str, source: str, excerpt: str, content: Any) -> KnowledgeDocument:
        document = KnowledgeDocument(
            tenant_id=tenant_id,
            user_id=user_id,
            project_id=project_id,
            title=title,
            source=source,
            excerpt=excerpt,
            content=content,
        )
        self._session.add(document)
        self._session.commit()
        self._session.refresh(document)
        return document

    def project_summary(self, project_id: int) -> Optional[Dict[str, Any]]:
        project = self.get_project(project_id)
        if not project:
            return None
        requirement_count = self._session.query(func.count(Requirement.id)).filter(Requirement.project_id == project_id).scalar()
        risk_count = self._session.query(func.count(RiskSnapshot.id)).filter(RiskSnapshot.project_id == project_id).scalar()
        knowledge_count = self._session.query(func.count(KnowledgeDocument.id)).filter(KnowledgeDocument.project_id == project_id).scalar()
        return {
            'project': project,
            'requirement_count': requirement_count,
            'risk_count': risk_count,
            'knowledge_count': knowledge_count,
        }
