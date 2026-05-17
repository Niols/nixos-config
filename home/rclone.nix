{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf;

in
{
  config = mkIf (config.x_niols.isPerso && config.x_niols.isGraphical) {
    programs.rclone = {
      enable = true;

      remotes.gdrive = {
        config = {
          type = "drive";
          scope = "drive";
          team_drive = "";
        };
        secrets = {
          client_id = config.age.secrets.rclone-gdrive-client-id.path;
          client_secret = config.age.secrets.rclone-gdrive-client-secret.path;
          token = config.age.secrets.rclone-gdrive-token.path;
        };
      };
    };

    home.packages = [
      (pkgs.writeShellApplication {
        name = "sync-tarcisius";
        text = ''
          for subdir in 'Bladmuziek harmonie orkest' 'Muziekmap leerlingenorkest (huidige muziek)'; do
            echo "Syncing \"$subdir\"..."
            rclone sync \
                gdrive:Tarcisius/"$subdir" \
                ~/.syncthing/MobileSheets/Tarcisius/'0_Google Drive (unstable)'/"$subdir"
            echo "Done syncing \"$subdir\"."
          done
        '';
      })
    ];
  };
}
