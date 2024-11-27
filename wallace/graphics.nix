{
  services.picom.enable = true;

  services.autorandr = {
    enable = true;
    defaultTarget = "default";

    profiles =
      let
        ## Define the screen fingerprints that we will be using.
        laptop = "00ffffffffffff000e6f031400000000001e0104b51e1378032594af5042b0250d4e550000000101010101010101010101010101010180e800a0f0605090302036002ebd10000018000000fd00303c95953c010a202020202020000000fe0043534f542054330a2020202020000000fe004d4e453030375a41312d320a2001a102030f00e3058000e60605016a6a24000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009a";
        philips = "00ffffffffffff00410c4709e57800002e1f0103803c22782ad705aa504aa7270c5054bfef00d1c0b30095008180814081c001010101565e00a0a0a029503020350055502100001e000000ff00554b3032313436303330393439000000fc0050484c2032373642310a202020000000fd00304b1e721e000a2020202020200157020327f14b101f051404130312021101230907078301000065030c001000681a00000101304be6a073006aa0a029500820350055502100001a2a4480a0703827403020350055502100001a023a801871382d40582c450055502100001ef03c00d051a0355060883a0055502100001c0000000000000000000000000000000067";
        projector = "00ffffffffffff003e8d7600580000001b2201038000007808137da256529624124e5f03ef80010181008180d100457c617c813c010104740030f2705a80b0588a00501d7400001e000000ff005137474c4b4141414543000020000000fc004f70746f6d61205548440a2020000000fd0018781f8c3c000a202020202020017a020333f1535f5e101f020507111416205d5e5f626364636423097f078301000072030c002100b83ce0250137018080010203040474801871382d40582c450020c23100001e662156aa51001e30468f330000000000001e04740030f2705a80b0588a00501d7400001e0000000000000000000000000000000000000000000030";
        tweag1 = "00ffffffffffff0030aecf62363632500320010380351e782ef735a7554fa3250c5054adef008180818a9500b300d1c0d100714f8100565e00a0a0a02950302035000f282100001a000000ff0056354748503236360a20202020000000fd00304b1e721e000a202020202020000000fc00453234712d32300a2020202020011002031ef14901020304111213101f230907078301000067030c001000003ccc7400a0a0a01e50302035000f282100001a662156aa51001e30468f33000f282100001e483f403062b0324040c013000f282100001e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000087";
        tweag2 = "00ffffffffffff0030aecf62383832500320010380351e782ef735a7554fa3250c5054adef008180818a9500b300d1c0d100714f8100565e00a0a0a02950302035000f282100001a000000ff0056354748503238380a20202020000000fd00304b1e721e000a202020202020000000fc00453234712d32300a2020202020010802031ef14901020304111213101f230907078301000067030c001000003ccc7400a0a0a01e50302035000f282100001a662156aa51001e30468f33000f282100001e483f403062b0324040c013000f282100001e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000087";
        mionsOffice1 = "00ffffffffffff00410c0cc22d1a0000131e0103803c22782ae445a554529e260d5054bfef00d1c0b30095008180814081c001010101565e00a0a0a029503020350055502100001ea073006aa0a029500820350055502100001a000000fc0050484c2032373545310a202020000000fd00304b1e721e000a2020202020200120020327f14b101f051404130312021101230907078301000065030c001000681a00000101304b00023a801871382d40582c450055502100001e8c0ad08a20e02d10103e96005550210000188c0ad090204031200c405500555021000018f03c00d051a0355060883a0055502100001c00000000000000000000000000000000ad";
        mionsOffice2 = "00ffffffffffff0009d1e77845540000081d010380351e782e0565a756529c270f5054a56b80d1c0b300a9c08180810081c001010101023a801871382d40582c45000f282100001e000000ff004e324b30303639383031510a20000000fd00324c1e5311000a202020202020000000fc0042656e51204757323438300a2001a9020322f14f901f04130312021101140607151605230907078301000065030c001000023a801871382d40582c45000f282100001f011d8018711c1620582c25000f282100009f011d007251d01e206e2855000f282100001e8c0ad08a20e02d10103e96000f282100001800000000000000000000000000000000000000000003";

        ## Single Philips screen, with laptop closed.
        make-philips-laptop-closed = key: {
          fingerprint = {
            ${key} = philips;
          };
          config = {
            ${key} = {
              primary = true;
              mode = "2560x1440";
            };
          };
        };

        ## Single Philips screen, with laptop open.
        make-philips-laptop-open = key: {
          fingerprint = {
            "eDP-1" = laptop;
            ${key} = philips;
          };
          config = {
            "eDP-1".enable = false;
            ${key} = {
              primary = true;
              mode = "2560x1440";
            };
          };
        };

        ## Double screen at Tweag's office, with laptop closed.
        make-tweag-double-laptop-closed = key: {
          fingerprint = {
            ${key} = tweag1;
            "HDMI-1" = tweag2;
          };
          config = {
            ${key} = {
              primary = true;
              mode = "2560x1440";
              position = "0x392";
            };
            "HDMI-1" = {
              mode = "2560x1440";
              position = "2560x0";
              rotate = "left";
            };
          };
        };

        ## Double screen at Tweag's office, with laptop open.
        make-tweag-double-laptop-open = key: {
          fingerprint = {
            "eDP-1" = laptop;
            ${key} = tweag1;
            "HDMI-1" = tweag2;
          };
          config = {
            "eDP-1".enable = false;
            ${key} = {
              primary = true;
              mode = "2560x1440";
              position = "0x392";
            };
            "HDMI-1" = {
              mode = "2560x1440";
              position = "2560x0";
              rotate = "left";
            };
          };
        };

        ## Double screen in Mions, in the office room, with laptop closed.
        make-mions-office-laptop-closed = key: {
          fingerprint = {
            ${key} = mionsOffice1;
            "HDMI-1" = mionsOffice2;
          };
          config = {
            ${key} = {
              primary = true;
              mode = "1920x1080";
              position = "0x0";
            };
            "HDMI-1" = {
              mode = "1920x1080";
              position = "1920x0";
            };
          };
        };

        ## Double screen in Mions, in the office room, with laptop open.
        make-mions-office-laptop-open = key: {
          fingerprint = {
            "eDP-1" = laptop;
            ${key} = mionsOffice1;
            "HDMI-1" = mionsOffice2;
          };
          config = {
            "eDP-1".enable = false;
            ${key} = {
              primary = true;
              mode = "1920x1080";
              position = "0x0";
            };
            "HDMI-1" = {
              mode = "1920x1080";
              position = "1920x0";
            };
          };
        };

      in
      {
        ## Default, with laptop screen only.
        default = {
          fingerprint = {
            "eDP-1" = laptop;
          };
          config = {
            "eDP-1" = {
              primary = true;
              mode = "1920x1200";
            };
          };
        };

        projector = {
          fingerprint = {
            "eDP-1" = laptop;
            "HDMI-1" = projector;
          };
          config = {
            "eDP-1".enable = false;
            "HDMI-1" = {
              primary = true;
              mode = "4096x2160";
            };
          };
        };

        ## Single Philips screen, with laptop open and closed and USB-C hub
        ## plugged on first or second port.
        philips-laptop-closed-usbc-1st-port = make-philips-laptop-closed "DP-3";
        philips-laptop-closed-usbc-2nd-port = make-philips-laptop-closed "DP-2";
        philips-laptop-open-usbc-1st-port = make-philips-laptop-open "DP-3";
        philips-laptop-open-usbc-2nd-port = make-philips-laptop-open "DP-2";

        ## Double screen at Tweag's office, with laptop open and closed and USB-C
        ## hub plugged on first or second port.
        tweag-double-laptop-closed-usbc-1st-port = make-tweag-double-laptop-closed "DP-3";
        tweag-double-laptop-closed-usbc-2nd-port = make-tweag-double-laptop-closed "DP-2";
        tweag-double-laptop-open-usbc-1st-port = make-tweag-double-laptop-open "DP-3";
        tweag-double-laptop-open-usbc-2nd-port = make-tweag-double-laptop-open "DP-2";

        ## Double screen in Mions, in the office room, with laptop open and closed
        ## and USB-C hub plugged on first or second port.
        mions-office-laptop-closed-usbc-1st-port = make-mions-office-laptop-closed "DP-3";
        mions-office-laptop-closed-usbc-2nd-port = make-mions-office-laptop-closed "DP-2";
        mions-office-laptop-open-usbc-1st-port = make-mions-office-laptop-open "DP-3";
        mions-office-laptop-open-usbc-2nd-port = make-mions-office-laptop-open "DP-2";
      };
  };
}
