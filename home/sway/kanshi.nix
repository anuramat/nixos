{
  services.kanshi = {
    enable = true;

    settings = [
      # Define output aliases
      {
        output = {
          criteria = "LG Display 0x0521 Unknown";
          alias = "t480";
          position = "0,0";
        };
      }
      {
        output = {
          criteria = "California Institute of Technology 0x1626 0x00006002";
          alias = "ll7";
          position = "0,0";
          scale = 1.5;
        };
      }
      {
        output = {
          criteria = "Dell Inc. DELL S2722QC 192SH24";
          alias = "ext";
          scale = 1.5;
          adaptiveSync = false;
        };
      }
    ];

    profiles = {
      ll7-home = {
        outputs = [
          {
            criteria = "ll7";
            scale = 2;
          }
          {
            criteria = "ext";
            position = "1600,0";
          }
        ];
      };

      ll7 = {
        outputs = [
          {
            criteria = "ll7";
            scale = 1.5;
          }
        ];
      };

      t480-home = {
        outputs = [
          {
            criteria = "t480";
          }
          {
            criteria = "ext";
            position = "0,-2000";
          }
        ];
      };

      t480 = {
        outputs = [
          {
            criteria = "t480";
          }
        ];
      };
    };
  };
}
