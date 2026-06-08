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

Review models are read-only and cannot replace deterministic verification.

`Invoke-TaskLoop.ps1` is intentionally a single-shot loop. It does not run as a daemon and it does not start the next queued task after dispatch. When a node reaches `codex_reviewing`, Codex must perform final review before any next node can be claimed.
