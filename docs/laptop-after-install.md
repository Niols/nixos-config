# Laptop installation — what to do afterwards

- Check that all the services are running correctly:
  ```console
  $ systemctl status
  ```

- Connect to Firefox. This will automatically install the right add-ons and
  bring back the bookmarks. Nothing else to do.

- Connect to Nextcloud. This is straightforward once Firefox is set up.

- Set up Autorandr. The default fingerprint is `0000` which will never work. Run
  `autorandr --fingerprint`, find the fingerprint for the display, and set
  `services.autorandr.x_niols.thisLaptopsFingerprint`.

- Set up Syncthing. Start `syncthingtray`, accept to “Start guided setup”, make
  sure to “Configure Syncthing Tray for currently running Syncthing instance”.

- Transfer GPG and SSH keys. ???

- Set up Steam's directory, if using the unencrypted `/opt`. ???

- Set up Thunderbird. ???

- Set up Doom Emacs. ??? (unless we push Doom into the Nix configuration)
