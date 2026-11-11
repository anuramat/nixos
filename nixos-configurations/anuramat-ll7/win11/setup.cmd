@echo off
rem first logon: guest drivers and agent, looking glass host (with the IVSHMEM
rem driver), no sleep or screen blanking (looking glass would show black)
for %%d in (D E F G H) do if exist %%d:\virtio-win-guest-tools.exe start /wait %%d:\virtio-win-guest-tools.exe /install /quiet /norestart
start /wait %~dp0looking-glass-host-setup.exe /S
powercfg /change standby-timeout-ac 0
powercfg /change monitor-timeout-ac 0
shutdown /r /t 10
