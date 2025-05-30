local models = {
  gpt41 = 'gpt-4.1', -- outperforms 4o, no limit
  -- 4.5 is not available for some reason
  claude35 = 'claude-3.5-sonnet',
  claude37 = 'claude-3.7-sonnet',
  claude37cot = 'claude-3.7-sonnet-thought',
  claude40 = 'claude-sonnet-4', -- sota
}

return models.claude40
