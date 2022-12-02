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
