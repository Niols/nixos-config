{
  inputs,
  system,
  lib,
  ...
}:

let
  inherit (lib) elem getName;

in

import inputs.nixpkgs {
  inherit system;

  config.allowUnfreePredicate =
    pkg:
    elem (getName pkg) [
      "claude-code"
      "discord"
      "slack"
      "steam"
      "steam-unwrapped"
      "teamspeak-client"
      "teamspeak-server"
      "unrar"
      "zoom"
    ];
}
