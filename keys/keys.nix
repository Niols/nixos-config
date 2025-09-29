let
  inherit (builtins)
    attrNames
    elemAt
    filter
    match
    readDir
    readFile
    stringLength
    substring
    listToAttrs
    ;

  hasSuffix =
    suffix: content:
    let
      lenContent = stringLength content;
      lenSuffix = stringLength suffix;
    in
    lenContent >= lenSuffix && substring (lenContent - lenSuffix) lenContent content == suffix;

  removeSuffix = suffix: str: substring 0 (stringLength str - stringLength suffix) str;
  removeTrailingWhitespace = s: elemAt (match "(.*[^[:space:]])[[:space:]]*" s) 0;

  ## Recursively collect all `.pub` files in the given directory, reproducing
  ## the directory tree with records. For instance, if applied to:
  ##
  ##      .
  ##     ├──  flake-part.nix
  ##     ├── 󰌆 github-actions.pub
  ##     ├──  keys.nix
  ##     ├──  machines
  ##     │   ├── 󰌆 ahlaya.pub
  ##     │   ├── 󰌆 dagrun.pub
  ##     ├──  niols
  ##     │   ├── 󰌆 default.pub
  ##     └── 󰌆 secrets-backup.pub
  ##
  ## it will return
  ##
  ##     {
  ##       github-actions = "<content>";
  ##       machines = {
  ##         ahlaya = "<content>";
  ##         dagrun = "<content>";
  ##       };
  ##       niols = {
  ##         default = "<content>";
  ##       };
  ##       secrets-backup = "<content>";
  ##     }
  ##
  ## It could be written in a simple way, but we only allow ourselves to use
  ## built-in functions, such that this file can be imported in Agenix's secrets
  ## file.
  ##
  collectKeys =
    dir:
    let
      content = readDir dir;
    in
    listToAttrs (
      filter (x: x != null) (
        map (
          file:
          let
            filePath = dir + "/${file}";
          in
          if content.${file} == "directory" then
            {
              name = file;
              value = collectKeys filePath;
            }
          else if hasSuffix ".pub" file then
            {
              name = removeSuffix ".pub" file;
              value = removeTrailingWhitespace (readFile filePath);
            }
          else
            null
        ) (attrNames content)
      )
    );
in

collectKeys ./.
