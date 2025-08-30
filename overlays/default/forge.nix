final: prev: {
  forge =
    let
      linux = "x86_64-linux";
      darwin = "aarch64-darwin";
    in
    prev.stdenv.mkDerivation rec {
      pname = "forge";
      # https://github.com/antinomyhq/forge/releases/
      version = "0.111.0";
      meta = {
        description = "AI enabled pair programmer for Claude, GPT, O Series, Grok, Deepseek, Gemini and 300+ models";
        platforms = [
          linux
          darwin
        ];
      };
      src =
        let
          src =
            let
              mkLink =
                system: "https://github.com/antinomyhq/forge/releases/download/v${version}/forge-${system}";
            in
            if prev.system == linux then
              {
                url = mkLink "x86_64-unknown-linux-musl";
                hash = "sha256-e0UNM660sf2hJZ/+b2TpV0BilGmiv0CBfF1f4O3f70E=";
              }
            else if prev.system == darwin then
              {
                url = mkLink "forge-aarch64-apple-darwin";
                hash = "";
              }
            else
              throw "illegal system";
        in
        prev.fetchurl src;
      dontUnpack = true;
      installPhase = ''
        install -Dm755 $src $out/bin/forge
      '';
    };
}
