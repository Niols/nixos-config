{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    extraOptionOverrides.AddKeysToAgent = "yes";
  };
}
