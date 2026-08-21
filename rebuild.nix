{
  flakeRoot,
  writeShellApplication,
  git,
  home-manager,
  nixos-rebuild-ng,
  nix-output-monitor,
  lib,
}:

let
  inherit (lib)
    concatStringsSep
    attrNames
    mapAttrs'
    ;

  servers = (import ./machines.nix).servers;

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
    __nix__all_deploy_targets = concatStringsSep " " (attrNames servers);
  }
  // (mapAttrs' (name: _meta: {
    name = "__nix__deploy_target_user__${name}";
    value = "root";
  }) servers)
  // (mapAttrs' (name: meta: {
    name = "__nix__deploy_target_host__${name}";
    value = meta.ipv4 or meta.ipv6 or "${name}.niols.fr";
  }) servers);
}
