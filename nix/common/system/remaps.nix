{
  services.keyd = {
    enable = true;
    keyboards = {
      main = {
        ids = [
          "048d:c997:193096a7" # ll7
          "0001:0001:a38e6885" # t480
        ];
        settings =
          let
            interval = toString 64;
            duration = toString 256;
          in
          {
            main = {
              # def lettermod(letter, mod, x, y):
              #     if last symbol was triggered at t: (now - x < t): return letter
              #     if key is held for longer than y OR there was a full tap inside the key hold: return mod
              #     return letter
              a = "lettermod(control, a, ${interval}, ${duration})";
              s = "lettermod(shift, s, ${interval}, ${duration})";
              d = "lettermod(alt, d, ${interval}, ${duration})";
              f = "lettermod(meta, f, ${interval}, ${duration})";

              # mapped to left mods too but it sholdn't be a problem, since
              # most of the time apps don't care
              semicolon = "lettermod(control, semicolon, ${interval}, ${duration})";
              l = "lettermod(shift, l, ${interval}, ${duration})";
              k = "lettermod(alt, k, ${interval}, ${duration})";
              j = "lettermod(meta, j, ${interval}, ${duration})";

              capslock = "noop";
              leftalt = "escape";
              rightalt = "backspace";

              # <https://github.com/rvaiya/keyd/issues/114>
              # right mods are remapped to left ones. sad.
            };
          };
      };
    };
  };
}
