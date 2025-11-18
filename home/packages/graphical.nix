{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkMerge mkIf;

in
{
  config = mkMerge [
    ## Packages common to laptops.
    (mkIf (!config.x_niols.isHeadless) {
      home.packages = with pkgs; [
        evince
        ffmpeg-full
        file-roller # GNOME archive manager
        filezilla
        nautilus
        nautilus-open-any-terminal
      ];
    })

    ## Packages that are only ever used on my personal laptops. They should not
    ## clutter work's environment, (and that eliminates the temptation to have
    ## Signal or Thunderbird running)!
    (mkIf (!config.x_niols.isHeadless && !config.x_niols.isWork) {
      home.packages = with pkgs; [
        ardour
        asunder
        audacity
        element-desktop
        firefox
        gimp
        gnucash
        inkscape
        ledger-live-desktop
        libreoffice
        lilypond
        localsend # needs to be here AND in `xdg.autostart`
        picard
        nextcloud-client # needs to be here AND in `xdg.autostart`
        signal-desktop
        texlive.combined.scheme-full
        thunderbird
        vdhcoapp # companion for Video DownloadHelper
        vlc
        zoom-us # for SCD meetings
      ];

      ## Start LocalSend and Nextcloud automatically on startup.
      ##
      ## NOTE: There is also `services.nextcloud.enable`, but it has been
      ## causing issues with Nextcloud forgetting its configuration, so we
      ## prefer this.
      ##
      ## NOTE: Make sure that a keyring is running for Nextcloud not to ask for
      ## the password every time.
      ##
      xdg.autostart.enable = true;
      xdg.autostart.entries = with pkgs; [
        "${localsend}/share/applications/LocalSend.desktop"
        "${nextcloud-client}/share/applications/com.nextcloud.desktopclient.nextcloud.desktop"
      ];
    })
  ];
}
