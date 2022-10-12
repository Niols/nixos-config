{ emacs-overlay, ... }:

{
  nixpkgs.overlays = [

    ## `emacs-overlay` provides `emacsUnstable` (last release on Emacs's git)
    ## and `emacsGit` (last commit on the master branch).
    ## cf https://github.com/nix-community/emacs-overlay
    ##
    emacs-overlay.overlay

    ## Custom overlay to brutally replace `emacs` by `emacsGit`.
    (self: super: { emacs = self.emacsGit; })

  ];
}
