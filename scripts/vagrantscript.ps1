choco install -y --force 7zip 7zip.install
choco install -y --force cmder

$env:path = "$env:path;c:/tools/cmder/vendor/git-for-windows/cmd"
c:
cd $env:userprofile
git clone https://github.com/cmderdev/cmder cmderdev
write-host "USERNAME: $env:USERNAME"

if ("$env:USERNAME" -eq "vagrant" -and -not (test-path "$env:userprofile/cmderdev/vendor/git-for-windows")) {
  invoke-expression -command "TAKEOWN /F `"$env:userprofile/cmderdev`" /R /D y /s localhost /u vagrant /p vagrant"
}

cd cmderdev
git remote add upstream  https://github.com/cmderdev/cmder
git pull upstream master

# cmd.exe "/K" '"C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Auxiliary/Build/vcvars64.bat" && powershell -command "& ''$env:userprofile/cmderdev/scripts/build.ps1'' -verbose -compile" && exit'
# copy $env:userprofile/cmderdev/launcher/x64/release/cmder.exe $env:userprofile/cmderdev
# cmd.exe "/K" '"C:/Program Files (x86)/Microsoft Visual Studio/2022/Community/VC/Auxiliary/Build/vcvars64.bat" && powershell -noexit -command "& ''build.ps1 -verbose -compile''"'

cd scripts
./build.ps1 -verbose

copy C:/Tools/Cmder/Cmder.exe $env:userprofile/cmderdev

write-host "Creating '${env:USERPROFILE}/Desktop/Cmder.lnk'..."
start-process -filePath "$env:userprofile/bin/set-shortcut.ps1" -ArgumentList "-sourceexe `"C:\\tools\\Cmder\\Cmder.exe`" -DestinationPath `"C:\\Users\\vagrant\\Desktop\\Cmder.lnk`" -WorkingDirectory `"C:\\tools\\Cmder`""

write-host "Creating '${env:USERPROFILE}/Desktop/Cmderdev.lnk'..."
start-process -filePath "$env:userprofile/bin/set-shortcut.ps1" -ArgumentList "-sourceexe `"${env:USERPROFILE}\\cmderdev\\Cmder.exe`" -DestinationPath `"${env:USERPROFILE}\\Desktop\\Cmderdev.lnk`" -WorkingDirectory `"${env:USERPROFILE}\\cmderdev`""

# tabby
setx cmder_root '%userprofile%/cmderdev'

# C:\Users\vagrant\AppData\Roaming\Hyper
#         // shell: '',
#         shell: 'cmd.exe',
#         // for setting shell arguments (i.e. for using interactive shellArgs: `['-i']`)
#         // by default `['--login']` will be used
#         // shellArgs: ['--login'],
#         shellArgs: ['/k', 'C:\\users\\vagrant\\cmderdev\\vendor\\init.bat'],


