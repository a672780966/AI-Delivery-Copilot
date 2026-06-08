# AI Control Runner

This directory stores task contracts, verification reports, review summaries, and memory for the Codex -> Opencode serial workflow.

The node execution flow is:

1. Codex creates exactly one queued task.
2. `build-local` implements only the current node.
3. `verify-local` runs deterministic checks and writes factual results.
4. `review-openrouter` reads the diff summary and verify report.
5. `review-google` runs only when triggered by failure, high risk, or Codex request.
6. Codex reads the final summary and decides the next action.

Review models are read-only and cannot replace deterministic verification.
