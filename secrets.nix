let
  keys = import ./hax/hosts ./hosts;
in
{
  "testSecret.age".publicKeys = keys;
}
