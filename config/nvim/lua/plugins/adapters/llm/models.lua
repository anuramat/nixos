return {
  ollama = {
    qwen06 = 'qwen3:0.6b', -- runs even on t480, 100% GPU on ll7
    qwen17 = 'qwen3:1.7b', -- 100% GPU on ll7, 4.5/8.2 GB VRAM
    qwen40 = 'qwen3:4b', -- 100->96% GPU on ll7
    qwen80 = 'qwen3:8b', -- 100->76% GPU on ll7
  },
  copilot = {
    gpt41 = 'gpt-4.1', -- outperforms 4o, no limit
    -- 4.5 is not available for some reason
    claude35 = 'claude-3.5-sonnet',
    claude37 = 'claude-3.7-sonnet',
    claude37cot = 'claude-3.7-sonnet-thought',
    claude40 = 'claude-sonnet-4', -- sota
  },
}
