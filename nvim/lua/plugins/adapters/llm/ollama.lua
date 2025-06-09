local models = {
  qwen06 = {
    -- runs even on t480, 100% GPU on ll7
    name = 'qwen3:0.6b',
    num_ctx = nil,
  },
  qwen40 = {
    -- 20480 is default; qwen3:4b -- 20k over, 19.5k under
    name = 'qwen3:4b',
    num_ctx = 19500,
  },
  qwen80 = {
    -- 10k under, 11k over
    name = 'qwen3:8b',
    num_ctx = 10000,
  },
}

local config = {
  reasoning_effort = 'low', -- low|medium|high, only used for reasoning models
  think = false,
  extra_request_body = { options = {} },
  endpoint = 'http://localhost:11434',
}

local function wrapQwen(model)
  config.model = model.name
  if not config.think then config.reasoning_effort = nil end
  config.extra_request_body.options.num_ctx = model.num_ctx
  return config
end

return wrapQwen(models.qwen40)
