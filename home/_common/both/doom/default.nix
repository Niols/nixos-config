{
  inputs,
  pkgs,
  lib,
  ...
}:

{
  ## Make sure that Home Manager is disabled for Emacs, we will handle things ourselves.
  programs.emacs.enable = false;

  home.packages = (
    with pkgs;
    [
      emacs
      cmake # necessary for Emacs's `vterm`
      libtool # necessary for Emacs's `vterm`
      nerd-fonts.symbols-only
      nodejs # necessary for Emacs's `copilot`
      python3 # needed by TreeMacs
      (aspellWithDicts (
        dicts: with dicts; [
          fr
          uk
        ]
      ))
      vim # useful when Emacs is broken/not set-up yet
    ]
  );

  home.activation.doom = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    set -xeuC

    readonly emacsdir=$HOME/.config/emacs
    readonly emacslocaldir=$emacsdir/.local

    readonly narhash=${inputs.doomemacs.narHash}
    readonly narhashfile=$emacslocaldir/narhash
    readonly lastmodified=${toString inputs.doomemacs.lastModified}
    readonly lastmodifiedfile=$emacslocaldir/lastmodified

    ## For increased reproducibility, always run doom as if from the exact time
    ## where the lastModified commit is from. NOTE: We do not use the flake
    ## `-f`, such that we allow time to pass. This gives less reproducibility,
    ## but otherwise the compilation of company-math hangs, somehow.
    doom () {
      ${pkgs.libfaketime}/bin/faketime "$(date --date="@$lastmodified" +'%F %T')" \
        "$emacsdir"/bin/doom --emacsdir "$emacsdir" --doomdir ${./.} "$@"
    }

    ## A temporary directory to move (parts of) the .local directory to.
    readonly tmplocaldir=$(mktemp -d)

    ## A utility to save a file from $emacslocaldir into $tmplocaldir.
    save_local_file () {
      if [ -e "$emacslocaldir"/"$1" ]; then
        mkdir -p "$(dirname "$tmplocaldir"/"$1")"
        cp -R "$emacslocaldir"/"$1" "$tmplocaldir"/"$1"
      fi
    }

    ## Look at the current installation and detect whether we should
    ## (re-)install Doom Emacs. In the case of a re-installation, save the parts
    ## of the .local directory that we care about.
    ##
    if ! [ -e "$emacsdir" ]; then
      echo "$emacsdir does not exist; we will proceed with a fresh installation."
      must_install=true
    elif ! [ -e "$narhashfile" ] || ! [ -e "$lastmodifiedfile" ] || [ "$(cat "$narhashfile")" != "$narhash" ] || [ "$(cat "$lastmodifiedfile")" != "$lastmodified" ]; then
      echo "$emacsdir exists, but does not match that of the flake; we will proceed with a re-installation."
      must_install=true
      save_local_file etc
      save_local_file cache/projectile/projects.eld
    else
      echo "$emacsdir exists and Doom Emacs has not been updated in the flake; we will only synchronise the configuration."
      must_install=false
    fi

    if $must_install; then
      echo "(Re-)installing Doom Emacs..."
      rm -Rf "$emacsdir"
      cp -R ${inputs.doomemacs} "$emacsdir"
      chmod -R u+w "$emacsdir"
      mv "$tmplocaldir" "$emacslocaldir"
      echo "$narhash" > $narhashfile
      echo "$lastmodified" > $lastmodifiedfile
      doom install --force
    fi

    rm -Rf "$tmplocaldir"

    echo "Syncing Doom Emacs's configuration..."
    doom sync --force
  '';

  ## Enable true color/24-bit color support. This makes Emacs pretty in the
  ## terminal (otherwise it is okay-ish but not really usable). However, this
  ## might break some terminals that do not have support for it.
  ## FIXME: Does not work.
  home.sessionVariables.TERM = "xterm-direct";
}
