# "special" hosts, e.g. designated LLM inference machine etc.
{ inputs, ... }:
{
  home.sessionVariables = {
    LLAMA_HOST = "http://${inputs.self.consts.llama.host}:${toString inputs.self.consts.llama.port}";
  };
}
