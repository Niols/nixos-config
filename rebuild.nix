{
  writeShellApplication,
  git,
  home-manager,
}:

writeShellApplication {
  name = "rebuild";
  runtimeInputs = [
    git
    home-manager
  ];
  excludeShellChecks = [ "SC2016" ];
  text = builtins.readFile ./rebuild.sh;
}
