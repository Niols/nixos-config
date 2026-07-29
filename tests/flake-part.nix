{
  self,
  inputs,
  lib,
  ...
}:

let
  inherit (lib)
    mkMerge
    optionalAttrs
    ;

in
{
  _class = "flake";

  perSystem =
    { pkgs, system, ... }:
    {
      checks = mkMerge [
        ## The nixops-deployment test can technically run on all platforms, but that makes
        ## `nix flake check` quite wasteful; we limit it to x86_64-linux here.
        (optionalAttrs (system == "x86_64-linux") {
          nixops-deployment = import ./nixops-deployment {
            inherit (pkgs.testers) runNixOSTest;
            inherit inputs;
          };
        })

        (optionalAttrs (system == "x86_64-linux") {
          nixos-helga = pkgs.testers.runNixOSTest {
            imports = [ ./nixosVmTestWip.nix ];
            _module.args = { inherit self inputs lib; };
          };
        })
      ];
    };
}
