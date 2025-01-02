{
  username = "anuramat";
  fullname = "Arsen Nuramatov";
  timezone = "Europe/Berlin";
  defaultLocale = "en_US.UTF-8";
  keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFPgKxqnXU0UAshEUDLcVZW6LkfMM0JE2yuhkyjXSxUI anuramat-t480"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKl0YHcx+ju+3rsPerkAXoo2zI4FXRHaxzfq8mNHCiSD anuramat-iphone16"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIORDkTNsAaKxMF/VIfoI+FXvcLARbswddfqtHNkuTsxR anuramat-ll7"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINBre248H/l0+aS5MJ+nr99m10g44y+UsaKTruszS6+D anuramat-ipad"
  ];
  # TODO might need to filter out $hostname from the list?
  # TODO or just refactor everything, move machine specific stuff to machine folders? would kinda make sense
  substituters = [ "http://anuramat-ll7:5000" ];
  trusted-public-keys = [ "anuramat-ll7:aFFmygZTV872vjBs+mugpBgkTObki/bi5xfJspLKeSc=" ];
}
