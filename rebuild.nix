{
  ## callPackage'd arguments
  writeShellApplication,
  git,
  home-manager,
  nixos-rebuild-ng,
  nix-output-monitor,
  writeText,
  lib,
  ## custom arguments
  flakeRoot,
  servers ? ((import ./machines.nix).servers),
  keys ? ((import ./keys/keys.nix).machines),
}:

let
  inherit (lib)
    concatStringsSep
    attrNames
    listToAttrs
    concatMap
    ;

  serverNames = attrNames servers;
  hostFor = name: servers.${name}.ipv4 or servers.${name}.ipv6 or "${name}.niols.fr";
  knownHosts = concatStringsSep "\n" (map (name: "${hostFor name} ${keys.${name}}") serverNames);

in

writeShellApplication {
  name = "rebuild";
  runtimeInputs = [
    git
    home-manager
    nixos-rebuild-ng
    nix-output-monitor
  ];
  excludeShellChecks = [ "SC2016" ];
  text = builtins.readFile ./rebuild.sh;

  ## NOTE: The `rebuild` script needs to know some things from the flake.
  ## It could call Nix, but we find it easier to just inject things statically.
  runtimeEnv = {
    __nix__flake_root = flakeRoot;
    __nix__all_deploy_targets = concatStringsSep " " serverNames;
    __nix__known_hosts_file = writeText "known-hosts" knownHosts;
  }
  // (listToAttrs (
    concatMap (name: [
      {
        name = "__nix__deploy_target_user__${name}";
        value = "root";
      }
      {
        name = "__nix__deploy_target_host__${name}";
        value = hostFor name;
      }
    ]) serverNames
  ));
}
