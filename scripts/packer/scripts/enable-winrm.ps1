write-host "==> 'enable-winrm.ps1' - START..."
write-host "====> Getting Connections..."
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private

write-host "====> Enable PSRemoting..."
Enable-PSRemoting -Force

write-host "====> WINRM Quick Config..."
winrm quickconfig -q
winrm quickconfig -transport:http

write-host "====> WINRM Set Config..."
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="800"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/client/auth '@{Basic="true"}'
winrm set winrm/config/listener?Address=*+Transport=HTTP '@{Port="5985"}'

write-host "====> Configure Firewall..."
netsh advfirewall firewall set rule group="Windows Remote Administration" new enable=yes
netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new enable=yes action=allow remoteip=any
write-host "====> Set WINRM Service Statup..."
Set-Service winrm -startuptype "auto"
write-host "====> Restart WINRM Service..."
Restart-Service winrm
write-host "==> 'enable-winrm.ps1' - END..."
