return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  version = false,
  build = "make",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-lua/plenary.nvim",
    "folke/snacks.nvim",
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
  opts = {
    provider = "copilot-claude-sonnet-45",
    providers = {
      ["copilot-gpt-5-mini"] = {
        __inherited_from = "copilot",
        model = "gpt-5-mini",
        display_name = "GPT 5 Mini (x0) (Default)",
        hide_in_model_selector = false,
      },
      ["copilot-gpt-4.1"] = {
        __inherited_from = "copilot",
        model = "gpt-4.1",
        display_name = "GPT 4.1 (x0)",
        hide_in_model_selector = false,
      },
      ["copilot-gpt-5"] = {
        __inherited_from = "copilot",
        model = "gpt-5",
        display_name = "GPT 5 (x1)",
        hide_in_model_selector = false,
      },
      ["copilot-gpt-5-codex"] = {
        __inherited_from = "copilot",
        model = "gpt-5-codex",
        display_name = "GPT 5 Codex (x1)",
        hide_in_model_selector = false,
      },
      ["copilot-claude-opus-41"] = {
        __inherited_from = "copilot",
        model = "claude-opus-41",
        display_name = "Claude Opus 4.1 (x10)",
        hide_in_model_selector = false,
      },
      ["copilot-claude-sonnet-45"] = {
        __inherited_from = "copilot",
        model = "claude-sonnet-4.5",
        display_name = "Claude Sonnet 4.5 (x1)",
        hide_in_model_selector = false,
      },
      ["copilot-claude-haiku-4.5"] = {
        __inherited_from = "copilot",
        model = "claude-haiku-4.5",
        display_name = "Claude Haiku 4.5 (x0.33)",
        hide_in_model_selector = false,
      },
      ["copilot-grok-code-fast-1"] = {
        __inherited_from = "copilot",
        model = "grok-code-fast-1",
        display_name = "Grok Code Fast 1 (x0.25)",
        hide_in_model_selector = false,
      },
      ["copilot-gemini-2.5-pro"] = {
        __inherited_from = "copilot",
        model = "gemini-2.5-pro",
        display_name = "Gemini 2.5 Pro (x1)",
        hide_in_model_selector = false,
      },
      ["copilot-gemini-2.0-flash"] = {
        __inherited_from = "copilot",
        model = "gemini-2.0-flash",
        display_name = "Gemini 2.0 Flash (x0.25)",
        hide_in_model_selector = false,
      },
      copilot = { hide_in_model_selector = true },
      gemini = { hide_in_model_selector = true },
      claude = { hide_in_model_selector = true },
      vertex = { hide_in_model_selector = true },
      vertex_claude = { hide_in_model_selector = true },
      openai = { hide_in_model_selector = true },
      morph = { hide_in_model_selector = true },
    },
    behaviour = {
      auto_set_highlight_group = true,
      auto_apply_diff_after_generation = true,
      auto_approve_tool_permissions = true,
      enable_fastapply = true,
    },
    system_prompt = function()
      local hub = require("mcphub").get_hub_instance()
      return hub and hub:get_active_servers_prompt() or ""
    end,
    custom_tools = function()
      return {
        require("mcphub.extensions.avante").mcp_tool(),
      }
    end,
    rag_service = {
      enabled = false,
      host_mount = vim.fn.getcwd(),
    },
    shortcuts = {

      {
        name = "udoc",
        description = "Read doc, analyze modifications, integrate changes cleanly.",
        details = "Understand existing doc, process new input, merge updates in place, remove redundancy, ensure clarity and consistency.",
        prompt = [[
# Documentation Update Workflow

You are a **software developer with strong documentation skills**.  
Your job is to update Markdown documentation based on new content provided while maintaining technical clarity and consistency.

## Workflow
1. **Read & understand existing doc** – capture structure, purpose, and key points.  
2. **Read & understand modifications** – analyze intent and relation to current content.  
3. **Integrate updates** – insert in relevant sections or add new ones. Merge overlaps, refine unclear text, and remove redundancy.  
4. **Output** – return the complete, polished Markdown doc with consistent style, formatting, and tone.

## Rules
* Keep concise, actionable, and technically accurate.  
* Use proper Markdown structure (headings, lists, code blocks).  
* Never drop essential context, only remove duplicates.  

---
**New or updated content will be provided below.**
  ]],
      },
      {
        name = "cnp",
        description = "Stage, commit, and push all changes with intent-focused, logical commit separation.",
        details = "Analyze changes by purpose, create separate commits per intent, use conventional format with bullet points.",
        prompt = [[
# Git Assistant Workflow Guidelines

You are a Git assistant. Use `git` MCP's tools to follow this workflow.
Execute all steps carefully for clean, structured commits.

### If necessary enable the `git` MCP server, using the `toggle_mcp_server` tool.

## Step 1: Review All Changes

* Use `git_status` to list modified, staged, unstaged, and untracked files.
* Use `git_diff_unstaged` to check, review and understand working directory changes.
* Use `git_diff_staged` to check, review and understand staged changes.
* Exclude temp, build, and sensitive files from staging.

## Step 2: Smart Staging by Intent

* Group related changes logically: **feature, fix, refactor, docs, style, config**.
* Stage with the correct tool:

  * For Modified/untracked → `git_add <file>`
  * For Deleted → `git_rm <file>`

* Use `git_reset` to regroup if necessary.
* Ensure deletions are staged properly.

## Step 3: Commit by Intent

* Commit each group with `git_commit` using **Conventional Commit** style.

### Format

```
type(scope): subject
```

* **Types:** feat, fix, docs, style, refactor, test, chore, perf
* Imperative mood (e.g., “Add”, “Fix”, “Update”)
* ≤ 80 characters in subject

### Body

* What changed (specific components)
* Why changed (reason/benefit)
* Use bullet points

## Step 4: Push

* Push all commits to the current branch’s remote using the bash tool.

## Rules

* No generic commit messages.
* Never mix unrelated changes in one commit.
* Be precise, descriptive, and action-oriented.
* Use MCP tool syntax correctly (`git_add`, `git_rm`, `git_commit`, etc.).
* Execute this workflow **without asking for confirmation**.
* Stay within workflow boundaries.
* Only output failure messages.

## Examples

```
feat(auth): implement OAuth2 integration
- add Google OAuth provider config
- create user session management

fix(ui): resolve mobile navigation accessibility
- increase touch target sizes to 44px minimum
- add ARIA labels and keyboard focus trap
```
      ]],
      },
      {
        name = "og",
        description = "Operational Guidelines",
        details = "Clear, enforceable operational rules to ensure tasks are completed efficiently, accurately, and with minimal unnecessary actions or file reads.",
        prompt = [[
# Operational Guidelines (Strict Adherence)

This document provides detailed instructions for task execution. All steps must be followed precisely to ensure consistency, efficiency, and correctness.

## 1. Task Scope

* Execute exactly what is requested.
* Avoid enhancements, optimizations, or unrelated modifications.

## 2. Implementation Details

* Follow the existing code style and patterns.
* Reuse established implementations wherever applicable.

## 3. Tool Usage

* Use MCP tools ONLY when essential.
* Verify inputs carefully before execution.
* Avoid redundant or unnecessary calls.

## 4. File Operations

### READ

* Access only files that are directly required for the task.

### EDIT

* Make minimal, targeted changes necessary to fulfill the request.
* Do NOT format or refactor files unless explicitly instructed.

## 5. Error Focus

* Address ONLY errors introduced or related to the current task.
* Ignore pre-existing issues in unrelated files.
* After making all planned changes, check diagnostics on the edited files to identify any errors and fix them.

## 6. Efficiency

* Complete tasks with the fewest actions.
* Stay fully within the stated boundaries.

## 7. Dev Server

* Assume the development server is already running.
* Do NOT start or restart the server.
  ]],
      },
    },
    windows = {
      width = 38,
      input = {
        height = 14,
      },
    },
  },
  keys = {
    { "<leader>ax", "<cmd>AvanteClear<cr>", desc = "avante: clear chat" },
  },
}
