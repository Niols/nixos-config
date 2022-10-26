{
  settings.trusted-users = [ "@wheel" ];

  ## Tweag Remote Builder
  buildMachines = [ {
    hostName = "build01.tweag.io";
    maxJobs = 24;
    sshUser = "nix";
    sshKey = "/root/.ssh/id-tweag-builder";
    system = "x86_64-linux";
    supportedFeatures = [ "benchmark" "big-parallel" "kvm" ];
  } ];

  extraOptions = ''
      builders-use-substitutes = true

      ## Required to use the `nix` CLI and `nix search` in particular.
      experimental-features = nix-command flakes
    '';

  ## Substituters, both usual and work-specific.
  ##
  settings.substituters = [
    "https://cache.nixos.org"
    "https://nix-community.cachix.org"
    "https://hydra.iohk.io"
    "https://iohk.cachix.org"
    "https://public-plutonomicon.cachix.org"
  ];
  settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
    "iohk.cachix.org-1:DpRUyj7h7V830dp/i6Nti+NEO2/nhblbov/8MW7Rqoo="
    "public-plutonomicon.cachix.org-1:3AKJMhCLn32gri1drGuaZmFrmnue+KkKrhhubQk/CWc="
  ];

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
