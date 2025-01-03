{
  sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFPgKxqnXU0UAshEUDLcVZW6LkfMM0JE2yuhkyjXSxUI anuramat-t480";
  hostKeys = builtins.readFile ./hostkeys;
  system = "x86_64-linux";
}
