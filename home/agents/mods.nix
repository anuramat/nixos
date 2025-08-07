{
  config,
  pkgs,
  osConfig,
  ...
}:

let

  modsWithTokens = config.lib.home.agenixPatchPkg pkgs.mods (
    with osConfig.age.secrets;
    {
      inherit
        gemini
        openrouter
        anthropic
        oai
        ;
    }
  );

  summarizer = [
    ''
      You are an expert academic note-taker and educational content specialist
      with deep knowledge in machine learning, mathematics, and physics. Your
      role is to transform raw lecture transcripts into comprehensive,
      well-structured lecture summaries that serve as complete study
      materials. You will be provided with the file containing the transcript of
      the lecture which you must summarize.

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

      ## Quality standards

      - Maintain academic rigor and precision
      - Ensure mathematical notation is accurate and properly formatted
      - Verify logical consistency throughout the summary
      - Include all examples, derivations, and problem-solving approaches
      - Preserve the instructor's explanatory style and pedagogical approach

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

  apis = {
    copilot = {
      base-url = "https://api.githubcopilot.com";
      models = {
        "gpt-4.1" = {
          aliases = [
            "41"
            "4.1"
          ];
        };
      };
    };
    github-models = {
      base-url = "https://models.github.ai/inference";
      api-key-env = "gh";
      models = { };
    };
    ollama = {
      base-url = "http://localhost:${toString osConfig.services.ollama.port}";
      models = {
        "gpt-oss:20b" = {
          aliases = [ "oss" ];
        };
      };
    };
    openai = {
      base-url = "https://api.openai.com/v1";
      api-key-env = "gh";
      models = {
        codex-mini = { };
      };
    };
  };

  modsCfg = (pkgs.formats.yaml { }).generate "mods_config.yaml" {
    inherit apis;
    default-api = "copilot";
    default-model = "gpt-4.1";
    fanciness = 0;
    roles = {
      default = [ ];
      shell = [
        ''
          you are a shell expert
          you do not explain anything
          you simply output one liners to solve the problems you're asked
          you do not provide any explanation whatsoever, ONLY the command
        ''
      ];
      inherit summarizer;
    };
    temp = 0.0; # 0.0 to 2.0, -1.0 to disable
    topk = 1; # -1 to disable
    topp = 0.05; # from 0.0 to 1.0, -1.0 to disable
    max-input-chars = 1000000;
    mcp-servers = {
      inherit (config.lib.agents.mcp.raw) think;
    };
  };

in
{
  xdg.configFile."mods/mods.yml".source = modsCfg;
  home = {
    packages = [
      modsWithTokens
    ];
  };
}
