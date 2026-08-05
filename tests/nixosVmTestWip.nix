{
  self,
  inputs,
  lib,
  pkgs,
  config,
  hostPkgs,
  ...
}:

let
  # inherit (builtins)
  #   concatStringsSep
  #   toJSON
  #   ;
  # inherit (lib)
  #   fileset
  #   genAttrs
  #   attrNames
  #   ;
  # inherit (hostPkgs)
  #   runCommand
  #   writeText
  #   system
  #   ;

  # forConcat = xs: f: concatStringsSep "\n" (map f xs);

  # ## We will need to override some inputs by the empty flake, so we make one.
  # emptyFlake = runCommand "empty-flake" { } ''
  #   mkdir $out
  #   echo "{ outputs = { self }: {}; }" > $out/flake.nix
  # '';

  # sourceFileset = fileset.toSource {
  #   root = ../..;
  #   fileset = fileset.unions [
  #     ## NOTE: our custom flake-under-test but with the official lock
  #     ./flake-under-test.nix
  #     ../../flake.lock

  #     ./deployment.nix
  #     ./targetNode.nix
  #     ./targetComponent.nix
  #   ];
  # };

  machines = import ../machines.nix;

  inherit
    (import ../nixos/nixosModuleFor.nix {
      inherit
        self
        inputs
        lib
        machines
        ;
      pkgsFor = _: pkgs;
    })
    nixosModuleFor
    specialArgsFor
    ;

  helgaModule = nixosModuleFor "helga";

in
{
  _class = "nixosTest";

  name = "FIXME";

  node.specialArgs = specialArgsFor "helga";
  node.pkgsReadOnly = false;

  nodes = {
    helga = {
      imports = [ helgaModule ];
    };
  };

  testScript = ''
    helga.start()
    helga.wait_for_unit("multi-user.target")

    with subtest("Check the deployment"):
      helga.succeed("echo foo 1>&2")
  '';
}
