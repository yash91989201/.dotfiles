Morph FastApply: Prefer morph_fastapply first only for suitable existing-file edits after reading the file and preparing marker-wrapped anchor snippets with // ... existing code .... Use native edit for small exact replacements, and use native write only for brand new files. If morph_fastapply lacks sufficient anchor context, skip it and use native edit instead.

<!-- pi-morphllm-plugin:fastapply:start -->
Morph FastApply: Prefer morph_fastapply first only for suitable existing-file edits after reading the file and preparing marker-wrapped anchor snippets with // ... existing code .... Use native edit for small exact replacements, and use native write only for brand new files. If morph_fastapply lacks sufficient anchor context, skip it and use native edit instead.
<!-- pi-morphllm-plugin:fastapply:end -->

## Specialized Subagents

You have access to specialized subagents for specific tasks. Use them when the situation calls for their expertise:

### Observer (Visual Analysis)
**When to use — ALWAYS for images:**
- User pastes an image, screenshot, or PDF
- User asks "what's this error?" with a screenshot
- User shares a diagram, chart, or visual content
- User shares terminal output as an image
- Any visual content needs analysis, regardless of whether the current model supports multimodal input

> **Rule:** Always delegate image analysis to the observer subagent, even if the running model has multimodal capabilities. This keeps raw image bytes out of the main context window and ensures consistent structured analysis.

**How to use:**
```typescript
subagent({
  agent: "observer",
  task: "Analyze the [image/screenshot/diagram] the user just shared. [Describe what you need extracted or analyzed]",
  context: "fork"  // Inherits the image from parent session
})
```

**Example triggers:**
- User pastes error screenshot → spawn observer to extract error details
- User shares UI screenshot → spawn observer to describe layout and issues
- User shares architecture diagram → spawn observer to explain components and relationships

### Designer (UI/UX)
**When to use:**
- User asks for UI/UX review or improvements
- User wants to improve visual design, layout, or styling
- User needs help with accessibility or responsive design
- User wants micro-interactions, animations, or visual polish
- User asks about color theory, typography, or spacing

**How to use:**
```typescript
subagent({
  agent: "designer",
  task: "[Review/Improve/Design] the [UI/component/page] for [specific goal]",
  context: "fork"  // Inherits current context
})
```

**Example triggers:**
- "How can I improve this UI?" → spawn designer
- "Make this more accessible" → spawn designer
- "Add some animations" → spawn designer
- "Review the visual hierarchy" → spawn designer

### Fixer (Fast Parallel Execution)
**When to use:**
- Well-defined implementation tasks with complete context provided
- Bulk updates across multiple files (e.g., "update all controllers")
- Writing tests for multiple functions
- Applying the same pattern to different locations
- Tasks that can be parallelized across folders/files

**How to use:**
```typescript
subagent({
  agent: "fixer",
  task: "Implement [specific change] in [scope]. Context: [pattern/example]. Acceptance: [criteria]",
  context: "fresh"  // Gets only the task, not full history
})
```

**Example triggers:**
- "Write tests for all API endpoints" → spawn fixers per endpoint folder
- "Add input validation to all forms" → spawn fixers per form component
- "Update all imports to use new module" → spawn fixers per directory

**Parallel pattern:**
```typescript
subagent({
  tasks: [
    { agent: "fixer", task: "Implement tests in /src/api/users/" },
    { agent: "fixer", task: "Implement tests in /src/api/posts/" },
    { agent: "fixer", task: "Implement tests in /src/api/comments/" },
    { agent: "fixer", task: "Implement tests in /src/api/auth/" },
    { agent: "fixer", task: "Implement tests in /src/api/notifications/" }
  ],
  concurrency: 5
})
```

**Fixer vs Worker:**
- Fixer: Fast, bounded tasks with complete context → use for speed
- Worker: Complex implementation needing decisions → use for quality

### General Pattern

When spawning these agents:
1. Use `context: "fork"` for observer/designer/oracle (inherit conversation)
2. Use `context: "fresh"` for fixer (gets only the task)
3. Be specific in the task description about what you need
4. Let them do their specialized work, then incorporate their findings
5. For observer: it will return structured analysis you can act on
6. For designer: it can review existing UI or implement new designs
7. For fixer: provide complete context and clear scope boundaries
