---
description: Root-cause debugging workflow [gpt-5.5 high]
model: openai-codex/gpt-5.5
thinking: high
---
Debug this systematically.

Process:
1. Reproduce or locate the failure signal.
2. Trace the execution path and identify likely root cause.
3. Avoid shotgun fixes.
4. Patch the smallest correct location.
5. Verify with targeted tests/commands.

Task:
$@

Return:
- root cause
- files changed
- verification performed
- remaining risks
