# TODO simplify this hsit
{ lib, ... }:
with lib;
with builtins;
let
  readLines = v: v |> readFile |> splitString "\n" |> filter (x: x != "");
  getSchema = attrsets.mapAttrsRecursive (path: v: typeOf (v));
  getMatches =
    patterns: x:
    mapAttrs (
      name: schema: if typeOf x == "set" then schema == getSchema x else schema == typeOf x
    ) patterns;
in
{
  mimeFromDesktop =
    package:
    let
      desktopFiles =
        package:
        let
          dir = (package.outPath + "/share/applications");
        in
        dir
        |> readDir
        |> filterAttrs (n: v: strings.hasSuffix ".desktop" n)
        |> attrNames
        |> map (v: dir + "/" + v);
      lineToMimes =
        line: line |> strings.removePrefix "MimeType=" |> splitString ";" |> filter (v: v != "");
    in
    package
    |> desktopFiles
    |> map readLines
    |> concatLists
    |> filter (v: strings.hasPrefix "MimeType" v)
    |> map lineToMimes
    |> concatLists
    |> unique;

  # one app, many types
  setMany =
    app: types:
    types
    |> map (v: {
      name = v;
      value = app;
    })
    |> listToAttrs;

  # thingie to actual mime type list
  generateMimeTypes =
    let
      # schema for mime types thingie
      mimePatterns = {
        parts = {
          prefix = "string";
          suffixes = "list";
        };
        exact = "string";
        exactList = "list";
        file = "path";
      };
    in
    thingies:
    thingies
    |> map (
      v:
      let
        matches = getMatches mimePatterns v;
      in
      if matches.parts then
        map (suffix: "${v.prefix}/${suffix}") v.suffixes
      else if matches.exact then
        [ v ]
      else if matches.exactList then
        v
      else if matches.file then
        v |> readLines
      else
        throw "illegal pattern: ${toJSON v}"
    )
    |> concatLists;
}
