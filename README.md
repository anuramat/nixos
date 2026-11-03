# anuramat/nixos

![TODO](https://img.shields.io/github/search?query=repo%3Aanuramat%2Fnixos%20TODO&style=flat-square&logo=nixos&color=blue&labelColor=black&label=TODO&link=&link=https%3A%2F%2Fgithub.com%2Fsearch%3Fq%3Drepo%253Aanuramat%252Fnixos%2520TODO%26type%3Dcode)
![BUG](https://img.shields.io/github/search?query=repo%3Aanuramat%2Fnixos%20BUG&style=flat-square&logo=gnubash&color=purple&labelColor=black&label=BUG&link=&link=https%3A%2F%2Fgithub.com%2Fsearch%3Fq%3Drepo%253Aanuramat%252Fnixos%2520BUG%26type%3Dcode)
![FUCK](https://img.shields.io/github/search?query=repo%3Aanuramat%2Fnixos%20FUCK&style=flat-square&logo=cplusplus&color=red&labelColor=black&label=FUCK&link=&link=https%3A%2F%2Fgithub.com%2Fsearch%3Fq%3Drepo%253Aanuramat%252Fnixos%2520FUCK%26type%3Dcode)

## Install

See [docs/install.md](docs/install.md).

## Problems

- sshKey and sshUser in nix.buildMachines are ignored: <https://github.com/NixOS/nix/issues/3423>;
  for now add this to /root/.ssh/config, for each `builder = true` host in `hosts` (`outputs.nix`):
  ```ssh_config
  Host anuramat-bgm5
          IdentitiesOnly yes
          IdentityFile /home/anuramat/.ssh/id_ed25519
          User builder
          ConnectTimeout 3
  ```
