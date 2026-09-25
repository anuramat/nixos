{ config, lib, ... }:
let
  inherit (lib)
    concatStringsSep
    concatMapStringsSep
    mapAttrsToList
    toList
    ;
  q = s: ''"${s}"'';
  # "Resize Increase Left" -> Resize "Increase Left"; strings containing quotes are verbatim KDL
  action =
    s:
    let
      m = builtins.match "([^ ]+) ?(.*)" s;
      arg = builtins.elemAt m 1;
    in
    if lib.hasInfix ''"'' s then
      s
    else
      concatStringsSep " " (
        [ (builtins.head m) ]
        ++ lib.optional (arg != "") (if builtins.match "[0-9]+" arg != null then arg else q arg)
      );
  bind = key: acts: "bind ${q key} { ${concatMapStringsSep "; " action (toList acts)}; }";
  # "shared_among scroll search" -> shared_among "scroll" "search"
  header =
    s:
    let
      ws = lib.splitString " " s;
    in
    concatStringsSep " " ([ (builtins.head ws) ] ++ map q (lib.tail ws));
  keybinds =
    modes:
    "keybinds clear-defaults=true {\n"
    + concatStringsSep "\n" (
      mapAttrsToList (
        m: bs: "${header m} {\n  ${concatStringsSep "\n  " (mapAttrsToList bind bs)}\n}"
      ) modes
    )
    + "\n}\n";
  lock = lib.mapAttrs (_: a: toList a ++ [ "SwitchToMode Locked" ]);
  forDirs =
    f:
    lib.mapAttrs (_: f) {
      h = "Left";
      j = "Down";
      k = "Up";
      l = "Right";
    };
  prefix = p: lib.mapAttrs' (k: lib.nameValuePair "${p}${k}");
  upper = lib.mapAttrs' (k: lib.nameValuePair (lib.toUpper k));
  newTab = ''NewTab { cwd "${config.home.homeDirectory}"; }'';
  tabs = lib.genAttrs' (lib.range 1 9) (
    i: lib.nameValuePair "Alt ${toString i}" "GoToTab ${toString i}"
  );
in
{
  programs.zellij = {
    enable = true;
    # every other unselected tab is painted with emphasis_1; make it match the rest
    themes.stylix.themes.default.ribbon_unselected.emphasis_1 =
      lib.mkForce config.lib.stylix.colors.withHashtag.base02;
    settings = {
      default_mode = "locked";
      # NOTE kinda ugly, doesn't show all the hotkeys anyway
      # plugins.compact-bar = {
      #   _props.location = "zellij:compact-bar";
      #   tooltip = ""; # don't need the hotkey since tooltip appears on ctrl-g
      # };
      show_startup_tips = false;
      show_release_notes = false;
      default_layout = "compact";
      simplified_ui = true;
      pane_frames = false;
      copy_on_select = false;
      session_serialization = false;
    };
    extraConfig = keybinds {
      normal = {
        p = "SwitchToMode Pane";
        r = "SwitchToMode Resize";
        s = "SwitchToMode Scroll";
        o = "SwitchToMode Session";
        t = "SwitchToMode Tab";
        m = "SwitchToMode Move";
      };
      locked =
        tabs
        // prefix "Alt " (forDirs (d: "MoveFocus ${d}"))
        // {
          "Ctrl g" = "SwitchToMode Normal";
          "Alt t" = newTab;
          "Alt i" = "GoToPreviousTab";
          "Alt o" = "GoToNextTab";
          "Alt Tab" = "ToggleTab";
          "Alt p" = "NewPane";
          "Alt w" = "ToggleFloatingPanes";
          "Alt =" = "Resize Increase";
          "Alt -" = "Resize Decrease";
          "Alt [" = "PreviousSwapLayout";
          "Alt ]" = "NextSwapLayout";
          "Alt m" = "TogglePaneInGroup";
          "Alt Shift m" = "ToggleGroupMarking";
        };
      resize =
        forDirs (d: "Resize Increase ${d}")
        // upper (forDirs (d: "Resize Decrease ${d}"))
        // {
          "=" = "Resize Increase";
          "-" = "Resize Decrease";
        };
      pane =
        lock (
          forDirs (d: "NewPane ${d}")
          // {
            n = "NewPane";
            s = "NewPane stacked";
            x = "CloseFocus";
            p = "TogglePanePinned";
            f = "ToggleFocusFullscreen";
            "Shift f" = "ToggleFocusNoUiFullscreen";
            w = "TogglePaneEmbedOrFloating";
          }
        )
        // {
          r = [
            "SwitchToMode RenamePane"
            "PaneNameInput 0"
          ];
        };
      move = forDirs (d: "MovePane ${d}") // {
        n = "MovePane";
        p = "MovePaneBackwards";
        i = "MoveTab Left";
        o = "MoveTab Right";
      };
      tab =
        lock {
          n = newTab;
          x = "CloseTab";
          b = "BreakPane";
          i = "BreakPaneLeft";
          o = "BreakPaneRight";
          s = "ToggleActiveSyncTab"; # sync inputs between all panes in the tab
        }
        // {
          r = [
            "SwitchToMode RenameTab"
            "TabNameInput 0"
          ];
        };
      scroll =
        lock {
          Esc = "ScrollToBottom";
          e = "EditScrollback";
          "Shift y" = "CopyLastCommandOutput";
        }
        // {
          "/" = "SwitchToMode EnterSearch"; # add `SearchInput 0` to reset
          v = "SelectCommandAtScrollPosition";
        };
      search = {
        Esc = "SwitchToMode Scroll";
        "/" = "SwitchToMode EnterSearch";
        n = "Search down";
        p = "Search up";
        N = "Search up";
        c = "SearchToggleOption CaseSensitivity";
        w = "SearchToggleOption Wrap";
        o = "SearchToggleOption WholeWord";
      };
      entersearch = {
        Esc = "SwitchToMode Scroll";
        Enter = "SwitchToMode Search";
      };
      renametab = lock { Esc = "UndoRenameTab"; };
      renamepane = lock { Esc = "UndoRenamePane"; };
      session =
        lock {
          "]" = "FocusHostSession";
          "[" = "FocusGuestSession";
          f = "ToggleHostFullscreen";
          w = ''LaunchOrFocusPlugin "session-manager" { floating true; move_to_focused_tab true; }'';
        }
        // {
          d = "Detach";
        };
      "shared_except locked" = lib.genAttrs [ "Ctrl g" "Enter" "Esc" ] (_: "SwitchToMode Locked");
      "shared_among normal scroll" = {
        "y" = "Copy";
      };
      "shared_among scroll search" = {
        j = "ScrollDown";
        k = "ScrollUp";
        "Ctrl f" = "PageScrollDown";
        "Ctrl b" = "PageScrollUp";
        "Ctrl d" = "HalfPageScrollDown";
        "Ctrl u" = "HalfPageScrollUp";
        "[" = "ScrollToPreviousPrompt";
        "]" = "ScrollToNextPrompt";
      };
    };
  };
}
