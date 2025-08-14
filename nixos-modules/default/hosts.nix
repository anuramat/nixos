# TODO move
{
  hax,
  config,
  inputs,
  lib,
  ...
}:
{
  lib.hosts =
    let
      name = config.networking.hostName;
      h = hax.hosts;
      inherit (lib) filterAttrs attrNames;

      hosts = h.mkOthers inputs name;
      names = attrNames hosts;
      builderNames = attrNames builders;
      builders = filterAttrs (n: v: v.builder) hosts;
    in
    {
      substituters = h.mkSubstituters builderNames; # binary cache
      keyFiles = h.mkKeyFiles names; # ssh public keys
      knownHostsFiles = h.mkKnownHostsFiles names; # agenix(?)/ssh host auth
      trusted-public-keys = map h.mkCacheKey builderNames; # packages signature
      inherit hosts builders;
    };
}
