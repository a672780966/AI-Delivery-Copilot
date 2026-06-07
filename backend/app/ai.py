import re
from typing import Any
from jsonschema import validate
from app.schemas import RequirementPool, ProjectArtifactsResponse, RequirementItem, PRDItem, UserStory, RiskItem, KnowledgeEntry, RetrospectiveEntry
from pathlib import Path
import json

SCHEMA_PATH = Path(__file__).resolve().parent.parent.parent / "contracts" / "schemas" / "ai_output.json"
SCHEMAS = {}

if SCHEMA_PATH.exists():
    with open(SCHEMA_PATH, "r", encoding="utf-8") as schema_file:
        SCHEMAS = json.load(schema_file)


def _normalize_transcript(transcript: str) -> str:
    return re.sub(r"\s+", " ", transcript.strip())


def extract_structured_requirements(transcript: str) -> dict:
    text = _normalize_transcript(transcript)
    sentences = re.split(r'[。.!？?]+', text)
    sentences = [sentence.strip() for sentence in sentences if sentence.strip()]
    requirements = []
    for idx, sentence in enumerate(sentences[:5], start=1):
        requirements.append(
            RequirementItem(
                scope=f"需求 {idx}",
                description=sentence[:180],
                priority="high" if idx == 1 else "medium",
                acceptance_criteria=[
                    f"确认 {sentence[:80]} 的需求已完成",
                    "确认相关业务场景可被复现",
                ],
            ).model_dump()
        )

    summary = "；".join(sentence for sentence in sentences[:3])
    return RequirementPool(
        requirements=requirements,
        project_summary=summary[:280],
    ).model_dump()


def generate_project_artifacts(requirement_summary: str) -> dict:
    summary = _normalize_transcript(requirement_summary)
    prd = [
        PRDItem(
            title="项目目标",
            description=summary,
            acceptance_criteria=[
                "确认客户访谈中的关键目标已整理",
                "确认交付范围与验收标准一致",
            ],
            priority="high",
        ).model_dump()
    ]
    user_stories = [
        UserStory(
            as_a="业务用户",
            i_want=f"能够查看 {summary[:80]} 的项目交付状态",
            so_that="快速判断交付结果是否满足业务需求",
            acceptance_criteria=[
                "用户能查看任务进度",
                "测试能覆盖核心场景",
            ],
        ).model_dump()
    ]
    risk_radar = [
        RiskItem(
            risk="需求理解偏差",
            impact="交付延期或返工",
            mitigation="安排二次确认会议并产出需求池",
        ).model_dump(),
        RiskItem(
            risk="系统集成困难",
            impact="接口对接延迟",
            mitigation="提前梳理系统边界与数据标准",
        ).model_dump(),
    ]
    knowledge_base = [
        KnowledgeEntry(
            title="访谈摘要",
            source="客户访谈",
            excerpt=summary[:120],
        ).model_dump()
    ]
    retrospective = [
        RetrospectiveEntry(
            lesson="提前梳理验收标准，降低返工风险",
            category="improvement",
        ).model_dump()
    ]

    return ProjectArtifactsResponse(
        record_id=0,
        prd=prd,
        user_stories=user_stories,
        risk_radar=risk_radar,
        knowledge_base=knowledge_base,
        retrospective=retrospective,
    ).model_dump(exclude={"record_id"})


def validate_ai_output(payload: Any, schema_type: str) -> dict:
    if not SCHEMAS:
        raise RuntimeError("AI output schema definitions are not available.")
    schema = SCHEMAS.get(schema_type)
    if not schema:
        raise ValueError(f"Unknown schema_type {schema_type}")
    validate(instance=payload, schema=schema)
    return {"schema_type": schema_type}
