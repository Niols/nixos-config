{
  imports = [ ../_common/headless.nix ];

  ## TODO: Move to _common/both and make them as default
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";
}
