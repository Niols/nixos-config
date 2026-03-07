{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    ## NOTE: NixOps4 has become a bit complicated recently, so I keep things in
    ## sync manually. This involves fixing the specific commit of nixops4 and
    ## nixpkgs (which itself means duplicating nixpkgs) from nixops4-nixos's
    ## development flake. See https://github.com/nixops4/nixops4-nixos/issues/17
    nixpkgs-for-nixops4.url = "github:NixOS/nixpkgs/e6eae2ee2110f3d31110d5c222cd395303343b08";
    nixops4.url = "github:nixops4/nixops4/75ebb067893d1ff071b481a7696563c99917421b";
    nixops4.inputs.nixpkgs.follows = "nixpkgs-for-nixops4";
    nixops4-nixos.url = "github:nixops4/nixops4-nixos";
    nixops4-nixos.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    flake-parts.url = "github:hercules-ci/flake-parts";

    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.darwin.follows = ""; # saves some resources on Linux

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    dancelor.url = "github:paris-branch/dancelor";

    doomemacs.url = "github:doomemacs/doomemacs";
    doomemacs.flake = false;
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      imports = [
        inputs.nixops4.modules.flake.default
      ];

      nixops4.members.check-deployment = {
        imports = [ ./tests/nixops4-deployment/deployment.nix ];
        _module.args = { inherit inputs; };
      };
    };
}
