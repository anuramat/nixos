{ lib, common, ... }:
with lib;
with builtins;
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
    |> map common.readLines
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
        matches = common.getMatches mimePatterns v;
      in
      if matches.parts then
        map (suffix: "${v.prefix}/${suffix}") v.suffixes
      else if matches.exact then
        [ v ]
      else if matches.exactList then
        v
      else if matches.file then
        v |> common.readLines
      else
        throw "illegal pattern: ${toJSON v}"
    )
    |> concatLists;
}
