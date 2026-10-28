# `decide QUESTION... < STATE`: the decision model's probability that the
# answer to the yes/no question about stdin is yes
{ pkgs, inputs, ... }:
let
  inherit (inputs.self.consts.llama) host decisionPort;
  decide = pkgs.writeShellApplication {
    name = "decide";
    runtimeInputs = with pkgs; [
      curl
      jq
    ];
    text = ''
      jq -Rs --arg q "$*" '{state: ., questions: {q: {type: "noul", instructions: $q}}}' |
        curl -sSf --json @- http://${host}:${toString decisionPort}/v1/systemone |
        jq .answers.q.noul
    '';
  };
in
{
  home.packages = [ decide ];
}
