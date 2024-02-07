netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new enable=yes action=block
netsh advfirewall firewall set rule group="Windows Remote Management" new enable=yes
$winrmService = Get-Service -Name WinRM
if ($winrmService.Status -eq "Running") {
  Disable-PSRemoting -Force
}
Stop-Service winrm
Set-Service -Name winrm -StartupType Disabled
