{
  imports = [
    ../_common/laptop
    ./packages.nix
  ];

  home.username = "work";
  home.homeDirectory = "/home/work";

  home.file.".face".source = ./face.jpg;

  programs.ssh.matchBlocks."*" = {
    identitiesOnly = true;
    identityFile = "~/.ssh/id_ahrefs";
  };
}
