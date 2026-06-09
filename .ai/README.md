# AI Control Runner

This directory stores task contracts, verification reports, review summaries, and memory for the Codex -> Opencode serial workflow.

The node execution flow is:

1. Codex creates exactly one queued task.
2. `scripts/Invoke-TaskLoop.ps1` claims at most one queued task when no active task exists.
3. `scripts/Invoke-AgentNode.ps1` dispatches `build-local` for the active node.
4. `verify-local` runs deterministic checks and writes factual results.
5. `review-openrouter` reads the diff summary and verify report.
6. `review-google` runs only when triggered by failure, high risk, or Codex request.
7. Codex reads the final summary and decides the next action.

## Multi-Agent Role Split

### Codex
Role: `planner_atomic_node_splitter_task_creator_final_reviewer`
Can: plan, split atomic node, create queued task, define scope, define acceptance criteria, inspect evidence, make final review decision.
Must not: write code, implement, repair code, provide full patch, provide full function body, auto start next task, accept without verify local evidence.

### opencode_build_local
Role: `only_code_writer_and_repair_worker`
Implementation owner: `true`
Model provider required: `local`
Expected model label: `Qwopus 3.5 9B Coder Q5 Local`
Can: claim one queued task, create or switch task branch, implement current node, repair current node, modify allowed scope only.
Must not: modify forbidden scope, start next task, merge, push main, release, use OpenRouter for implementation, use Google for implementation, use Codex direct edits for implementation.

### verify_local
Role: `deterministic_local_fact_layer`
Model required: `false`
Can: run local commands, inspect git diff, check allowed scope, check forbidden scope, produce verify evidence.
Must output: scope_check, forbidden_scope_check, verify_status.
Must not: call model, write code, repair code, commit, merge, decide final acceptance.

### review_openrouter_gpt_oss_120b
Role: `read_only_summary_and_report_agent`
Can: read eval, read verify, read diff summary, summarize for Codex, produce short report.
Must not: implement, patch, edit files, run commands, commit, merge, start task, replace verify local.

### review_google_ai_studio_gemma_4_31b
Role: `read_only_second_opinion_agent`
Trigger only when: high risk, verify failed, scope failed, forbidden scope failed, complex error, Codex requests second opinion.
Can: inspect diff, inspect verify evidence, explain risk, recommend accept or repair.
Must not: implement, patch, edit files, run commands, commit, merge, start task, replace verify local.

### codex_final_review
Role: `final_gate_decision`
Decision basis: verify_local.scope_check, verify_local.forbidden_scope_check, verify_local.verify_status, review_openrouter_gpt_oss_120b.report, review_google_ai_studio_gemma_4_31b.second_opinion_if_triggered
Allowed decisions: accept, request repair, split task, inspect detail.
Must not accept if: verify local evidence missing, scope check fail, forbidden scope check fail, implementation owner not opencode build local, implementation model provider not local, Codex wrote code true.

## Execution Provenance

- `planner`: `codex`
- `implementation_owner`: `opencode_build_local`
- `implementation_model`: `llamacpp/qwopus3.5-9b-q5.gguf`
- `implementation_model_provider`: `local`
- `codex_wrote_code`: `false`
- `verify_layer`: `verify_local`
- `review_report_model`: `OpenRouter GPT OSS 120B`
- `review_second_opinion_model`: `Google AI Studio Gemma 4 31B|null`

Review models are read-only and cannot replace deterministic verification.

`Invoke-TaskLoop.ps1` is intentionally a single-shot loop. It does not run as a daemon and it does not start the next queued task after dispatch. When a node reaches `codex_reviewing`, Codex must perform final review before any next node can be claimed.
