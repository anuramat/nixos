-- https://docs.github.com/en/copilot/managing-copilot/monitoring-usage-and-entitlements/about-premium-requests
-- 300 premium requests per month
local models = {
  gpt41 = 'gpt-4.1', -- free
  -- other decent openai models aren't available right now
  gemini = 'gemini-2.5-pro', -- 1 -- top 2 aider, top 3 kagi reasoning, huge context
  claude40 = 'claude-sonnet-4', -- 1
}

return models
