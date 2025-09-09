{ config, ... }:

let
  modifier = config.xsession.windowManager.i3.config.modifier;

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
        # "${modifier}+h" = "split h" ## NOTE: clashes with `focus left`
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
        "${modifier}+Return" = "exec ~/.config/i3/terminal.sh";
        "${modifier}+Enter" = "exec ~/.config/i3/terminal.sh";
        "${modifier}+BackSpace" = "exec ~/.config/i3/explorer.sh";
        "${modifier}+Shift+q" = "kill";
        "${modifier}+d" = "exec rofi -show drun";
        "${modifier}+slash" = "exec rofi -show window";
        "${modifier}+period" = "exec rofi -show calc";
        "${modifier}+comma" = "exec rofimoji --files math";
        "XF86Display" = "exec arandr";
        "${modifier}+p" = "exec arandr";
        "Print" = "exec xfce4-screenshooter --region"; # FIXME: was `--release`?
        "Shift+Print" = "exec xfce4-screenshooter --fullscreen"; # FIXME: was `--release`?
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
          statusCommand = "py3status -c ~/.config/i3/status.conf"; # FIXME: point to file
          workspaceButtons = true;
          extraConfig = ''
            separator_symbol " | "
          '';
        }
      ];
    };
  };
}
