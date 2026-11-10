{
  ## Suspend when closing the lid, but hibernate after 3 hours or when the
  ## battery gets below 5%, except on AC power.

  ## NOTE: See also `home/i3.nix` for screen locking options.

  services.logind.settings.Login.HandleLidSwitch = "suspend-then-hibernate";

  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "3h";
    HibernateOnACPower = false;
  };
}
