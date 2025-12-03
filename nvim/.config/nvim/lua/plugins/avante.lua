return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  version = false,
  build = "make",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-lua/plenary.nvim",
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
  opts = {
    provider = "copilot-gpt-5-mini",
    providers = {
      ["copilot-gpt-5-mini"] = {
        __inherited_from = "copilot",
        model = "gpt-5-mini",
        display_name = "GPT 5 Mini (x0) (Default)",
        hide_in_model_selector = false,
      },
      ["copilot-gpt-51"] = {
        __inherited_from = "copilot",
        model = "gpt-5.1",
        display_name = "GPT 5.1 (x1)",
        hide_in_model_selector = false,
      },
      ["copilot-gpt-51-codex"] = {
        __inherited_from = "copilot",
        model = "gpt-5.1-codex",
        display_name = "Codex (x1)",
        hide_in_model_selector = false,
      },
      ["copilot-gpt-51-codex-mini"] = {
        __inherited_from = "copilot",
        model = "gpt-5.1-codex-mini",
        display_name = "Codex Mini (x0.33)",
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
        description = "Stage, commit, and push all changes with clean, intent-based commits.",
        details = "Use Git MCP + bash to group changes by purpose, create conventional commits, and push.",
        prompt = [[
You are a **Git assistant** using Git MCP tools and a bash shell.

Goal: In the current repo, **review changes → group by intent → stage → commit → push**.
Do everything automatically. Do **not** ask the user anything.

## Rules
- Use only Git MCP tools and bash (`git_status`, `git_diff_*`, `git_add`, `git_rm`, `git_reset`, `git_commit`, `bash`).
- Do not modify files, run tests, or start dev servers.
- Skip build/dep/IDE/secret noise unless clearly intentional (e.g. `node_modules`, `dist`, `.env`, `.vscode`, etc.).

## Steps

1. **Status & Diffs**
   - Run `git_status`. If not a repo or error → stop with a short error.
   - If no modified/staged/untracked files → output `No changes to commit.` and stop.
   - Use `git_diff_unstaged` and `git_diff_staged` to understand changes (reason internally).

2. **Group by Intent**
   - Group files into logical sets by purpose (intent): `feat`, `fix`, `refactor`, `docs`, `style`, `test`, `chore`, `perf`.
   - Each group should represent one clear change.

3. **Stage per Group**
   - For each group:
     - Stage with `git_add <file>` or `git_rm <file>` for deletes.
     - If wrong files are staged, use `git_reset <file>` and restage correctly.

4. **Commit per Group**
   - For each staged group, create a conventional commit:
     - Header: `type(scope): subject`
       - `type` ∈ {feat, fix, docs, style, refactor, test, chore, perf}
       - `scope` optional, short (e.g. `auth`, `ui`, `api`)
       - `subject` imperative, ≤ 80 chars, no trailing period.
     - Body: a few bullet points explaining **what** and **why**.
   - Use `git_commit`. If commit fails → stop with a short error.

5. **Push**
   - After all groups are committed, run `git_status` to confirm no important leftovers.
   - Use bash to run: `git push`.
   - If push fails (no remote, non-fast-forward, auth, etc.) → output a short failure message with the Git error.

## Output
- On success: keep output minimal (or none).
- On failure: output a **short, clear** message about which step failed and why.
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
