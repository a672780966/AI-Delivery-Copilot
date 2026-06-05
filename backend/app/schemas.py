from typing import List, Literal, Optional
from pydantic import BaseModel, Field

class BaseContext(BaseModel):
    tenant_id: str = Field(..., description="租户 ID")
    user_id: str = Field(..., description="用户 ID")
    request_id: str = Field(..., description="请求 ID")
    idempotency_key: str = Field(..., description="幂等键")

class AIImportRequest(BaseContext):
    transcript: str = Field(..., description="客户访谈或者会议纪要文本")
    project_name: Optional[str] = Field(None, description="可选项目名称，用于关联需求池")
    project_type: Optional[str] = Field(None, description="可选项目类型，例如 CRM、OA、ERP+CDP")

class GenerateArtifactsRequest(BaseContext):
    requirement_summary: str = Field(..., description="结构化需求摘要")
    project_id: Optional[int] = Field(None, description="关联的项目 ID")

class RequirementItem(BaseModel):
    scope: str
    description: str
    priority: Literal['low', 'medium', 'high']
    acceptance_criteria: List[str]

class RequirementPool(BaseModel):
    requirements: List[RequirementItem]
    project_summary: str

class PRDItem(BaseModel):
    title: str
    description: str
    acceptance_criteria: List[str]
    priority: Literal['low', 'medium', 'high']

class UserStory(BaseModel):
    as_a: str
    i_want: str
    so_that: str
    acceptance_criteria: List[str]

class RiskItem(BaseModel):
    risk: str
    impact: str
    mitigation: str

class KnowledgeEntry(BaseModel):
    title: str
    source: str
    excerpt: str

class RetrospectiveEntry(BaseModel):
    lesson: str
    category: Literal['success', 'challenge', 'improvement']

class ProjectSummary(BaseModel):
    id: int
    name: str
    project_type: str
    domain: Optional[str]
    description: str
    requirement_count: int
    risk_count: int
    knowledge_count: int

class ProjectOverviewResponse(BaseModel):
    project: ProjectSummary
    latest_artifacts: List[PRDItem]
    latest_risks: List[RiskItem]
    knowledge_documents: List[KnowledgeEntry]

class RequirementPoolResponse(BaseModel):
    record_id: int
    pool: RequirementPool
    project_id: Optional[int]

class ProjectArtifactsResponse(BaseModel):
    record_id: int
    prd: List[PRDItem]
    user_stories: List[UserStory]
    risk_radar: List[RiskItem]
    knowledge_base: List[KnowledgeEntry]
    retrospective: List[RetrospectiveEntry]

class RequirementListResponse(BaseModel):
    project_id: int
    project_name: str
    requirements: List[RequirementItem]

class RiskSnapshotResponse(BaseModel):
    project_id: int
    project_name: str
    risks: List[RiskItem]

class ValidationResponse(BaseModel):
    valid: bool
    details: dict
