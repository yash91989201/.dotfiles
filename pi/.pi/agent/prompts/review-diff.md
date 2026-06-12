---
description: Review current diff with reviewer subagent
model: openai-codex/gpt-5.4-mini
thinking: medium
subagent: reviewer
context: fresh
---
Review the current git diff and any relevant surrounding code. Use repo files/diff as source of truth; do not rely on parent chat unless context is explicitly included.

Focus on:

- correctness bugs
- missed edge cases
- security/privacy issues
- test coverage gaps
- unnecessary complexity

Do not nitpick style unless it affects maintainability.

Additional context/request:
$@

Return prioritized findings with file/line references when possible, then a merge/readiness verdict.
