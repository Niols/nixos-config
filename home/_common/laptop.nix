let
  allFilesFrom = import ../../_utils/allFilesFrom.nix;
in
{
  imports = [ ./laptop ] ++ allFilesFrom ./both;
}
