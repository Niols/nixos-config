{
  ## Garbage-collect automatically everything that is at least a month old. Do
  ## not garbage-collect results of `direnv` or `nix build` as long as there
  ## is a link.
  ##
  settings.keep-outputs = true;
  settings.keep-derivations = true;
}
