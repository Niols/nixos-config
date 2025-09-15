## Small utility that receives a path and returns a list of paths of all files
## and directories in the given path.
let
  inherit (builtins) readDir attrNames map;
in
dir: map (fname: dir + "/${fname}") (attrNames (readDir dir))
