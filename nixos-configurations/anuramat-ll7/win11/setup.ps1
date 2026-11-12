# first logon, run by autounattend.xml from the unattend cdrom; ends with a
# shutdown, which tells win11-install that the guest is ready. FirstLogonCommands
# only run once, so a startup task reruns this after any reboot or crash on the
# way, and each step is skipped once it's done
$d = $PSScriptRoot
$action = New-ScheduledTaskAction powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
Register-ScheduledTask win11-setup -Action $action -Trigger (New-ScheduledTaskTrigger -AtStartup) -User SYSTEM -RunLevel Highest -Force | Out-Null

# guest drivers and the qemu guest agent, from the virtio-win cdrom
if (!(Get-Service QEMU-GA -EA 0)) {
  $tools = Get-PSDrive -PSProvider FileSystem |
    % { Join-Path $_.Root virtio-win-guest-tools.exe } | ? { Test-Path $_ } | select -First 1
  Start-Process -Wait $tools '/install /quiet /norestart'
}

# looking glass host, with the IVSHMEM driver
if (!(Get-Service 'Looking Glass (host)' -EA 0)) {
  Start-Process -Wait "$d\looking-glass-host-setup.exe" /S
}

if (!(Test-Path C:\Windows\System32\nvidia-smi.exe)) {
  Start-Process -Wait "$d\nvidia.exe" '-s -noreboot'
}

# virtual monitor on the 4070 for looking glass to capture: a root device for
# the driver to bind to, and trust in its publisher, which a GUI install would
# ask for; the driver reads its settings from C:\VirtualDisplayDriver
if (!(Get-PnpDevice | ? HardwareID -contains Root\MttVDD)) {
  New-Item -ItemType Directory -Force C:\VirtualDisplayDriver | Out-Null
  Copy-Item "$d\vdd\vdd_settings.xml" C:\VirtualDisplayDriver
  & "$d\nefconc.exe" --create-device-node --hardware-id Root\MttVDD --class-name Display --class-guid 4d36e968-e325-11ce-bfc1-08002be10318
  $store = [Security.Cryptography.X509Certificates.X509Store]::new('TrustedPublisher', 'LocalMachine')
  $store.Open('ReadWrite')
  $store.Add((Get-AuthenticodeSignature "$d\vdd\mttvdd.cat").SignerCertificate)
  $store.Close()
  pnputil /add-driver "$d\vdd\MttVDD.inf" /install
}

# looking glass shows black when the guest sleeps or blanks the screen
powercfg /change standby-timeout-ac 0
powercfg /change monitor-timeout-ac 0

Unregister-ScheduledTask win11-setup -Confirm:$false
shutdown /s /t 10
