# Google AI Pro Pi Extension

Registers a Pi provider named `google-ai-pro` backed by Google Code Assist / Gemini CLI OAuth.

## Setup

The extension stores OAuth client credentials in `auth.json` (not checked into git). Create it in the extension directory:

```json
{
  "oauthClientId": "YOUR_CLIENT_ID",
  "oauthClientSecret": "YOUR_CLIENT_SECRET"
}
```

These are the OAuth client ID/secret used by the Gemini CLI Code Assist login flow.

## Usage

1. Reload Pi or start a new Pi session.
2. Run `/login` and choose `Google AI Pro / Code Assist`.
3. Pick a model with `/model`, or start Pi with:

```bash
pi --provider google-ai-pro --model gemini-2.5-pro
```

## Notes

- This uses Google OAuth and the Code Assist endpoint used by Gemini CLI.
- It does **not** scrape browser cookies or passwords.
- Google AI Pro/Ultra quota applies only when Google recognizes the signed-in account tier for Code Assist/Gemini CLI.
- API-key auth (`GEMINI_API_KEY`) is separate from AI Pro subscription quota.
- There is no official Pi package for this provider. The closest public reference found is `opencode-gemini-auth`, plus the official `google-gemini/gemini-cli` implementation.
- Google has warned that Gemini CLI OAuth via third-party software may be policy-sensitive; use at your own discretion.

## Optional environment

- `GOOGLE_CLOUD_PROJECT` or `GOOGLE_CLOUD_PROJECT_ID`: project for paid/standard Code Assist tiers.
- `GOOGLE_AI_PRO_ACCESS_TOKEN`: direct access-token fallback for testing; normally use `/login`.
- `GOOGLE_AI_PRO_DEBUG=1`: print sanitized request/response diagnostics to stderr.
- `CODE_ASSIST_ENDPOINT` / `CODE_ASSIST_API_VERSION`: override Code Assist endpoint for debugging.

## Pi Google-provider parity

This extension mirrors Pi's built-in Google provider message handling where it matters for forks, subagents, and long tool-use sessions:

- drops errored or aborted assistant turns before replaying history
- strips foreign-provider thought signatures that Google would reject
- preserves valid same-model `thoughtSignature` values on text, thinking, and `functionCall` parts
- synthesizes empty tool results for orphaned tool calls so replay stays valid
- only sends explicit function-call IDs for model families that require them
- uses Gemini major-version detection for multimodal tool responses, including `gemini-3.1-*`

## Tool-result images

When a Pi tool returns an image (for example `read` on a pasted screenshot path), Gemini 2.x Code Assist does not accept nested `function_response.parts`. This extension sends those image bytes as a separate user image turn after the function response, matching Pi's built-in Google fallback behavior, so observer/designer subagents can read image files without a 400 error.

## Tool-call thought signatures

Code Assist requires Gemini thought signatures to be replayed on function-call parts during tool-use turns. The extension preserves valid same-model `thoughtSignature` values on text, thinking, and `functionCall` parts so subagents can call tools and continue after tool results without `Function call is missing a thought_signature` errors.
