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

  ## NOTE: XDG Desktop Portal (XDP) is how modern applications query system
  ## settings and access resources. By default, the portal automatically selects
  ## from all available backend implementations. For the Settings interface
  ## (org.freedesktop.impl.portal.Settings), at least both xapp and gtk backends
  ## are available. However, xapp does not properly read GTK settings or dconf,
  ## causing applications like Firefox and Nautilus to receive incorrect dark
  ## mode preferences. We explicitly configure the gtk backend here to ensure
  ## consistent behavior.
  xdg.portal = {
    enable = true; # already the case
    config = {
      xfce = {
        "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
      };
    };
  };
}
