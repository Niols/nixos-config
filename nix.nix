{
  settings.trusted-users = [ "@wheel" ];

  buildMachines = [
    ## Tweag Remote Builders
    {
      hostName = "build01.tweag.io";
      maxJobs = 24;
      sshUser = "nix";
      sshKey = "/root/.ssh/id-tweag-builder";
      system = "x86_64-linux";
      supportedFeatures = [ "benchmark" "big-parallel" "kvm" ];
    }
    {
      hostName = "build02.tweag.io";
      maxJobs = 24;
      sshUser = "nix";
      sshKey = "/root/.ssh/id-tweag-builder";
      systems = ["aarch64-darwin" "x86_64-darwin"];
      supportedFeatures = [ "benchmark" "big-parallel" ];
    }
  ];

  extraOptions = ''
      builders-use-substitutes = true

      ## Required to use the `nix` CLI and `nix search` in particular.
      experimental-features = nix-command flakes
    '';

  settings = {
    ## Substituters that are always used.
    substituters = [
      "https://nix-community.cachix.org"
      "https://cache.nixos.org"
    ];

    ## Not used by default but trusted. If a flake uses `extra-substituters`
    ## with these, they will be accepted without issue.
    trusted-substituters = [
      "https://cache.iog.io"
      "https://iohk.cachix.org"
      "https://public-plutonomicon.cachix.org"
      "https://tweag-tree-sitter-formatter.cachix.org"
    ];

    ## Public keys that we trust to put stuff in substituters.
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=" ## for cache.iog.io
      "iohk.cachix.org-1:DpRUyj7h7V830dp/i6Nti+NEO2/nhblbov/8MW7Rqoo="
      "public-plutonomicon.cachix.org-1:3AKJMhCLn32gri1drGuaZmFrmnue+KkKrhhubQk/CWc"
      "tweag-tree-sitter-formatter.cachix.org-1:R95oCa9JV/Cu8dtdFZY55HLFqJ3ASh34dXh7o7LeL5Y="
    ];
  };

  ## Garbage-collect automatically everything that is at least a month old. Do
  ## not garbage-collect results of `direnv` or `nix build` as long as there
  ## is a link.
  ##
  settings.auto-optimise-store = true;
  settings.keep-outputs = true;
  settings.keep-derivations = true;
  # gc = {
  #   automatic = true;
  #   dates = "daily";
  #   options = "--delete-older-than 31d";
  # };
}
