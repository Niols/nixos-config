{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;

    home-manager.url = github:nix-community/home-manager;
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    emacs-overlay.url = github:nix-community/emacs-overlay;
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";

    nix-doom-emacs.url = github:nix-community/nix-doom-emacs;
    nix-doom-emacs.inputs.nixpkgs.follows = "nixpkgs";
    nix-doom-emacs.inputs.emacs-overlay.follows = "emacs-overlay";

    opam-nix.url = github:tweag/opam-nix;
    opam-nix.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = github:NixOS/nixos-hardware/master;
  };

  outputs = inputs: {
    nixosConfigurations.wallace = import ./wallace inputs;
  };
}
