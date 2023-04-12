{ config, pkgs, ... }:

let
  ## Emacs for Haskell is not very Nix-aware and expects a binary called
  ## `haskell-language-server-wrapper`. But Nix environments make this notion
  ## of wrappers irrelevant and therefore they do not provide the binary in
  ## question. This compatibility script adds an executable fallback called
  ## `haskell-language-server-wrapper` that just relays everything to
  ## `haskell-language-server`. This should make my life easier everywhere.
  hlsWrapperCompatScript = pkgs.writeShellApplication {
    name = "haskell-language-server-wrapper";
    text = ''
      exec haskell-language-server "$@"
    '';
  };

in {
  ## Packages installed in system profile. Allow a selected set of
  ## unfree packages for this list.
  nixpkgs.config.allowUnfreePredicate = (pkg:
    builtins.elem (pkgs.lib.getName pkg) [
      "discord"
      "skypeforlinux"
      "slack"
      "steam-run"
      "steam-original"
      "teamspeak-client"
      "unrar"
      "zoom"
    ]);

  environment.systemPackages =
      (import ./system.nix { inherit pkgs; })
      ++ [hlsWrapperCompatScript];
}