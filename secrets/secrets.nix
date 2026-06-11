let
  flake = builtins.getFlake (toString ../.);
  recipients =
    flake.outputs.keys
    |> builtins.attrValues
    |> builtins.concatMap (h: h.clientKeys ++ h.knownHostsKeys);
in
[
  "anthropic.age"
  "cachix.age"
  "cerebras.age"
  "claudecode.age"
  "claudecode-jojo.age"
  "gemini.age"
  "groq.age"
  "minimax.age"
  "ollama.age"
  "openai.age"
  "openrouter.age"
  "perplexity.age"
  "zai.age"
  "hdotp.age"
  "hdpw.age"
  "uc3-pw.age"
  "uc3-totp.age"
  "tgfy-token.age"
  "tgfy-id.age"
]
|> map (x: {
  name = x;
  value = {
    publicKeys = recipients;
  };
})
|> builtins.listToAttrs
