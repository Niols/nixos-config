{ config, lib, ... }:

## My wrapper around the `programs.starship` Home Manager configuration.
## cf https://starship.rs/ for configuration options etc.

let
  ## open and close box FIXME: try the other character but ading “inverted” to
  ## the style. this might behave better in selections.
  obox = style: "[▐](${style})";
  cbox = style: "[▌](${style})";
  ## box, left- and right- boxes
  box = style: text: "${obox style}${text}${cbox style}";
  lbox = style: text: "${obox style}${text}";
  rbox = style: text: "${text}${cbox style}";

  fgColourFor =
    let
      t = {
        blue = "white";
      };
    in
    x: if t ? ${x} then t.${x} else "black";

  ## FIXME: Not a great name.
  fgFor = x: "fg:${fgColourFor x} bg:${x}";

in
{
  options.x_niols = with lib; {
    thisMachinesColour = mkOption {
      description = ''
        Colour of the machine.
      '';
      type =
        ## FIXME: Also support `#abcdef` RGB color hex codes, or 0-255 8-bit
        ## ANSI color codes.
        let
          standardTerminalColours = [
            "black"
            "red"
            "green"
            "blue"
            "yellow"
            "purple"
            "cyan"
            "white"
          ];
        in
        types.enum (standardTerminalColours ++ map (c: "bright-${c}") standardTerminalColours);
      default = "green"; # FIXME: really the default?
    };
  };

  config.programs.starship = {
    enable = true;

    settings = {
      format = ''
        $status in $cmd_duration
        $username$hostname$directory$git_branch$git_commit$git_state$git_metrics$git_status$nix_shell
        $character
      '';

      status.disabled = false;
      status.format = "$symbol";
      status.success_symbol = "[✓ $status](bold fg:${config.x_niols.thisMachinesColour})";
      status.symbol = "[✗ $status](bold fg:red)";

      cmd_duration.min_time = 0;
      cmd_duration.format = "[$duration]($style)";
      cmd_duration.style = "";

      username.show_always = true;
      username.format = "[$user@]($style)";
      username.style_root = fgFor "red";
      username.style_user = fgFor config.x_niols.thisMachinesColour;

      hostname.ssh_only = false;
      ## FIXME: try `prev_fg` and `prev_bg` to replicate the colouring of the `username` section.
      hostname.format = rbox "fg:${config.x_niols.thisMachinesColour}" "[$hostname$ssh_symbol](${fgFor config.x_niols.thisMachinesColour})";
      hostname.ssh_symbol = "";

      directory = {
        format = box "bright-black" "[$path]($style bg:bright-black)";
        repo_root_format = box "bright-black" "[$before_root_path]($before_repo_root_style bg:bright-black)[$repo_root]($repo_root_style bg:bright-black)[$path]($style bg:bright-black)[$read_only]($read_only_style bg:bright-black)";
        style = "fg:white";
        repo_root_style = "fg:white";
        before_repo_root_style = "fg:black";
        truncation_length = 5;
        truncate_to_repo = false;
        truncation_symbol = "…";
      };

      git_branch.format = lbox "bright-yellow" "[ $branch(:$remote_branch)](fg:black bg:bright-yellow)";
      git_commit.format = lbox "bright-yellow" "[ \\($hash$tag\\)](fg:black bg:bright-yellow)";
      git_state.format = "[\\($state( $progress_current/$progress_total)\\)](fg:black bg:bright-yellow)";
      git_status.format = rbox "bright-yellow" "[(\\[$all_status$ahead_behind\\])](fg:black bg:bright-yellow)";

      nix_shell.format = box "bright-cyan" "[$symbol$state]($style)";
      nix_shell.symbol = "";
      nix_shell.impure_msg = "";
      nix_shell.style = "fg:black bg:bright-cyan";

      character.success_symbol = "\\$";
      character.error_symbol = "\\$";
    };
  };
}
