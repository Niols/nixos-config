let
  allFilesFrom = import ../../_utils/allFilesFrom.nix;
in
{
  imports = [ ../../common ] ++ allFilesFrom ./both;
  x_niols.isServer = true;
}
