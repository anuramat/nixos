{ lib, ... }:
let
  inherit (lib) isAttrs isString isList;
in
rec {
  when = cond: val:
    if cond then val
    else if isAttrs val then {}
    else if isString val then ""
    else if isList val then []
    else throw "when: unsupported type";
}