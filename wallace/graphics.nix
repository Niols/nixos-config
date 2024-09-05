{
  services.picom.enable = true;

  services.autorandr = {
    enable = true;
    defaultTarget = "default";

    profiles = let
      ## Define the screen fingerprints that we will be using.
      laptop =
        "00ffffffffffff000e6f031400000000001e0104b51e1378032594af5042b0250d4e550000000101010101010101010101010101010180e800a0f0605090302036002ebd10000018000000fd00303c95953c010a202020202020000000fe0043534f542054330a2020202020000000fe004d4e453030375a41312d320a2001a102030f00e3058000e60605016a6a24000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009a";
      tweag1 =
        "00ffffffffffff0030aecf62363632500320010380351e782ef735a7554fa3250c5054adef008180818a9500b300d1c0d100714f8100565e00a0a0a02950302035000f282100001a000000ff0056354748503236360a20202020000000fd00304b1e721e000a202020202020000000fc00453234712d32300a2020202020011002031ef14901020304111213101f230907078301000067030c001000003ccc7400a0a0a01e50302035000f282100001a662156aa51001e30468f33000f282100001e483f403062b0324040c013000f282100001e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000087";
      tweag2 =
        "00ffffffffffff0030aecf62383832500320010380351e782ef735a7554fa3250c5054adef008180818a9500b300d1c0d100714f8100565e00a0a0a02950302035000f282100001a000000ff0056354748503238380a20202020000000fd00304b1e721e000a202020202020000000fc00453234712d32300a2020202020010802031ef14901020304111213101f230907078301000067030c001000003ccc7400a0a0a01e50302035000f282100001a662156aa51001e30468f33000f282100001e483f403062b0324040c013000f282100001e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000087";
      mionsOffice1 =
        "00ffffffffffff00410c0cc22d1a0000131e0103803c22782ae445a554529e260d5054bfef00d1c0b30095008180814081c001010101565e00a0a0a029503020350055502100001ea073006aa0a029500820350055502100001a000000fc0050484c2032373545310a202020000000fd00304b1e721e000a2020202020200120020327f14b101f051404130312021101230907078301000065030c001000681a00000101304b00023a801871382d40582c450055502100001e8c0ad08a20e02d10103e96005550210000188c0ad090204031200c405500555021000018f03c00d051a0355060883a0055502100001c00000000000000000000000000000000ad";
      mionsOffice2 =
        "00ffffffffffff0009d1e77845540000081d010380351e782e0565a756529c270f5054a56b80d1c0b300a9c08180810081c001010101023a801871382d40582c45000f282100001e000000ff004e324b30303639383031510a20000000fd00324c1e5311000a202020202020000000fc0042656e51204757323438300a2001a9020322f14f901f04130312021101140607151605230907078301000065030c001000023a801871382d40582c45000f282100001f011d8018711c1620582c25000f282100009f011d007251d01e206e2855000f282100001e8c0ad08a20e02d10103e96000f282100001800000000000000000000000000000000000000000003";

    in {
      ## Default, with laptop screen only.
      default = {
        fingerprint = { "eDP-1" = laptop; };
        config = {
          "eDP-1" = {
            mode = "1920x1080";
            ## REVIEW: I am hoping that, by not specifying any of the following,
            ## they will naturally get a good default value. For now, I keep
            ## them here, commented out, ready in case I need them one day:
            # position = "0x0";
            # crtc = 0;
            # rate = "59.88";
            ## REVIEW: Not sure what to do with the following xrandr fields. All
            ## the screens have them and the values vary only slightly. Should
            ## we add them to all the `config` fields?
            # x-prop-broadcast_rgb Automatic
            # x-prop-colorspace Default
            # x-prop-max_bpc 12
            # x-prop-non_desktop 0
            # x-prop-scaling_mode Full aspect
          };
        };
      };

      ## Double screen at Tweag's office, with laptop closed.
      tweag-double-laptop-closed = {
        fingerprint = {
          "DP-3" = tweag1;
          "HDMI-1" = tweag2;
        };
        config = {
          "DP-3" = {
            primary = true;
            mode = "2560x1440";
            position = "0x392";
            # crtc = 0;
            # rate = "59.95";
          };
          "HDMI-1" = {
            mode = "2560x1440";
            position = "2560x0";
            rotate = "left";
            # crtc = 2;
            # rate = "59.95";
          };
        };
      };

      ## Double screen at Tweag's office, with laptop open.
      ## REVIEW: The fact that DP-3 is disabled and HDMI-1 is not rotate is
      ## weird. There is also no primary screen. I think this might be a very
      ## broken configuration.
      tweag-double-laptop-open = {
        fingerprint = {
          "eDP-1" = laptop;
          "DP-3" = tweag1;
          "HDMI-1" = tweag2;
        };
        config = {
          "eDP-1" = {
            mode = "1920x1200";
            position = "0x0";
            # crtc = 1;
            # rate = "59.88";
          };
          "DP-3".enable = false;
          "HDMI-1" = {
            mode = "2560x1440";
            position = "2560x0";
            # crtc = 2;
            # rate = "59.95";
          };
        };
      };

      ## Double screen in Mions, in the office room, with laptop closed.
      mions-office-laptop-closed = {
        fingerprint = {
          "DP-3" = mionsOffice1;
          "HDMI-1" = mionsOffice2;
        };
        config = {
          "DP-3" = {
            primary = true;
            mode = "1920x1080";
            position = "0x0";
            # crtc = 0;
            # rate = "60.00";
          };
          "HDMI-1" = {
            mode = "1920x1080";
            position = "1920x0";
            # crtc = 2;
            # rate = "60.00";
          };
        };
      };

      ## Double screen in Mions, in the office room, with laptop open.
      mions-office-laptop-open = {
        fingerprint = {
          "eDP-1" = laptop;
          "DP-3" = mionsOffice1;
          "HDMI-1" = mionsOffice2;
        };
        config = {
          "eDP-1".enable = false;
          "DP-3" = {
            primary = true;
            mode = "1920x1080";
            position = "0x0";
            # crtc = 0;
            # rate = "60.00";
          };
          "HDMI-1" = {
            mode = "1920x1080";
            position = "1920x0";
            # crtc = 2;
            # rate = "60.00";
          };
        };
      };
    };
  };
}
