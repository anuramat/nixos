{
  config,
  lib,
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
  inherit (lib)
    mapAttrs
    concatStrings
    ;

  inherit (config.lib.home) when;

  think = true;

  wrapCmds = x: [ (concatStrings x) ];

  modagent = {
    main = ''
      You are an agent for Claude Code, Anthropic's official CLI for Claude.
      Given the user's message, you should use the tools available to
      complete the task. Do what has been asked; nothing more, nothing less.
      When you complete the task simply respond with a detailed writeup.
    '';

    general_guidelines = ''
      General guidelines:

      - In your final response always share relevant file names and code snippets.
        Any file paths you return in your response MUST be absolute. Do NOT use relative paths.
      - For clear communication with the user the assistant MUST avoid using emojis.
    '';
  };

  tools = mapAttrs (n: v: map (x: "claude_" + x) v) {
    r = [
      "Glob"
      "Grep"
      "LS"
      "Read"
      "TodoWrite"
    ];
    w = [
      "Edit"
      "MultiEdit"
      "Write"
      "NotebookEdit"
    ];
    x = [ "Bash" ];
  };

  roles = {
    junior-r = {
      allowed_tools = with tools; r;
      prompt = wrapCmds [
        modagent.main
        ''
          Your strengths:

          - Performing multi-step research tasks
          - Investigating complex questions
          - Analyzing multiple files

        ''
        modagent.general_guidelines
        ''
          Analysis guidelines:

          - Start broad and narrow down. ${when think "Use sequential thinking."}
          - Be thorough: always consider different options.
        ''
      ];
    };

    junior-rwx = {
      allowed_tools = with tools; r ++ w ++ x;
      prompt = wrapCmds [
        modagent.main
        ''
          Your strengths:

          - Searching for code, configurations, and patterns across large codebases
          - Analyzing multiple files to understand system architecture
          - Investigating complex questions that require exploring many files
          - Performing multi-step research tasks
        ''
        modagent.general_guidelines
        ''
          File access guidelines:

          - For file searches: Use Grep or Glob when you need to search broadly. Use Read when you know the specific file path.
          - For analysis: Start broad and narrow down. ${when think "Use sequential thinking."}
            Use multiple search strategies if the first doesn't yield results.
          - Be thorough: Check multiple locations, consider different naming conventions, look for related files.
          - NEVER create files unless they're absolutely necessary for achieving your goal.
            ALWAYS prefer editing an existing file to creating a new one.
          - NEVER proactively create documentation files (*.md) or README files.
            Only create documentation files if explicitly requested.
        ''
      ];
    };

    default = {
      blocked_tools = [ "*" ];
    };

    # TODO add a command that uses structured outputs, asks to fill field "command", and prints that
    shell = [
      ''
        you are a shell expert
        you do not explain anything
        you simply output one liners to solve the problems you're asked
        you do not provide any explanation whatsoever, ONLY the command
      ''
    ];

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
    };
  };

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
    inherit roles;
    temp = -1.0; # 0.0 to 2.0, -1.0 to disable
    topk = -1; # -1 to disable
    topp = -1.0; # from 0.0 to 1.0, -1.0 to disable
    max-input-chars = 1000000;
    mcp-servers = when think {
      inherit (config.lib.agents.mcp.raw) think claude;
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
