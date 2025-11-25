{ config, lib, ... }:

let
  inherit (lib) mkOption types;

in
{
  options.services.autorandr.x_niols.thisLaptopsFingerprint = mkOption {
    description = ''
      The fingerprint of the current laptop's screen. This option has a default
      that has no chance to work, but that allows running
      `autorandr --fingerprint` without errors.
    '';
    type = types.str;
    default = "0000";
  };

  config.services.autorandr = {
    enable = true;
    defaultTarget = "default";

    profiles =
      let
        ## Screen fingerprints that we use several times.
        laptop = config.services.autorandr.x_niols.thisLaptopsFingerprint;
        philipsHdmi = "00ffffffffffff00410c4709e57800002e1f0103803c22782ad705aa504aa7270c5054bfef00d1c0b30095008180814081c001010101565e00a0a0a029503020350055502100001e000000ff00554b3032313436303330393439000000fc0050484c2032373642310a202020000000fd00304b1e721e000a2020202020200157020327f14b101f051404130312021101230907078301000065030c001000681a00000101304be6a073006aa0a029500820350055502100001a2a4480a0703827403020350055502100001a023a801871382d40582c450055502100001ef03c00d051a0355060883a0055502100001c0000000000000000000000000000000067";
        philipsUsbC = "00ffffffffffff00410c4709e57800002e1f0104a53c22783ad705aa504aa7270c5054bfef00d1c0b30095008180814081c001010101565e00a0a0a029503020350055502100001e000000ff00554b3032313436303330393439000000fc0050484c2032373642310a202020000000fd00304b1e721e010a2020202020200120020318f14b0103051404131f120211902309070783010000a073006aa0a029500820350055502100001a2a4480a0703827403020350055502100001a023a801871382d40582c450055502100001e011d007251d01e206e28550055502100001ef03c00d051a0355060883a0055502100001c00000000000000000000000000a1";
        lgUsbC = "00ffffffffffff001e6da4770a59050003230104b5502278fedc45ac524f9f250f5054210800d1c061400101010101010101010101017d7d70b0d0a0295038203a00204e3100001a000000fd003b3c1e5a21000a202020202020000000fc004c4720554c545241574944450a000000ff003530334e54585241413437340a014602031f7123090707830100004410040301e2006ae305c000e606050153535d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000068";
        tweag1 = "00ffffffffffff0030aecf62363632500320010380351e782ef735a7554fa3250c5054adef008180818a9500b300d1c0d100714f8100565e00a0a0a02950302035000f282100001a000000ff0056354748503236360a20202020000000fd00304b1e721e000a202020202020000000fc00453234712d32300a2020202020011002031ef14901020304111213101f230907078301000067030c001000003ccc7400a0a0a01e50302035000f282100001a662156aa51001e30468f33000f282100001e483f403062b0324040c013000f282100001e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000087";
        tweag2 = "00ffffffffffff0030aecf62383832500320010380351e782ef735a7554fa3250c5054adef008180818a9500b300d1c0d100714f8100565e00a0a0a02950302035000f282100001a000000ff0056354748503238380a20202020000000fd00304b1e721e000a202020202020000000fc00453234712d32300a2020202020010802031ef14901020304111213101f230907078301000067030c001000003ccc7400a0a0a01e50302035000f282100001a662156aa51001e30468f33000f282100001e483f403062b0324040c013000f282100001e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000087";
        mionsOffice1 = "00ffffffffffff00410c0cc22d1a0000131e0103803c22782ae445a554529e260d5054bfef00d1c0b30095008180814081c001010101565e00a0a0a029503020350055502100001ea073006aa0a029500820350055502100001a000000fc0050484c2032373545310a202020000000fd00304b1e721e000a2020202020200120020327f14b101f051404130312021101230907078301000065030c001000681a00000101304b00023a801871382d40582c450055502100001e8c0ad08a20e02d10103e96005550210000188c0ad090204031200c405500555021000018f03c00d051a0355060883a0055502100001c00000000000000000000000000000000ad";
        mionsOffice2 = "00ffffffffffff0009d1e77845540000081d010380351e782e0565a756529c270f5054a56b80d1c0b300a9c08180810081c001010101023a801871382d40582c45000f282100001e000000ff004e324b30303639383031510a20000000fd00324c1e5311000a202020202020000000fc0042656e51204757323438300a2001a9020322f14f901f04130312021101140607151605230907078301000065030c001000023a801871382d40582c45000f282100001f011d8018711c1620582c25000f282100009f011d007251d01e206e2855000f282100001e8c0ad08a20e02d10103e96000f282100001800000000000000000000000000000000000000000003";
        ahrefsSgOffice1 = "00ffffffffffff001e6d105bf82c0400081b0104a5301b78800f91ae5243b0260f50542000000101010101010101010101010101010125cc0050f0703e8008201800db0b1100001a000000ff003730384e54414238313635360a000000fd00303c588f3c010a202020202020000000fc004c4720556c74726146696e650a0219701279000001000c8e126e0a0010000950784e772900100e4b7caeb474496baa67046db61f7eed030050a5640084ff0e4f0007801f006f081e0000000700bb9c00041f0d4f0007801f006107350000000700a25b0004ff094f0007801f009f05280000000700133400047f074f0007801f0037041e000000070000000000bb907012790000030050f5e70084ff0f4f0007801f00ff084100000007008cb80084ff0f4f0007801f00ff083400000007005c720084ff0f4f0007801f00ff0820000000070024cc0084ff0e4f0007801f006f083d00000007000000000000000000000000000000000000000000000000000000000000000000000000000000af90";

        ## Single screen, with laptop closed.
        make-only-laptop-closed = key: fingerprint: mode: {
          fingerprint = {
            ${key} = fingerprint;
          };
          config = {
            ${key} = {
              primary = true;
              inherit mode;
            };
          };
        };

        ## Single screen, with laptop open.
        make-only-laptop-open = key: fingerprint: mode: {
          fingerprint = {
            "eDP-1" = laptop;
            ${key} = fingerprint;
          };
          config = {
            "eDP-1".enable = false;
            ${key} = {
              primary = true;
              inherit mode;
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

        ## Projector in Waalbandijk, plugged via HDMI, with laptop open.
        projector = {
          fingerprint = {
            "eDP-1" = laptop;
            "HDMI-1" =
              "00ffffffffffff003e8d7600580000001b2201038000007808137da256529624124e5f03ef80010181008180d100457c617c813c010104740030f2705a80b0588a00501d7400001e000000ff005137474c4b4141414543000020000000fc004f70746f6d61205548440a2020000000fd0018781f8c3c000a202020202020017a020333f1535f5e101f020507111416205d5e5f626364636423097f078301000072030c002100b83ce0250137018080010203040474801871382d40582c450020c23100001e662156aa51001e30468f330000000000001e04740030f2705a80b0588a00501d7400001e0000000000000000000000000000000000000000000030";
          };
          config = {
            "eDP-1".enable = false;
            "HDMI-1" = {
              primary = true;
              mode = "4096x2160";
              scale = {
                x = 0.5;
                y = 0.5;
              };
            };
          };
        };

        ## TV at Aggelandros's place in Reykjavik, plugged via HDMI,
        ## with laptop open.
        aggelandros-reykjavik-tv = {
          fingerprint = {
            "eDP-1" = laptop;
            "HDMI-1" =
              "00ffffffffffff005262080101010101ff160103805932780a303da1544a9b260f474a00000001010101010101010101010101010101023a80d072382d40102c458075f23100001e011d80d0721c1620102c258075f23100009e000000fc00544f53484942412d54560a2020000000fd00314c0f510e000a202020202020010502032b71521f2114131216111510050403070206012022260907071507506c030c002000001ec015151f1f011d00bc52d01e20b828554075f23100001e023a801871382d40582c450075f23100001e011d8018711c1620582c250075f23100009e011d007251d01e206e28550075f23100001e000000000000000000000000aa";
          };
          config = {
            "eDP-1" = {
              primary = true;
              mode = "1920x1080";
              position = "0x0";
            };
            "HDMI-1" = {
              mode = "1920x1080";
              position = "0x0";
            };
          };
        };

        ## Desktop screen at Aggelandros, plugging via HDMI, with laptop open.
        ## The angle is peculiar and might not work always.
        aggelandros-reykjavik-desktop = {
          fingerprint = {
            "eDP-1" = laptop;
            "HDMI-1" =
              "00ffffffffffff0030aec860010101013219010380351e782e2195a756529c26105054bdcf00714f8180818c9500b300d1c001010101023a801871382d40582c45000f282100001e000000ff0056314137353534380a20202020000000fd00324b1e5311000a202020202020000000fc004c454e20543234323470410a20013e02031ef14b010203040514111213901f230907078301000065030c001000011d007251d01e206e2855000f282100001e8c0ad08a20e02d10103e96000f28210000188c0ad090204031200c4055000f282100001800000000000000000000000000000000000000000000000000000000000000000000000000000000000000ce";
          };
          config = {
            "eDP-1" = {
              primary = true;
              mode = "1920x1200";
              position = "0x1080";
            };
            "HDMI-1" = {
              mode = "1920x1080";
              position = "1056x0";
            };
          };
        };

        ## Single Philips screen, with laptop open and closed and USB-C hub
        ## plugged on first or second port.
        philips-hdmi-laptop-closed-dp-2 = make-only-laptop-closed "DP-2" philipsHdmi "2560x1440";
        philips-hdmi-laptop-closed-dp-3 = make-only-laptop-closed "DP-3" philipsHdmi "2560x1440";
        philips-usbc-laptop-closed-dp-1-8 = make-only-laptop-closed "DP-1-8" philipsUsbC "2560x1440";
        philips-usbc-laptop-closed-dp-2-8 = make-only-laptop-closed "DP-2-8" philipsUsbC "2560x1440";
        philips-usbc-laptop-closed-dp-3-8 = make-only-laptop-closed "DP-3-8" philipsUsbC "2560x1440";
        philips-hdmi-laptop-open-dp-2 = make-only-laptop-open "DP-2" philipsHdmi "2560x1440";
        philips-hdmi-laptop-open-dp-3 = make-only-laptop-open "DP-3" philipsHdmi "2560x1440";
        philips-usbc-laptop-open-dp-2-8 = make-only-laptop-open "DP-2-8" philipsUsbC "2560x1440";
        philips-usbc-laptop-open-dp-3-8 = make-only-laptop-open "DP-3-8" philipsUsbC "2560x1440";

        ## Single LG screen, with laptop open and closed and USB-C hub
        ## plugged on first or second port.
        lg-usbc-laptop-closed-dp-1 = make-only-laptop-closed "DP-1" lgUsbC "3440x1440";
        lg-usbc-laptop-closed-dp-2 = make-only-laptop-closed "DP-2" lgUsbC "3440x1440";
        lg-usbc-laptop-closed-dp-3 = make-only-laptop-closed "DP-3" lgUsbC "3440x1440";
        lg-usbc-laptop-open-dp-1 = make-only-laptop-open "DP-1" lgUsbC "3440x1440";
        lg-usbc-laptop-open-dp-2 = make-only-laptop-open "DP-2" lgUsbC "3440x1440";
        lg-usbc-laptop-open-dp-3 = make-only-laptop-open "DP-3" lgUsbC "3440x1440";

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

        ## Guest screen at Ahrefs' SG office, with laptop open.
        ahrefs-sg-office-1 = {
          fingerprint = {
            "eDP-1" = laptop;
            "DP-1" = ahrefsSgOffice1;
          };
          config = {
            "eDP-1" = {
              mode = "1920x1200";
              position = "320x1440";
            };
            "DP-1" = {
              primary = true;
              mode = "2560x1440";
              position = "0x0";
            };
          };
        };
      };
  };
}
