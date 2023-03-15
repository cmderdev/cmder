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
git checkout vagrant
git pull origin vagrant
git remote add upstream  https://github.com/cmderdev/cmder
git pull upstream master

# cmd.exe "/K" '"C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Auxiliary/Build/vcvars64.bat" && powershell -command "& ''$env:userprofile/cmderdev/scripts/build.ps1'' -verbose -compile" && exit'
# copy $env:userprofile/cmderdev/launcher/x64/release/cmder.exe $env:userprofile/cmderdev
# cmd.exe "/K" '"C:/Program Files (x86)/Microsoft Visual Studio/2022/Community/VC/Auxiliary/Build/vcvars64.bat" && powershell -noexit -command "& ''build.ps1 -verbose -compile''"'

cd scripts
./build.ps1 -verbose

copy C:/Tools/Cmder/Cmder.exe $env:userprofile/cmderdev

$env:cmder_root = "C:/tools/cmder"
write-host "Creating '${env:USERPROFILE}/Desktop/Cmder.lnk'..."
start-process -NoNewWindow -filePath "$env:userprofile/bin/set-shortcut.ps1" -ArgumentList "-sourceexe `"$env:cmder_root\\Cmder.exe`" -DestinationPath `"${env:USERPROFILE}\\Desktop\\Cmder.lnk`" -WorkingDirectory `"${env:USERPROFILE}`""

$env:cmder_root = "${env:USERPROFILE}\\cmderdev"
write-host "Creating '${env:USERPROFILE}\\Desktop\\Cmderdev.lnk'..."
start-process -NoNewWindow -filePath "$env:userprofile\\bin\\set-shortcut.ps1" -ArgumentList "-sourceexe `"${env:cmder_root}\\Cmder.exe`" -DestinationPath `"${env:USERPROFILE}\\Desktop\\Cmderdev.lnk`" -WorkingDirectory `"${env:cmder_root}`""

# tabby
setx cmder_root "$env:cmder_root"

# C:\Users\vagrant\AppData\Roaming\Hyper
#         // shell: '',
#         shell: 'cmd.exe',
#         // for setting shell arguments (i.e. for using interactive shellArgs: `['-i']`)
#         // by default `['--login']` will be used
#         // shellArgs: ['--login'],
#         shellArgs: ['/k', 'C:\\users\\vagrant\\cmderdev\\vendor\\init.bat'],


