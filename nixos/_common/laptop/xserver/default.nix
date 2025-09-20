{ pkgs, ... }:

{
  services.xserver = {
    enable = true;

    ## Keymap: US International.
    ## FIXME: add non-breakable spaces on space bar.
    ## FIXME: add longer dashes somewhere.
    ## FIXME: what about three dots?
    xkb = {
      layout = "us";
      variant = "intl";
    };

    ## XFCE as desktop manager...
    desktopManager = {
      xterm.enable = false;
      xfce = {
        enable = true;
        noDesktop = true;
        enableXfwm = false;
      };
      wallpaper = {
        mode = "scale";
        combineScreens = false;
      };
    };

    ## ...with i3 as window manager.
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu
        i3status
        i3lock
        python3Packages.py3status # # wrapper around i3status
      ];
    };

    ## The display manager choses this combination.
    displayManager = {
      lightdm = {
        enable = true;
        background = ./background.jpg;
        extraConfig = ''
          ## Do not hide users, show their `.face`!
          greeter-hide-users = false
        '';
      };
    };

    ## Enable touchpad support. On the Lenovo X1 Carbon, the touchpad does not
    ## work so great, so we are trying workarounds as described in:
    ## https://github.com/NixOS/nixpkgs/issues/19022
    synaptics.enable = false;
  };

  services = {
    ## The display manager choses this combination.
    displayManager.defaultSession = "xfce+i3";

    ## Enable touchpad support. On the Lenovo X1 Carbon, the touchpad does not
    ## work so great, so we are trying workarounds as described in:
    ## https://github.com/NixOS/nixpkgs/issues/19022
    libinput.enable = true;
  };
}
