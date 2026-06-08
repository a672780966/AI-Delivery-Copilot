---
blueprint_version: bp_codex_opencode_serial_v1
task_id: ai-control-pin-agent-role-split
module_id: ai-control
node_id: pin-agent-role-split
title: Pin Agent Role Split
queue_state: codex_reviewing
owner: opencode.worker
reviewer: codex.main
priority: high
created_at: 2026-06-09T00:00:00+08:00
branch: opencode/ai-control/pin-agent-role-split
---

# Pin Agent Role Split

## Goal

Persist the agreed multi-agent role split so context compression cannot weaken or rewrite responsibilities.

## Background

The delivery loop is paused because context compression caused state and provenance loss. Before verify-local baseline work can resume, the repository must record the exact agreed role split for Codex, opencode build local, verify local, OpenRouter GPT OSS 120B review reporting, and Google AI Studio Gemma 4 31B second-opinion review.

This task is a control-plane documentation and schema hardening node only. It must not modify product code, scripts, tests, infrastructure, package metadata, or runtime implementation.

## Required Skills

- Follow `bp_codex_opencode_serial_v1`.
- Preserve exact multi-agent responsibility boundaries.
- Edit only allowed control-plane files.
- Produce eval and verify evidence before returning to Codex.

## Allowed Scope

- `.ai/state/codex-context-checkpoint.md`
- `.ai/README.md`
- `.ai/templates/final-summary.schema.json`
- `.ai/templates/task-contract.schema.json`

## Forbidden Scope

- `backend/app`
- `web/app`
- `contracts/schemas`
- `tests`
- `infra`
- `scripts/Invoke-VerifyLocal.ps1`
- `scripts/Invoke-AgentNode.ps1`
- `scripts/Invoke-TaskLoop.ps1`
- `Dockerfile`
- `package.json`
- requirements files
- product code

## Input Context

### Role Split

#### Codex

Role: `planner_atomic_node_splitter_task_creator_final_reviewer`

Can:

- plan
- split atomic node
- create queued task
- define scope
- define acceptance criteria
- inspect evidence
- make final review decision

Must not:

- write code
- implement
- repair code
- provide full patch
- provide full function body
- auto start next task
- accept without verify local evidence

#### opencode_build_local

Role: `only_code_writer_and_repair_worker`

Implementation owner: `true`

Model provider required: `local`

Expected model label: `Qwopus 3.5 9B Coder Q5 Local`

Can:

- claim one queued task
- create or switch task branch
- implement current node
- repair current node
- modify allowed scope only

Must not:

- modify forbidden scope
- start next task
- merge
- push main
- release
- use OpenRouter for implementation
- use Google for implementation
- use Codex direct edits for implementation

#### verify_local

Role: `deterministic_local_fact_layer`

Model required: `false`

Can:

- run local commands
- inspect git diff
- check allowed scope
- check forbidden scope
- produce verify evidence

Must output:

- scope_check
- forbidden_scope_check
- verify_status

Must not:

- call model
- write code
- repair code
- commit
- merge
- decide final acceptance

#### review_openrouter_gpt_oss_120b

Role: `read_only_summary_and_report_agent`

Preferred model label: `OpenRouter GPT OSS 120B`

Can:

- read eval
- read verify
- read diff summary
- summarize for Codex
- produce short report

Must not:

- implement
- patch
- edit files
- run commands
- commit
- merge
- start task
- replace verify local

#### review_google_ai_studio_gemma_4_31b

Role: `read_only_second_opinion_agent`

Preferred model label: `Google AI Studio Gemma 4 31B`

Trigger only when:

- high risk
- verify failed
- scope failed
- forbidden scope failed
- complex error
- Codex requests second opinion

Can:

- inspect diff
- inspect verify evidence
- explain risk
- recommend accept or repair

Must not:

- implement
- patch
- edit files
- run commands
- commit
- merge
- start task
- replace verify local

#### codex_final_review

Role: `final_gate_decision`

Decision basis:

- `verify_local.scope_check`
- `verify_local.forbidden_scope_check`
- `verify_local.verify_status`
- `review_openrouter_gpt_oss_120b.report`
- `review_google_ai_studio_gemma_4_31b.second_opinion_if_triggered`

Allowed decisions:

- accept
- request repair
- split task
- inspect detail

Must not accept if:

- verify local evidence missing
- scope check fail
- forbidden scope check fail
- implementation owner not opencode build local
- implementation model provider not local
- Codex wrote code true

### Final Summary Schema Must Require

`execution_provenance` with:

- `planner`: `codex`
- `implementation_owner`: `opencode_build_local`
- `implementation_model`: string
- `implementation_model_provider`: `local`
- `codex_wrote_code`: `false`
- `verify_layer`: `verify_local`
- `review_report_model`: `OpenRouter GPT OSS 120B`
- `review_second_opinion_model`: `Google AI Studio Gemma 4 31B|null`

## Expected Outputs

- `.ai/state/codex-context-checkpoint.md` records this exact role split.
- `.ai/README.md` records this exact role split.
- `.ai/templates/final-summary.schema.json` requires `execution_provenance`.
- `.ai/templates/task-contract.schema.json` records implementation owner and model provider constraints.
- Eval evidence for this node.
- Verify evidence for this node.
- Review-ready changed file list, implementation log, repair actions if any, and risk notes.

## Acceptance Criteria

- `.ai/state/codex-context-checkpoint.md` records this exact role split.
- `.ai/README.md` records this exact role split.
- `.ai/templates/final-summary.schema.json` requires `execution_provenance`.
- `.ai/templates/task-contract.schema.json` records implementation owner and model provider constraints.
- No product code modified.
- No scripts modified.
- No Opencode build started by Codex.
- No next task started.
- verify-local-baseline remains paused until this node is accepted.

## Verify Commands

- `python -m json.tool .ai/templates/final-summary.schema.json`
- `python -m json.tool .ai/templates/task-contract.schema.json`
- `git diff --name-only`
- `git diff --stat`

## Branch Policy

- Branch name: `opencode/ai-control/pin-agent-role-split`
- opencode must create or switch to the task branch before implementation.
- opencode must commit the task branch.
- opencode must not merge or push directly to `main`.
- One node, one branch, one commit.
- Use explicit staging only.

## Commit Policy

One node, one branch, one commit: `true`

Explicit stage only: `true`

Allowed stage paths:

- `.ai/state/codex-context-checkpoint.md`
- `.ai/README.md`
- `.ai/templates/final-summary.schema.json`
- `.ai/templates/task-contract.schema.json`
- `.ai/tasks/queued/ai-control-pin-agent-role-split.md`
- `.ai/tasks/active/ai-control-pin-agent-role-split.md`
- `.ai/eval/ai-control-pin-agent-role-split.json`
- `.ai/verify/ai-control-pin-agent-role-split.md`
- `.ai/reviews/ai-control-pin-agent-role-split.md`
- `.ai/reviews/ai-control-pin-agent-role-split.diff-summary.md`
- `.ai/memory/ai-control-pin-agent-role-split.json`
- `.ai/state/current-run.json`

Forbidden stage paths:

- `backend/app`
- `web/app`
- `contracts/schemas`
- `tests`
- `infra`
- `scripts`
- product code

## Memory Write Policy

- Write only short-term evidence for this node if required by the loop.
- Do not write long-term memory until Codex approves.
- Do not capture raw secrets or sensitive logs.

## Risk Notes

- This node exists to prevent role drift after context compression.
- The work is control-plane only but high process risk because weakening provenance rules could allow Codex direct edits or hosted review agents to replace local implementation or verification.
- `.ai/README.md`, `.ai/templates/final-summary.schema.json`, and `.ai/templates/task-contract.schema.json` may need to be created if still missing.
- Do not resume `verify-local-baseline` until this role-split node is accepted.

## Codex Dispatch Notes

- Create exactly one queued task only.
- Do not implement this task as Codex.
- Do not start opencode.
- Do not resume verify-local-baseline until this role-split node is accepted.
- Codex final review must reject or request repair if implementation provenance does not show `opencode_build_local` with local model provider.
