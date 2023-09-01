{ pkgs, ... }:

{
  services.teamspeak3 = {
    enable = true;
    openFirewall = true;
    dataDir = "/hester/services/teamspeak";
    logDir = "/hester/services/teamspeak/logs";
  };

  users.groups.hester.members = [ "teamspeak" ];

  nixpkgs.config.allowUnfreePredicate =
    (pkg: builtins.elem (pkgs.lib.getName pkg) [ "teamspeak-server" ]);
}
