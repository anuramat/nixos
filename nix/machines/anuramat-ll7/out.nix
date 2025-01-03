{
  builder = true;
  cacheKey = "anuramat-ll7:aFFmygZTV872vjBs+mugpBgkTObki/bi5xfJspLKeSc=";
  sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIORDkTNsAaKxMF/VIfoI+FXvcLARbswddfqtHNkuTsxR anuramat-ll7";
  hostKeys = builtins.readFile ./hostkeys;
  system = "x86_64-linux";
}
