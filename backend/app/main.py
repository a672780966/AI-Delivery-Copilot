from typing import List

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from jsonschema.exceptions import ValidationError as JSONSchemaValidationError
from app.schemas import (
    AIImportRequest,
    GenerateArtifactsRequest,
    ProjectArtifactsResponse,
    ProjectOverviewResponse,
    ProjectSummary,
    RequirementListResponse,
    RequirementPoolResponse,
    RiskSnapshotResponse,
    ValidationResponse,
)
from app.ai import (
    extract_structured_requirements,
    generate_project_artifacts,
    validate_ai_output,
)
from app.mock_connectors import mock_connector
from app.repository import Repository
from app.audit import audit_log
from app.db import init_db

app = FastAPI(
    title="AI Delivery Copilot",
    version="0.1.0",
    description="面向 ERP/CRM/CDP/OA 项目交付的 AI 中控系统。",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

init_db()
repo = Repository()

@app.post("/api/v1/import-notes", response_model=RequirementPoolResponse)
def import_notes(payload: AIImportRequest):
    audit_log("import_notes", payload.tenant_id, payload.user_id, payload.request_id, payload.idempotency_key, {
        "transcript_length": len(payload.transcript),
        "project_name": payload.project_name,
        "project_type": payload.project_type,
    })

    requirements = extract_structured_requirements(payload.transcript)
    validate_ai_output(requirements, "requirement_pool")

    project_name = payload.project_name or "Demo 项目"
    project_type = payload.project_type or "CRM"
    project_description = f"基于访谈生成的 {project_type} 项目需求池"
    project = repo.create_project(
        tenant_id=payload.tenant_id,
        user_id=payload.user_id,
        name=project_name,
        project_type=project_type,
        description=project_description,
        domain=project_type,
    )

    draft = repo.save_requirement_draft(
        tenant_id=payload.tenant_id,
        user_id=payload.user_id,
        project_id=project.id,
        draft_text=payload.transcript,
        generated_requirements=requirements,
    )
    audit_log("save_requirement_draft", payload.tenant_id, payload.user_id, payload.request_id, payload.idempotency_key, {
        "draft_id": draft.id,
        "project_id": project.id,
    })

    saved_reqs = []
    for requirement in requirements["requirements"]:
        saved = repo.save_requirement(
            tenant_id=payload.tenant_id,
            user_id=payload.user_id,
            project_id=project.id,
            requirement_data=requirement,
        )
        saved_reqs.append(saved.id)

    external_write = mock_connector.write("crm", {
        "source": "meeting_notes",
        "project_id": project.id,
        "requirements": requirements,
    })
    audit_log("mock_cross_system_write", payload.tenant_id, payload.user_id, payload.request_id, payload.idempotency_key, external_write)

    record = repo.save_record(
        tenant_id=payload.tenant_id,
        user_id=payload.user_id,
        request_id=payload.request_id,
        idempotency_key=payload.idempotency_key,
        record_type="requirement_pool",
        payload={
            "project_id": project.id,
            "requirements": requirements,
        },
    )
    return {"record_id": record.id, "pool": requirements, "project_id": project.id}

@app.post("/api/v1/generate-artifacts", response_model=ProjectArtifactsResponse)
def generate_artifacts(payload: GenerateArtifactsRequest):
    audit_log("generate_artifacts", payload.tenant_id, payload.user_id, payload.request_id, payload.idempotency_key, {
        "requirement_summary": payload.requirement_summary[:120],
        "project_id": payload.project_id,
    })

    outputs = generate_project_artifacts(payload.requirement_summary)
    validate_ai_output(outputs, "project_artifacts")

    project_id = payload.project_id
    if project_id is not None:
        project = repo.get_project(project_id)
        if project:
            repo.save_artifact(
                tenant_id=payload.tenant_id,
                user_id=payload.user_id,
                project_id=project.id,
                artifact_type="project_artifacts",
                content=outputs,
            )
            repo.save_risk_snapshot(
                tenant_id=payload.tenant_id,
                user_id=payload.user_id,
                project_id=project.id,
                risks=outputs["risk_radar"],
            )
            for knowledge in outputs["knowledge_base"]:
                repo.save_knowledge_document(
                    tenant_id=payload.tenant_id,
                    user_id=payload.user_id,
                    project_id=project.id,
                    title=knowledge["title"],
                    source=knowledge["source"],
                    excerpt=knowledge["excerpt"],
                    content=knowledge,
                )
            audit_log("save_project_artifacts", payload.tenant_id, payload.user_id, payload.request_id, payload.idempotency_key, {
                "project_id": project.id,
                "artifact_type": "project_artifacts",
            })

    external_write = mock_connector.write("project_knowledge_base", outputs["knowledge_base"])
    audit_log("mock_cross_system_write", payload.tenant_id, payload.user_id, payload.request_id, payload.idempotency_key, external_write)

    record = repo.save_record(
        tenant_id=payload.tenant_id,
        user_id=payload.user_id,
        request_id=payload.request_id,
        idempotency_key=payload.idempotency_key,
        record_type="project_artifacts",
        payload=outputs,
    )
    return {"record_id": record.id, **outputs}

@app.get("/api/v1/projects", response_model=List[ProjectSummary])
def list_projects():
    projects = repo.list_projects()
    summaries = []
    for project in projects:
        summary = repo.project_summary(project.id)
        summaries.append(
            ProjectSummary(
                id=project.id,
                name=project.name,
                project_type=project.project_type,
                domain=project.domain,
                description=project.description,
                requirement_count=summary["requirement_count"],
                risk_count=summary["risk_count"],
                knowledge_count=summary["knowledge_count"],
            )
        )
    return summaries

@app.get("/api/v1/projects/{project_id}", response_model=ProjectOverviewResponse)
def get_project(project_id: int):
    project = repo.get_project(project_id)
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    summary = repo.project_summary(project_id)
    artifacts = [
        output for output in project.artifacts if output.artifact_type == "project_artifacts"
    ]
    latest_artifacts = []
    if artifacts:
        latest = artifacts[-1].content
        latest_artifacts = latest.get("prd", [])
    return ProjectOverviewResponse(
        project=ProjectSummary(
            id=project.id,
            name=project.name,
            project_type=project.project_type,
            domain=project.domain,
            description=project.description,
            requirement_count=summary["requirement_count"],
            risk_count=summary["risk_count"],
            knowledge_count=summary["knowledge_count"],
        ),
        latest_artifacts=latest_artifacts,
        latest_risks=project.risk_snapshots[-1].risks if project.risk_snapshots else [],
        knowledge_documents=[
            {
                "title": doc.title,
                "source": doc.source,
                "excerpt": doc.excerpt,
            }
            for doc in project.knowledge_documents
        ],
    )

@app.get("/api/v1/requirements", response_model=List[RequirementListResponse])
def list_requirements():
    requirements = repo.list_requirements()
    grouped = {}
    for req in requirements:
        project = repo.get_project(req.project_id)
        key = req.project_id
        if key not in grouped:
            grouped[key] = {
                "project_id": req.project_id,
                "project_name": project.name if project else "Unknown",
                "requirements": [],
            }
        grouped[key]["requirements"].append({
            "scope": req.scope,
            "description": req.description,
            "priority": req.priority,
            "acceptance_criteria": req.acceptance_criteria,
        })
    return [RequirementListResponse(**item) for item in grouped.values()]

@app.get("/api/v1/risk-snapshots", response_model=List[RiskSnapshotResponse])
def list_risk_snapshots():
    snapshots = repo.list_risk_snapshots()
    results = []
    for snapshot in snapshots:
        project = repo.get_project(snapshot.project_id)
        results.append(
            RiskSnapshotResponse(
                project_id=snapshot.project_id,
                project_name=project.name if project else "Unknown",
                risks=snapshot.risks,
            )
        )
    return results

@app.post("/api/v1/validate-output", response_model=ValidationResponse)
def validate_output(payload: dict):
    schema_type = payload.get("schema_type", "project_artifacts")
    try:
        result = validate_ai_output(payload, schema_type)
        return {"valid": True, "details": result}
    except (JSONSchemaValidationError, ValueError) as exc:
        raise HTTPException(status_code=400, detail=str(exc))
