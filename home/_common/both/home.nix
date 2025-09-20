{ lib, ... }:

let
  inherit (builtins) getEnv;
  inherit (lib) mkDefault;

in

{
  home.username = mkDefault (getEnv "USER");
  home.homeDirectory = mkDefault (getEnv "HOME");
}
