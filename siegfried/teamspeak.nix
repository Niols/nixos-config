{ pkgs, ... }:

{
  services.teamspeak3 = {
    enable = true;
    openFirewall = true;
    dataDir = "/hester/siegfried/teamspeak";
  };

  nixpkgs.config.allowUnfreePredicate =
    (pkg: builtins.elem (pkgs.lib.getName pkg) [ "teamspeak-server" ]);
}
