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

      xdg.dataFile."sounds/sf2/SalamanderGrandPiano.sf2".source =
        let
          salamanderPackage = pkgs.callPackage ./soundfont-salamander-grand-piano.nix { };
        in
        "${salamanderPackage}/share/sounds/sf2/SalamanderGrandPiano.sf2";

      ## Start Nextcloud automatically on startup.
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
        "${nextcloud-client}/share/applications/com.nextcloud.desktopclient.nextcloud.desktop"
      ];
    })

    ## Start LocalSend automatically on startup, for all graphical sessions.
    ##
    ## NOTE: There is a desktop file shipped with LocalSend, but we want to run
    ## it with option `--hidden` so that it starts only as a tray.
    ##
    (mkIf (!config.x_niols.isHeadless) {
      xdg.autostart.enable = true;
      xdg.autostart.entries = [
        (pkgs.writeText "localsend-autostart.desktop" ''
          [Desktop Entry]
          Categories=GTK;FileTransfer;Utility
          Exec=${pkgs.localsend}/bin/localsend_app --hidden
          GenericName=An open source cross-platform alternative to AirDrop
          Icon=localsend
          Keywords=Sharing;LAN;Files
          Name=LocalSend
          StartupNotify=true
          StartupWMClass=localsend_app
          Type=Application
          Version=${pkgs.localsend.version}
        '')
      ];

    })
  ];
}
