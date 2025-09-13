{ lib, ... }:

{
  enable = true;
  ignores = [
    "*~"
    "*#"
    ".envrc"
    ".direnv"
    ".auctex-auto"
  ];

  ## Require to sign by default, but give a useless key, forcing
  ## myself to setup the key correctly in the future.
  signing.key = "YOU NEED TO EXPLICITLY SETUP THE KEY";
  signing.signByDefault = true;

  ## Change of personality depending on the location in the file tree. This
  ## only switches between personal and profesionnal. Because entries accept
  ## only one condition, we first introduce a `processConditions` function
  ## which will accept `conditions` and flatten them to several uses of
  ## `condition`.
  includes =
    let
      processConditions =
        entries:
        lib.lists.concatMap (
          entry:
          lib.lists.map (condition: {
            condition = condition;
            contents.user = entry.contents.user;
          }) entry.conditions
        ) entries;
    in
    processConditions [
      {
        conditions = [
          "gitdir:~/git/perso/**"
          "gitdir:~/git/paris-branch/**"
          "gitdir:~/git/niols/**"
          "gitdir:~/git/jana/**"
          "gitdir:~/git/boloss/**"
          "gitdir:~/git/colis/**"
          "gitdir:~/git/rscds/**"
          "gitdir:~/.opam/plugins/opam-publish/repos/**"
          "gitdir:/etc/nixos/**"
        ];
        contents.user = {
          name = "Niols";
          email = "niols@niols.fr";
          signingKey = "2EFDA2F3E796FF05ECBB3D110B4EB01A5527EA54";
        };
      }
    ];

  extraConfig = {
    init.defaultBranch = "main";

    ## FIXME: Maybe this should rather be in Siegfried's configuration?
    safe.directory = [ "/hester/services/git/niols.fr.git" ];

    ## Used by forge (via ghub) to access GitHub.
    github.user = "niols";

    ## Set remote automatically for branches without a tracking upstream.
    push.autoSetupRemote = true;
  };

  # ## Rewrite GitHub's https:// URI to ssh://
  # extraConfig.url = {
  #   "ssh://git@github.com" = {
  #     insteadOf = "https://github.com";
  #   };
  # };

  ## Enable git LFS
  lfs.enable = true;

  ## Lesser Known Git Commands, by Tim Pettersen
  ## https://dzone.com/articles/lesser-known-git-commands
  aliases = {
    it = "!git init && git commit -m root --allow-empty";
    commend = "commit --amend --no-edit";
    grog = ''
      log --graph --abbrev-commit --decorate --all --format=format:"%C(bold blue)
      %h%C(reset) - %C(bold cyan)%aD%C(dim white) - %an%C(reset) %C(bold green)(%ar)%C(reset)%C(bold
       yellow)%d%C(reset)%n %C(white)%s%C(reset)"'';
  };
}
