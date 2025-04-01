let
  inherit (builtins)
    attrNames
    attrValues
    elemAt
    filter
    foldl'
    mapAttrs
    match
    readDir
    readFile
    removeAttrs
    stringLength
    substring
    ;

  hasSuffix =
    suffix: content:
    let
      lenContent = stringLength content;
      lenSuffix = stringLength suffix;
    in
    lenContent >= lenSuffix && substring (lenContent - lenSuffix) lenContent content == suffix;

  removeSuffix = suffix: str: substring 0 (stringLength str - stringLength suffix) str;

  filterAttrs = pred: set: removeAttrs set (filter (name: !pred name set.${name}) (attrNames set));

  ## `mergeAttrs` and `concatMapAttrs` are in `lib.trivial` and `lib.attrsets`,
  ## but we would rather avoid a dependency in nixpkgs for this file.
  mergeAttrs = x: y: x // y;
  concatMapAttrs = f: v: foldl' mergeAttrs { } (attrValues (mapAttrs f v));
  removeTrailingWhitespace = s: elemAt (match "(.*[^[:space:]])[[:space:]]*" s) 0;

  collectKeys =
    dir:
    concatMapAttrs (name: _: {
      "${removeSuffix ".pub" name}" = removeTrailingWhitespace (readFile (dir + "/${name}"));
    }) (filterAttrs (name: _: hasSuffix ".pub" name) (readDir dir));
in

{
  machines = collectKeys ./machines;
  niols = collectKeys ./niols;
  github-actions = collectKeys ./github-actions;
}
