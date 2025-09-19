{ config, pkgs, ... }:

let
  inherit (pkgs) writeShellScript;
  modifier = config.xsession.windowManager.i3.config.modifier;

  terminalScript = writeShellScript "terminal.sh" ''
    for bin in xfce4-terminal i3-sensible-terminal; do
      if command -v "$bin" >/dev/null 2>&1; then
        exec "$bin"
      fi
    done
    exit 7
  '';

  explorerScript = writeShellScript "explorer.sh" ''
    ## FIXME: others?
    for bin in nautilus thunar; do
      if command -v "$bin" >/dev/null 2>&1; then
        exec "$bin"
      fi
    done
    exit 7
  '';

in
{
  xsession.windowManager.i3 = {
    enable = true;

    config = {
      modifier = "Mod4";

      fonts = {
        names = [ "pango" ];
        style = "monospace";
        size = 8.0;
      };

      ## Within workspaces
      keybindings = {
        "${modifier}+h" = "focus left";
        "${modifier}+j" = "focus down";
        "${modifier}+k" = "focus up";
        "${modifier}+l" = "focus right";
        "${modifier}+Shift+h" = "move left";
        "${modifier}+Shift+j" = "move down";
        "${modifier}+Shift+k" = "move up";
        "${modifier}+Shift+l" = "move right";
        # "${modifier}+h" = "split h" ## NOTE: clashes with `focus left` FIXME: maybe v and S like in Doom?
        "${modifier}+v" = "split v";
        "${modifier}+f" = "fullscreen toggle";
        "${modifier}+s" = "layout stacking";
        "${modifier}+z" = "layout tabbed";
        "${modifier}+e" = "layout toggle split";
        "${modifier}+Shift+space" = "floating toggle";
        "${modifier}+space" = "focus mode_toggle";
        "${modifier}+q" = "focus parent";
        "${modifier}+w" = "focus child";
      };

      ## Change workspaces
      workspaceAutoBackAndForth = true;
      keybindings = {
        "${modifier}+dead_grave" = "workspace 0";
        "${modifier}+1" = "workspace 1";
        "${modifier}+2" = "workspace 2";
        "${modifier}+3" = "workspace 3";
        "${modifier}+4" = "workspace 4";
        "${modifier}+5" = "workspace 5";
        "${modifier}+6" = "workspace 6";
        "${modifier}+7" = "workspace 7";
        "${modifier}+8" = "workspace 8";
        "${modifier}+9" = "workspace 9";
        "${modifier}+0" = "workspace 10";
        "${modifier}+minus" = "workspace 11";
        "${modifier}+equal" = "workspace 12";
        "${modifier}+Shift+dead_grave" = "move container to workspace 0";
        "${modifier}+Shift+1" = "move container to workspace 1";
        "${modifier}+Shift+2" = "move container to workspace 2";
        "${modifier}+Shift+3" = "move container to workspace 3";
        "${modifier}+Shift+4" = "move container to workspace 4";
        "${modifier}+Shift+5" = "move container to workspace 5";
        "${modifier}+Shift+6" = "move container to workspace 6";
        "${modifier}+Shift+7" = "move container to workspace 7";
        "${modifier}+Shift+8" = "move container to workspace 8";
        "${modifier}+Shift+9" = "move container to workspace 9";
        "${modifier}+Shift+0" = "move container to workspace 10";
        "${modifier}+Shift+minus" = "move container to workspace 11";
        "${modifier}+Shift+equal" = "move container to workspace 12";
      };

      ## Outputs
      keybindings = {
        "${modifier}+Shift+Ctrl+h" = "move workspace to output left";
        "${modifier}+Shift+Ctrl+j" = "move workspace to output down";
        "${modifier}+Shift+Ctrl+k" = "move workspace to output up";
        "${modifier}+Shift+Ctrl+l" = "move workspace to output right";
      };

      ## Other keybindings
      keybindings = {
        "${modifier}+Return" = "exec ${terminalScript}";
        "${modifier}+Enter" = "exec ${terminalScript}";
        "${modifier}+BackSpace" = "exec ${explorerScript}";

        "${modifier}+Shift+q" = "kill";
        "${modifier}+d" = "exec rofi -show drun";
        "${modifier}+slash" = "exec rofi -show window";
        "${modifier}+period" = "exec rofi -show calc";
        "${modifier}+comma" = "exec rofimoji --files math";
        "XF86Display" = "exec arandr";
        "${modifier}+p" = "exec arandr";
        "Print" = "exec xfce4-screenshooter --region"; # REVIEW: was `--release` in previous text configuration - what does that change?
        "Shift+Print" = "exec xfce4-screenshooter --fullscreen"; # REVIEW: was `--release` in previous text configuration - what does that change?
        "${modifier}+Shift+r" = "restart";
        "${modifier}+Shift+e" = "exec xfce4-session-logout";
        "${modifier}+Shift+p" = "exec xflock4";
      };

      ## Resizing
      modes.resize = {
        "h" = "resize shrink width  5 px or 5 ppt";
        "j" = "resize grow   height 5 px or 5 ppt";
        "k" = "resize shrink height 5 px or 5 ppt";
        "l" = "resize grow   width  5 px or 5 ppt";
        "Shift+h" = "resize shrink width  1 px or 1 ppt";
        "Shift+j" = "resize grow   height 1 px or 1 ppt";
        "Shift+k" = "resize shrink height 1 px or 1 ppt";
        "Shift+l" = "resize grow   width  1 px or 1 ppt";
        "Escape" = "mode default";
      };
      keybindings."${modifier}+r" = "mode resize";

      bars = [
        {
          statusCommand = "py3status";
          workspaceButtons = true;
          extraConfig = ''
            separator_symbol " | "
          '';
        }
      ];
    };
  };

  programs.i3status = {
    enable = true;
    enableDefault = false;
    package = pkgs.python3Packages.py3status;

    general = {
      colors = true;
      color_good = "#00FF00";
      color_bad = "#FF0000";
      color_degraded = "#FFFF00";
      color_separator = "#FFFF00";
      interval = 1;
    };

    modules = {
      "load" = {
        position = 1;
        settings = {
          format = "CPU: %5min";
          max_threshold = "4";
          format_above_threshold = "CPU: %1min %5min %15min";
        };
      };

      "memory" = {
        position = 2;
        settings = {
          format = "RAM: %free [%percentage_free] free";
          threshold_degraded = "30%";
          threshold_critical = "10%";
        };
      };

      ## FIXME: bring back disk
      # "disk /" = {
      #   position = 3;
      #   settings = {
      #     prefix_type = "custom";
      #     format = "ROM[root]: %free [%percentage_free] free";
      #     low_threshold ="5";
      #   };
      # };

      "ethernet _first_" = {
        position = 4;
        settings = {
          format_up = "Ethernet";
          format_down = "";
        };
      };

      "wireless _first_" = {
        position = 5;
        settings = {
          format_up = "WiFi: %essid [%quality]";
          format_down = "";
          format_quality = "%d%s";
        };
      };

      "battery all" = {
        position = 6;
        settings = {
          format = "%percentage [%remaining%status]";
          format_down = "";
          status_chr = " charging";
          status_bat = " left";
          status_full = "full";
          low_threshold = 30;
          threshold_type = "time";
        };
      };

      "time" = {
        position = 7;
        settings = {
          format = "%Hh%M [%A %d %B %Y]";
        };
      };
    };
  };

  ## Xfce comes with its own keyboard shortcuts that clash with our use of i3,
  ## so we erase them here. In case of annoying keyboard shortcuts, the best is
  ## to run
  ##
  ##     xfconf-query -c xfce4-keyboard-shortcuts -l
  ##
  ## to find the offending shortcut, and then to set it to `null` in the
  ## following configuration. The shortcuts of the form `/*/default/*` are
  ## defaults and therefore not relevant.
  xfconf.settings.xfce4-keyboard-shortcuts = {
    "commands/custom/<Alt>F1" = null;
    "commands/custom/<Alt>F2" = null;
    "commands/custom/<Alt>F2/startup-notify" = null;
    "commands/custom/<Alt>F3" = null;
    "commands/custom/<Alt>F3/startup-notify" = null;
    "commands/custom/<Alt>Print" = null;
    "commands/custom/<Alt><Super>s" = null;
    "commands/custom/HomePage" = null;
    "commands/custom/override" = null;
    "commands/custom/<Primary><Alt>Delete" = null;
    "commands/custom/<Primary><Alt>Escape" = null;
    "commands/custom/<Primary><Alt>f" = null;
    "commands/custom/<Primary><Alt>l" = null;
    "commands/custom/<Primary><Alt>t" = null;
    "commands/custom/<Primary>Escape" = null;
    "commands/custom/<Primary><Shift>Escape" = null;
    "commands/custom/Print" = null;
    "commands/custom/<Shift>Print" = null;
    "commands/custom/<Super>e" = null;
    "commands/custom/<Super>p" = null;
    "commands/custom/<Super>r" = null;
    "commands/custom/<Super>r/startup-notify" = null;
    "commands/custom/XF86Display" = null;
    "commands/custom/XF86Mail" = null;
    "commands/custom/XF86WWW" = null;
  };
}
