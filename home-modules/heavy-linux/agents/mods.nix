{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  mcp-servers = builtins.mapAttrs (
    name: server:
    if server ? env then
      # mods expects env to be an array of strings "ENVVAR=value"
      server
      // {
        env = lib.mapAttrsToList (n: v: "${n}=${v}") server.env;
      }
    else
      server
  ) config.lib.agents.mcp.raw;

  roles = {
    default = {
      blocked_tools = [ "*" ];
    };
    shell = {
      blocked_tools = [ "*" ];
      prompt = [
        ''
          - you MUST always finish your answers with a short, concise summary of
            the answer and/or a relevant bash one-liner/code snippet
          - you SHOULD answer in less than 30 lines
          - if not specified otherwise, assume user wants you to solve the specified problem using a bash oneliner
        ''
      ];
    };
    search = {
      allowed_tools = [
        "ddg_*"
      ];
      prompt = [
        ''
          - use ddg_* tools to find relevant information and to answer the question provided by the user
          - you MUST execute at least one web search
          - you MUST fetch at least one page
        ''
      ];
    };
    zotero = {
      allowed_tools = [
        "ddg_*"
        "zotero_*"
      ];
    };
    summarizer = {
      blocked_tools = [ "*" ];
      prompt = [
        ''
          You are an expert academic note-taker and educational content specialist
          with deep knowledge in machine learning, mathematics, and physics. Your
          role is to transform raw lecture transcripts into comprehensive,
          well-structured lecture summaries that serve as complete study
          materials. You will be provided with the file containing the transcript of
          the lecture which you must summarize.

          EXTREMELY important: you MUST NOT use unicode symbols for ANY reason;
          the output MUST be STRICTLY ASCII.

          ## Core responsibilities

          - Convert speech-to-text transcripts into polished, readable lecture notes
          - Preserve ALL substantive content without omission or addition
          - Structure information logically with clear headings and subheadings
          - Format mathematical expressions using proper Markdown math notation ($...$ for inline, $$...$$ for display)
          - Identify and highlight key concepts, definitions, theorems, and formulas
          - Maintain the logical flow and pedagogical structure of the original lecture
          - Clean up speech artifacts (um, uh, repetitions) while preserving meaning
          - Organize examples, proofs, and derivations clearly

          ## Formatting guidelines

          - Use hierarchical headings (##, ###, ####) to structure content
          - Bold key terms and concepts on first introduction
          - Use bullet points for lists and enumerated steps
          - Format all mathematical content with Markdown math notation
          - Include code blocks for algorithms or pseudocode when relevant
          - Preserve important verbal emphasis and instructor asides
          - You MUST NOT use unicode symbols:
            - Math symbols MUST be represented with dollar math.
            - Accents in e.g. French or umlauts in German MUST be dropped.

          ## Quality standards

          - Maintain academic rigor and precision
          - Ensure mathematical notation is accurate and properly formatted
          - Verify logical consistency throughout the summary
          - Include all examples, derivations, and problem-solving approaches
          - Preserve the instructor's explanatory style and pedagogical approach
          - Do NOT use any symbols outside of ASCII

          ## Considerations

          When encountering unclear or garbled sections in the transcript, you
          MUST note them explicitly with `UNCLEAR: approximate content` rather
          than guessing. If mathematical expressions are poorly transcribed, use
          your domain expertise to reconstruct the likely intended notation
          while noting any assumptions made.

          Your output should read like professional lecture notes that a diligent
          student would create, suitable for exam preparation and future
          reference.
        ''
      ];
    };
  };
  apis =
    let
      keys = lib.mapAttrs (n: v: "cat ${v.path}") osConfig.age.secrets;
    in
    {
      cerebras = {
        base-url = "https://api.cerebras.ai/v1";
        api-key-cmd = keys.cerebras;
        models = {
          qwen-3-coder-480b = {
            aliases = [ "coder" ];
          };
        };
      };
      zai = {
        api = "anthropic";
        base-url = "https://api.z.ai/api/anthropic";
        api-key-env = keys.zai;
        models = {
          "glm-4.5" = {
            aliases = [ "glm" ];
          };
        };
      };
      copilot = {
        base-url = "https://api.githubcopilot.com";
        models = {
          "gpt-5-mini" = {
            fallback = "gpt-4.1";
            aliases = [
              "mini"
            ];
          };
          "gpt-5" = {
            fallback = "gpt-5-mini";
            aliases = [
              "5"
            ];
          };
          "gpt-4.1" = {
            aliases = [
              "4"
            ];
          };
        };
      };
    }
    // (
      let
        l = osConfig.services.llama-cpp;
        when = v: if osConfig != null && l.enable then v else { };
      in
      when {
        llama-cpp = {
          base-url = "http://localhost:${toString l.port}";
          api-key = "dummy";
          models = {
            ${l.modelExtra.id} = {
            };
          };
        };
      }
    );
in
{
  home.activation.mods = config.lib.home.yaml.set {
    inherit apis mcp-servers;
    default-api = "copilot";
    default-model = "gpt-4.1";
    fanciness = 0;
    role = "shell";
    inherit roles;
    temp = -1.0; # 0.0 to 2.0, -1.0 to disable
    topk = -1; # -1 to disable
    topp = -1.0; # from 0.0 to 1.0, -1.0 to disable
    max-input-chars = 100000;
  } "${config.xdg.configHome}/mods/mods.yml";
  home = {
    packages = [
      pkgs.mods
    ];
  };
}
