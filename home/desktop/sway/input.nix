{ ... }:
{
  wayland.windowManager.sway.config.input = {
    "*" = {
      repeat_delay = "250";
      repeat_rate = "50";
      xkb_layout = "us,ru";
      xkb_options = "grp:alt_space_toggle";
      accel_profile = "flat";
    };

    "5426:98:Razer_Razer_Atheris_-_Mobile_Gaming_Mouse_Keyboard" = {
    };

    "5426:138:Razer_Razer_Viper_Mini" = {
    };

    # anuramat-ll7
    "1267:12928:ELAN06FA:00_04F3:3280_Touchpad" = {
      dwt = "enabled";
      click_method = "clickfinger";
      natural_scroll = "enabled";
      # pointer_accel = "-0.05";
      scroll_method = "two_finger";
      tap = "disabled";
      drag = "enabled"; # tap-drag
      drag_lock = "enabled"; # grace period for tap-drag
      accel_profile = "adaptive";
    };

    "1165:51607:ITE_Tech._Inc._ITE_Device(8258)_Keyboard" = {
    };

    # anuramat-t480
    "1:1:AT_Translated_Set_2_keyboard" = {
    };

    "1739:0:Synaptics_TM3276-022" = {
      events = "disabled";
    };

    "2:10:TPPS/2_IBM_TrackPoint" = {
      pointer_accel = "0.7";
      accel_profile = "adaptive";
    };
  };

}
