let
  allFilesFrom = import ../../_utils/allFilesFrom.nix;
in
{
  imports = allFilesFrom ./both ++ allFilesFrom ./headless;
}
