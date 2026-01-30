{ config, pkgs, ... }:

{
  ## NOTE: The .netrc file could contain more than Git identities, but for now
  ## it doesn't so that will do.
  home.file.".netrc".source =
    let
      netrcPath =
        if config.x_niols.isWork && config.x_niols.isHeadless then
          config.age.secrets.netrc-work.path
        else
          config.age.secrets.netrc-niols.path;
    in
    pkgs.runCommand "netrc" { } "ln -s ${netrcPath} $out";

  programs.git = {
    enable = true;
    ignores = [
      "*~"
      "*#"
      ".envrc"
      ".direnv"
      ".auctex-auto"
      ".pre-commit-config.yaml"
      ".claude"
    ];

    ## Require to sign by default, but give a useless key, forcing
    ## myself to setup the key correctly in the future.
    signing.format = "ssh";
    signing.signByDefault = true;

    ## Enable git LFS
    lfs.enable = true;

    settings = {
      user.name = "Niols";
      user.email = "niols@niols.fr";
      user.signingKey = "~/.ssh/id_niols_signing.pub";

      ## I have a personal and an Ahrefs GitHub accounts that do not share the
      ## same SSH key. SSH does not know how to disambiguate and will try all
      ## identities in an unspecified way, which might lead to interacting with
      ## a repository with the wrong user. We specify the key explicitly here,
      ## but one must make sure that there is no catch-all block in the SSH
      ## config that adds the `id_niols` identity; see `assertions` below.
      core.sshCommand = "ssh -i ~/.ssh/id_niols";

      init.defaultBranch = "main";

      ## FIXME: Maybe this should rather be in Siegfried's configuration?
      safe.directory = [ "/hester/services/git/niols.fr.git" ];

      ## Used by forge (via ghub) to access GitHub.
      github.user = "niols";

      ## Set remote automatically for branches without a tracking upstream.
      push.autoSetupRemote = true;

      ## Lesser Known Git Commands, by Tim Pettersen
      ## https://dzone.com/articles/lesser-known-git-commands
      alias = {
        it = "!git init && git commit -m root --allow-empty";
        commend = "commit --amend --no-edit";
        grog = ''
          log --graph --abbrev-commit --decorate --all --format=format:"%C(bold blue)
          %h%C(reset) - %C(bold cyan)%aD%C(dim white) - %an%C(reset) %C(bold green)(%ar)%C(reset)%C(bold
           yellow)%d%C(reset)%n %C(white)%s%C(reset)"'';
      };
    };

    includes = [
      {
        condition = "gitdir:~/git/ahrefs/**";
        contents = {
          user = {
            name = "Nicolas Jeannerod";
            email = "nicolas.jeannerod@ahrefs.com";
            signingKey = "~/.ssh/id_ahrefs_signing.pub";
          };
          github.user = "nicolas-jeannerod_ahrefs"; # for forge via ghub
          core.sshCommand = "ssh -i ~/.ssh/id_ahrefs";
        };
      }
    ];
  };

  assertions = [
    {
      ## See comment to Ahrefs's `core.sshCommand` option above.
      assertion = !(config.programs.ssh.matchBlocks ? "*") || config.programs.ssh.matchBlocks."*" == { };
      message = "A catch-all block in SSH configuration will break the Git configuration that relies on `ssh -i <identity>`.";
    }
  ];
}
