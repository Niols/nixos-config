{
  writeShellApplication,
  git,
  nix-output-monitor,
  home-manager,
}:

writeShellApplication {
  name = "rebuild";
  runtimeInputs = [
    git
    nix-output-monitor
    home-manager
  ];
  excludeShellChecks = [ "SC2016" ];
  text = builtins.readFile ./rebuild.sh;
}
