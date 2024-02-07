$DefenderInstalled = Get-Command -Module Defender
if($null -ne $DefenderInstalled) {
    Set-MpPreference -DisableRealtimeMonitoring $true
}
