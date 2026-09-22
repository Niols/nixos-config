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
      "*.swp"
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

      init.defaultBranch = "main";

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

      ## I have a personal and an Ahrefs GitHub accounts that do not share the
      ## same SSH key. SSH does not know how to disambiguate and will try all
      ## identities in an unspecified way, which might lead to interacting with
      ## a repository with the wrong user. So we use the personal identity by
      ## default, except for certain GitHub orgs (ahrefs, ahrefs-core) for which
      ## we replace the host by a fake host, which SSH can pick up on to inject
      ## the right key.
      url."ssh://git@github.com-ahrefs/ahrefs/".insteadOf = [
        "ssh://git@github.com/ahrefs/"
        "git@github.com:ahrefs/" # scp-like syntax equivalent of the previous one
      ];
      url."ssh://git@github.com-ahrefs/ahrefs-core/".insteadOf = [
        "ssh://git@github.com/ahrefs-core/"
        "git@github.com:ahrefs-core/" # scp-like syntax equivalent of the previous one
      ];
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
        };
      }
    ];
  };

  assertions = [
    {
      ## See comment to Ahrefs's `core.sshCommand` option above.
      assertion =
        let
          catchAll = config.programs.ssh.matchBlocks."*" or { };
          catchAllSetsIdentityFile =
            (catchAll ? identityFile) || ((catchAll.extraOptions or { }) ? "IdentityFile");
        in
        !catchAllSetsIdentityFile;
      message = "Cannot set `IdentityFile` in an SSH catch-all block, as that would break the Git configuration that relies on `ssh -i <identity>`.";
    }
  ];
}
