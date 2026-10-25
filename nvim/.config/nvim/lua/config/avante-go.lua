local M = {}

-- Read credentials on demand without copying secrets into the dotfiles config.
function M.api_key()
  for _, name in ipairs({ "AVANTE_OPENCODE_GO_API_KEY", "OPENCODE_GO_API_KEY" }) do
    local key = vim.env[name]
    if key and key ~= "" then
      return key
    end
  end
  -- GUI launches and other shells may not inherit .bashrc's exports. Let Bash
  -- interpret the private secrets file, suppressing all output except this key.
  local secrets = vim.fn.expand("~/.bash_secrets")
  if vim.fn.filereadable(secrets) == 1 then
    local result = vim.system({
      "bash",
      "--noprofile",
      "--norc",
      "-c",
      'set +x; source "$1" >/dev/null 2>&1 || exit 1; printf "%s" "${OPENCODE_GO_API_KEY:-}"',
      "avante-go",
      secrets,
    }, { text = true }):wait(2000)
    if result.code == 0 and result.stdout and result.stdout ~= "" then
      return result.stdout
    end
  end
  local path = vim.fn.stdpath("data") .. "/../opencode/auth.json"
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local content = file:read("*a")
  file:close()
  local ok, auth = pcall(vim.json.decode, content)
  if not ok or type(auth) ~= "table" then
    return nil
  end
  local credential = auth["opencode-go"]
  if type(credential) == "table" and credential.type == "api" and type(credential.key) == "string" then
    return credential.key ~= "" and credential.key or nil
  end
end

local fallback_session

function M.list_models(self, timeout)
  local models = require("avante.providers.openai").list_models(self, timeout)
  -- Go also lists models served via Messages and Responses; this provider uses
  -- Chat Completions. Only offer model families served through that endpoint.
  local families = { "deepseek", "kimi", "glm", "mimo", "longcat", "hy", "space" }
  return vim.tbl_filter(function(model)
    for _, family in ipairs(families) do
      if model.id:match("^" .. family .. "[%-]") then
        return true
      end
    end
    return false
  end, models)
end

function M.parse_curl_args(self, prompt_opts)
  local request = require("avante.providers.openai").parse_curl_args(self, prompt_opts)
  if not request then
    return nil
  end
  local sidebar = require("avante").get(false)
  local history = sidebar and sidebar.chat_history
  -- A persisted chat filename and project identify the conversation across turns.
  local session
  if history and history.filename then
    session = vim.fn.sha256(tostring(require("avante.utils").root.get()) .. ":" .. history.filename)
  else
    fallback_session = fallback_session or require("avante.utils").uuid()
    session = fallback_session
  end
  request.headers["User-Agent"] = "Avante.nvim"
  request.headers["x-opencode-session"] = session
  return request
end

return M
