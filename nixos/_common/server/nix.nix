{
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-old"; # Delete all old generations of profiles.
  };
}
