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
          target=~/.syncthing/MobileSheets/Tarcisius/'0_Google Drive (unstable)'

          for subdir in 'Bladmuziek harmonie orkest' 'Muziekmap leerlingenorkest (huidige muziek)'; do
            echo "Syncing \"$subdir\"..."
            rclone sync gdrive:Tarcisius/"$subdir" "$target"/"$subdir"
            echo "Done syncing \"$subdir\"."
          done

          ## Remove duplicate files that only differ per case, because Android
          ## devices do not like that.
          ##
          find "$target" | sort | {
            prev_file=
            prev_file_lower=
            while read -r file; do
              file_lower=$(echo "$file" | tr '[:upper:]' '[:lower:]')
              if [ "$file_lower" = "$prev_file_lower" ]; then
                printf 'Found two files whose names only differs by casing:\n'
                md5sum "$prev_file" "$file"
                printf 'Removing the former arbitrarily.\n\n'
                rm "$prev_file"
              fi
              prev_file=$file
              prev_file_lower=$file_lower
            done
          }
        '';
      })
    ];
  };
}
