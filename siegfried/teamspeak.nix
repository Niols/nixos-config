{ pkgs, ... }:

{
  services.teamspeak3 = {
    enable = true;
    openFirewall = true;
  };

  nixpkgs.config.allowUnfreePredicate =
    (pkg: builtins.elem (pkgs.lib.getName pkg) [ "teamspeak-server" ]);
}
