# VSCode
$VSCodeUserSettings = "$env:APPDATA/Code/User"
$VSCodeSettings = "$VSCodeUserSettings/settings.json";
$VSCodeSettingsNew = $VSCodeSettings.replace('.json', '-new.json')

if (test-path $VSCodeSettings) {
    $data = get-content -path $VSCodeSettings -ErrorAction silentlycontinue | out-string | ConvertFrom-Json
}
else {
    New-Item -ItemType directory $VSCodeUserSettings -force
    $data = @{}
}

write-host $data

$data | Add-Member -force -Name 'terminal.integrated.defaultProfile.windows' -MemberType NoteProperty -Value "Cmder"

if ($null -eq $data.'terminal.integrated.profiles.windows') {
  write-host "Adding 'terminal.integrated.profiles.windows'..."
  $data | Add-Member -force -Name 'terminal.integrated.profiles.windows' -MemberType NoteProperty -Value @{}
} 

write-host "Adding 'terminal.integrated.profiles.windows.Cmder' profile..."
$data.'terminal.integrated.profiles.windows'.'Cmder' = @{
  "name" = "Cmder";
  "path" = @(
    "`${env:windir}/Sysnative/cmd.exe";
    "`${env:windir}/System32/cmd.exe";
  );
  "args" = @(
    "/k";
    "`${env:USERPROFILE}/cmderdev/vendor/bin/vscode_init.cmd");
  "icon" = "terminal-cmd";
  "color" = "terminal.ansiGreen";
};

$data | ConvertTo-Json -depth 100 | set-content $VSCodeSettings


