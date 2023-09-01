{ pkgs, ... }:

{
  services.teamspeak3.enable = true;

  nixpkgs.config.allowUnfreePredicate =
    (pkg: builtins.elem (pkgs.lib.getName pkg) [ "teamspeak-server" ]);
}
