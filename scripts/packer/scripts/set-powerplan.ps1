Try {
  Write-Output "Set power plan to high performance"

  $HighPerf = powercfg -l | ForEach-Object { if ($_.contains("High performance")) { $_.split()[3] } }

  # $HighPerf cannot be $null, we try activate this power profile with powercfg
  if ($null -eq $HighPerf) {
    throw "Error: HighPerf is null"
  }

  $CurrPlan = $(powercfg -getactivescheme).split()[3]

  if ($CurrPlan -ne $HighPerf) { powercfg -setactive $HighPerf }

}
Catch {
  Write-Warning -Message "Unable to set power plan to high performance"
  Write-Warning $Error[0]
}
