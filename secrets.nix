let
  keys = import ./helpers/hosts ./hosts;
in
{
  "testSecret.age".publicKeys = keys;
}
