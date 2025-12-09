{ pkgs, ... }:
let
  transcribe = pkgs.writeShellApplication {
    name = "transcribe";
    runtimeInputs = with pkgs; [
      fd
      gum
      openai-whisper
    ];
    text =
      let
        find = ''fd --max-depth 1 -e "$1"'';
      in
      # bash
      ''
        ${find}
        gum confirm || exit 1
        ${find} -j 1 -x sh -c 'mkdir -p "{.}" && whisper "{}" --language en --device cuda -o "{.}" && mv -t "{.}" "{}"'
      '';
  };
in
{
  home.packages = with pkgs; [
    openai-whisper
    transcribe
  ];
}
