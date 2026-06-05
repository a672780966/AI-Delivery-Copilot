from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, DateTime, JSON, ForeignKey
from sqlalchemy.orm import declarative_base, relationship

Base = declarative_base()

class AuditLog(Base):
    __tablename__ = 'audit_logs'

    id = Column(Integer, primary_key=True, index=True)
    tenant_id = Column(String, nullable=False)
    user_id = Column(String, nullable=False)
    request_id = Column(String, nullable=False)
    idempotency_key = Column(String, nullable=False)
    action = Column(String, nullable=False)
    metadata_payload = Column('metadata', JSON, nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

class Project(Base):
    __tablename__ = 'projects'

    id = Column(Integer, primary_key=True, index=True)
    tenant_id = Column(String, nullable=False)
    user_id = Column(String, nullable=False)
    name = Column(String, nullable=False)
    project_type = Column(String, nullable=False)
    domain = Column(String, nullable=True)
    description = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    requirements = relationship('Requirement', back_populates='project')
    artifacts = relationship('Artifact', back_populates='project')
    risk_snapshots = relationship('RiskSnapshot', back_populates='project')
    knowledge_documents = relationship('KnowledgeDocument', back_populates='project')
    requirement_drafts = relationship('RequirementDraft', back_populates='project')

class Requirement(Base):
    __tablename__ = 'requirements'

    id = Column(Integer, primary_key=True, index=True)
    tenant_id = Column(String, nullable=False)
    user_id = Column(String, nullable=False)
    project_id = Column(Integer, ForeignKey('projects.id'), nullable=False)
    scope = Column(String, nullable=False)
    description = Column(String, nullable=False)
    priority = Column(String, nullable=False)
    acceptance_criteria = Column(JSON, nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    project = relationship('Project', back_populates='requirements')

class RequirementDraft(Base):
    __tablename__ = 'requirement_drafts'

    id = Column(Integer, primary_key=True, index=True)
    tenant_id = Column(String, nullable=False)
    user_id = Column(String, nullable=False)
    project_id = Column(Integer, ForeignKey('projects.id'), nullable=False)
    draft_text = Column(String, nullable=False)
    generated_requirements = Column(JSON, nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    project = relationship('Project', back_populates='requirement_drafts')

class Artifact(Base):
    __tablename__ = 'artifacts'

    id = Column(Integer, primary_key=True, index=True)
    tenant_id = Column(String, nullable=False)
    user_id = Column(String, nullable=False)
    project_id = Column(Integer, ForeignKey('projects.id'), nullable=False)
    artifact_type = Column(String, nullable=False)
    content = Column(JSON, nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    project = relationship('Project', back_populates='artifacts')

class RiskSnapshot(Base):
    __tablename__ = 'risk_snapshots'

    id = Column(Integer, primary_key=True, index=True)
    tenant_id = Column(String, nullable=False)
    user_id = Column(String, nullable=False)
    project_id = Column(Integer, ForeignKey('projects.id'), nullable=False)
    risks = Column(JSON, nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    project = relationship('Project', back_populates='risk_snapshots')

class KnowledgeDocument(Base):
    __tablename__ = 'knowledge_documents'

    id = Column(Integer, primary_key=True, index=True)
    tenant_id = Column(String, nullable=False)
    user_id = Column(String, nullable=False)
    project_id = Column(Integer, ForeignKey('projects.id'), nullable=False)
    title = Column(String, nullable=False)
    source = Column(String, nullable=False)
    excerpt = Column(String, nullable=False)
    content = Column(JSON, nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    project = relationship('Project', back_populates='knowledge_documents')

class AIRecord(Base):
    __tablename__ = 'ai_record'

    id = Column(Integer, primary_key=True, index=True)
    tenant_id = Column(String, nullable=False)
    user_id = Column(String, nullable=False)
    request_id = Column(String, nullable=False)
    idempotency_key = Column(String, nullable=False, unique=True)
    record_type = Column(String, nullable=False)
    payload = Column(JSON, nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
