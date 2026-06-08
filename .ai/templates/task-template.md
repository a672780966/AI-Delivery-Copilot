# Codex Queued Task Template

## Metadata

| Field | Value |
|-------|-------|
| **task_id** | \
| **module_id** | \
| **node_id** | \
| **status** | `queued` |
| **owner** | `opencode` |
| **reviewer** | `codex` |

## Goal

[Describe the specific objective of this task. What must be achieved?]

## Background

[Context, prerequisites, and why this work exists. Link related issues/docs.]

## Allowed Scope

- [ ] Scope item 1
- [ ] Scope item 2
- [ ] Scope item 3

## Forbidden Scope

- [ ] Prohibited action 1
- [ ] Prohibited action 2
- [ ] Prohibited action 3

## Required Skills

- [ ] Skill 1
- [ ] Skill 2
- [ ] Skill 3

## Acceptance Criteria

1. \
2. \
3. \

## Verify Commands

```bash
# Add verification commands here
cmd1

# Expected outputs:
# - output1
# - output2
```

## Expected Outputs

[Describe the expected results, metrics, or artifacts.]

## Constraints

- **Complete this node only** — do not start another task until this one is fully resolved.
- **Return evidence to Codex**: `eval_result`, `verify_result`, `repair_count`, `risk`, `branch_name`, `commit`.
- **Max files changed**: `max_files_changed`
- **Max repair rounds**: `max_repair_rounds`

## Final Decision

- [ ] `pass` — all criteria met
- [ ] `fail` — criteria not met
- [ ] `needs_repair` — requires remediation
