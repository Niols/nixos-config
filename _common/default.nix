## NOTE: Depending on the type of machine, we might not want to include exactly
## the same modules.

let
  inherit (builtins) readDir attrNames map;
  allFilesFrom = dir: map (fname: dir + "/${fname}") (attrNames (readDir dir));
in
{
  server.imports = allFilesFrom ./both ++ allFilesFrom ./server;
  laptop.imports = allFilesFrom ./both ++ allFilesFrom ./laptop;
}
