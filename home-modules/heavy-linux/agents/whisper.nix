{ config, pkgs, ... }:
let
  transcribe = pkgs.writeShellApplication {
    name = "transcribe";
    runtimeInputs = with pkgs; [
      fd
      gum
      whisper-cpp
    ];
    text =
      let
        modelName = "base.en";
        modelDir = config.xdg.dataHome + "/whisper-cpp/models";
        modelPath = modelDir + "/ggml-${modelName}.bin";
        find = ''fd --max-depth 1 -e "$1"'';
        whisperCmd = ''whisper-cli -m ${modelPath} "{}" cuda -otxt true -f "{.}/{.}.wav"'';
      in
      # bash
      ''
        [ -f "${modelPath}" ] || {
          mkdir -p "${modelDir}"
          (cd "${modelDir}" && whisper-cpp-download-ggml-model ${modelName})
        }
        ${find}
        gum confirm || exit 1
        ${find} -j 1 -x sh -c 'mkdir -p "{.}" && ffmpeg -i "{}" "{.}/{.}.wav" && ${whisperCmd} && mv -t "{.}" "{}"'
      '';
  };
in
{
  home.packages = with pkgs; [
    whisper-cpp
    transcribe
  ];
}
