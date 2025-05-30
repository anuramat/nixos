-- https://docs.github.com/en/copilot/managing-copilot/monitoring-usage-and-entitlements/about-premium-requests#user-content-fnref-1
-- 300 premium requests per month
local models = {
  gpt41 = 'gpt-4.1', -- free
  -- 4.5 is not available for some reason, 50!!!
  -- opus 4 waiting -- 10
  claude37cot = 'claude-3.7-sonnet-thought', -- 1.25
  claude40 = 'claude-sonnet-4', -- 1
}

return models.claude40
