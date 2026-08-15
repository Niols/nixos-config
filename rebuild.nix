{
  writeShellApplication,
  git,
  nix-output-monitor,
  home-manager,
  readFile,
}:

writeShellApplication {
  name = "rebuild";
  runtimeInputs = [
    git
    nix-output-monitor
    home-manager
  ];
  excludeShellChecks = [ "SC2016" ];
  text = readFile ./rebuild.sh;
}
