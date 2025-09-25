{ config, inputs, ... }:

{
  nix = {
    settings.trusted-users = [ "@wheel" ];

    extraOptions = ''
      experimental-features = nix-command flakes
      builders-use-substitutes = true
    '';

    settings.auto-optimise-store = true;

    ## Automatic garbage collection on servers.
    ##
    gc = {
      automatic = config.x_niols.isServer;
      dates = "daily";
      options = "--delete-old"; # Delete all old generations of profiles.
    };

    ## Do not garbage-collect results of `direnv` or `nix build` as long as
    ## there is a link. This makes sense on laptops that are there for
    ## development purposes.
    ##
    settings.keep-outputs = !config.x_niols.isServer;
    settings.keep-derivations = !config.x_niols.isServer;

    registry.nixpkgs.flake = inputs.nixpkgs;

    settings = {
      ## Substituters that are always used.
      substituters = [
        "https://nix-community.cachix.org"
        "https://cache.nixos.org"
        "https://nix-cache.niols.fr/nixos-config"
      ];

      ## Not used by default but trusted. If a flake uses `extra-substituters`
      ## with these, they will be accepted without issue.
      trusted-substituters = [
        "https://dancelor.cachix.org/"
        "https://pre-commit-hooks.cachix.org/"
        "https://tweag-topiary.cachix.org/"
      ];

      ## Public keys that we trust to put stuff in substituters.
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "dancelor.cachix.org-1:Q2pAI0MA6jIccQQeT8JEsY+Wfwb/751zmoUHddZmDyY="
        "pre-commit-hooks.cachix.org-1:Pkk3Panw5AW24TOv6kz3PvLhlH8puAsJTBbOPmBo7Rc="
        "tweag-topiary.cachix.org-1:8TKqya43LAfj4qNHnljLpuBnxAY/YwEBfzo3kzXxNY0="
        "nixos-config:14mZWfYYiWRRSKGgnUHZ63nHLD8JfkYoj+cNqsbneik="
      ];
    };
  };
}
