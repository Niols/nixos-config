{
  nix.gc = {
    automatic = true;
    options = "--delete-old"; # Delete all old generations of profiles.
  };
}
