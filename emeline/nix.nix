{ nixpkgs, ... }:

{
  nix = {
    settings.trusted-users = [ "@wheel" ];

    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    settings.auto-optimise-store = true;

    registry.nixpkgs.flake = nixpkgs;
  };
}
