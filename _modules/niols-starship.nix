{ config, lib, ... }:

## My wrapper around the `programs.starship` Home Manager configuration.
## cf https://starship.rs/ for configuration options etc.

let
  ## open and close box
  obox = style: "[▐](${style})";
  cbox = style: "[▌](${style})";
  ## box, left- and right- boxes
  box = style: text: "${obox style}${text}${cbox style}";
  lbox = style: text: "${obox style}${text}";
  rbox = style: text: "${text}${cbox style}";
in

{
  options.niols-starship = with lib; {
    enable = mkEnableOption (mdDoc "niols-starship");
    hostcolour = mkOption {
      type = types.str;
      description = mdDoc "Colour of the machine.";
    };
  };

  config = lib.mkIf config.niols-starship.enable {
    programs.starship = {
      enable = true;

      settings = {
        format = ''
          $status in $cmd_duration
          $username$hostname$directory$git_branch$git_commit$git_state$git_metrics$git_status$nix_shell
          $character
        '';

        status.disabled = false;
        status.format = "$symbol";
        status.success_symbol = "[✓ $status](bold fg:${config.niols-starship.hostcolour})";
        status.symbol = "[✗ $status](bold fg:red)";

        cmd_duration.min_time = 0;
        cmd_duration.format = "[$duration]($style)";
        cmd_duration.style = "";

        username.show_always = true;
        username.format = "[$user@]($style)";
        username.style_root = "fg:black bg:red";
        username.style_user = "fg:black bg:${config.niols-starship.hostcolour}";

        hostname.ssh_only = false;
        hostname.format = rbox "${config.niols-starship.hostcolour}" "[$hostname$ssh_symbol](fg:black bg:${config.niols-starship.hostcolour})";
        hostname.ssh_symbol = "🌐";

        directory = {
          format = box "bright-black" "[$path]($style bg:bright-black)";
          repo_root_format = box "bright-black"
            "[$before_root_path]($before_repo_root_style bg:bright-black)[$repo_root]($repo_root_style bg:bright-black)[$path]($style bg:bright-black)[$read_only]($read_only_style bg:bright-black)";
          style = "fg:white";
          repo_root_style = "fg:white";
          before_repo_root_style = "fg:black";
          truncation_length = 5;
          truncate_to_repo = false;
          truncation_symbol = "…";
        };

        git_branch.format = lbox "bright-yellow"
          "[ $branch(:$remote_branch)](fg:black bg:bright-yellow)";
        git_commit.format =
          lbox "bright-yellow" "[ \\($hash$tag\\)](fg:black bg:bright-yellow)";
        git_status.format = rbox "bright-yellow"
          "[(\\[$all_status$ahead_behind\\])](fg:black bg:bright-yellow)";

        nix_shell.format = box "bright-cyan" "[$symbol$state]($style)";
        nix_shell.symbol = "";
        nix_shell.impure_msg = "";
        nix_shell.style = "fg:black bg:bright-cyan";

        character.success_symbol = "\\$";
        character.error_symbol = "\\$";
      };
    };
  };
}
