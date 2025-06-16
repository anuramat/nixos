{
  programs.readline = {
    enable = true;
    variables = {
      # completion: logic
      match-hidden-files = true;
      skip-completed-text = true;
      completion-ignore-case = true;
      # '-' == '_':
      completion-map-case = true;

      # completion: visuals
      visible-stats = true;
      colored-stats = true;
      mark-symlinked-directories = true;
      completion-display-width = -1;
      colored-completion-prefix = true;
      completion-prefix-display-length = 5;

      # history
      # reset history modifications after running a command:
      revert-all-at-newline = true;
      history-size = -1;

      # stfu
      completion-query-items = 0;
      page-completions = false;
      show-all-if-ambiguous = true;
      show-all-if-unmodified = true;
    };
  };
}
