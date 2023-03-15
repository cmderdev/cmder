# $script_cmder = <<-SCRIPT
# choco install -y --force 7zip 7zip.install
# choco install -y --force cmder
# SCRIPT
# 
# $script_cmderdev = <<-SCRIPT
# $env:path = "$env:path;c:/tools/cmder/vendor/git-for-windows/cmd"
# c:
# cd /Users/Vagrant
# git clone https://github.com/cmderdev/cmder cmderdev
# TAKEOWN /F c:/Users/vagrant/cmderdev /R /D y /s localhost /u vagrant /p vagrant
# cd cmderdev
# git remote add upstream  https://github.com/cmderdev/cmder
# git pull upstream master
# 
# # cmd.exe "/K" '"C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Auxiliary/Build/vcvars64.bat" && powershell -command "& ''c:/Users/Vagrant/cmderdev/scripts/build.ps1'' -verbose -compile" && exit'
# # copy c:/Users/Vagrant/cmderdev/launcher/x64/release/cmder.exe c:/Users/Vagrant/cmderdev
# # cmd.exe "/K" '"C:/Program Files (x86)/Microsoft Visual Studio/2022/Community/VC/Auxiliary/Build/vcvars64.bat" && powershell -noexit -command "& ''build.ps1 -verbose -compile''"'
# 
# cd scripts
# ./build.ps1 -verbose
# 
# copy C:/Tools/Cmder/Cmder.exe C:/Users/Vagrant/cmderdev
# 
# # tabby
# setx cmder_root '%userprofile%/cmderdev'
# 
# # VSCode
# $VSCodeUserSettings = "$env:APPDATA/Code/User"
# $VSCodeSettings = "$VSCodeUserSettings/settings.json";
# $VSCodeSettingsNew = $VSCodeSettings.replace('.json', '-new.json')
# 
# if (test-path $VSCodeSettings) {
#     $data = get-content -path $VSCodeSettings -ErrorAction silentlycontinue | out-string | ConvertFrom-Json
# }
# else {
#     New-Item -ItemType directory $VSCodeUserSettings -force
#     $data = @{}
# }
# 
# write-host $data
# 
# $data | Add-Member -force -Name 'terminal.integrated.defaultProfile.windows' -MemberType NoteProperty -Value "Cmder"
# 
# if ($null -eq $data.'terminal.integrated.profiles.windows') {
#   write-host "Adding 'terminal.integrated.profiles.windows'..."
#   $data | Add-Member -force -Name 'terminal.integrated.profiles.windows' -MemberType NoteProperty -Value @{}
# } 
# 
# write-host "Adding 'terminal.integrated.profiles.windows.Cmder' profile..."
# $data.'terminal.integrated.profiles.windows'.'Cmder' = @{
#   "name" = "Cmder";
#   "path" = @(
#     "`${env:windir}/Sysnative/cmd.exe";
#     "`${env:windir}/System32/cmd.exe";
#   );
#   "args" = @(
#     "/k";
#     "`${env:USERPROFILE}/cmderdev/vendor/bin/vscode_init.cmd");
#   "icon" = "terminal-cmd";
#   "color" = "terminal.ansiGreen";
# };
# 
# $data | ConvertTo-Json -depth 100 | set-content $VSCodeSettings
# 
# # Windows Terminal
# start-process wt.exe
# sleep 5
# kill (get-process windowsterminal).id
# $windowsTerminalFolder = (dir "C:/Users/vagrant/AppData/Local/Packages/Microsoft.WindowsTerminal_*").name
# $windowsTerminalPath = 'C:/Users/vagrant/AppData/Local/Packages/' + $windowsTerminalFolder
# $windowsTerminalSettings = $windowsTerminalPath + '/localState/settings.json'
# $windowsTerminalSettingsNew = $windowsTerminalPath + '/localState/settings-new.json'
# $json = get-content $windowsTerminalSettings | ConvertFrom-Json
# $json.defaultProfile="{00000000-0000-0000-ba54-000000000132}"
# 
# $cmderFound = $false
# $cmderAsAdminFound = $false
# 
# foreach ($profile in $json.profiles.list) {
#   if ($profile.Name -eq "Cmder") {
#     $cmderFound = $true
#   }
#   elseIf ($profile.Name -eq "Cmder as Admin") {
#     $cmderAsAdminFound = $true
#   }
# }
# 
# if (-not $cmderFound) {
#   write-host "Adding 'Cmder' to Windows Terminal..."
# 
#   $json.profiles.list += @{
#     commandline="cmd.exe /k `"%USERPROFILE%/cmderdev/vendor/init.bat`"";
#     startingDirectory="%USERPROFILE%/cmderdev";
#     icon="%USERPROFILE%/cmderdev/icons/cmder.ico";
#     closeOnExit="graceful";
#     guid="{00000000-0000-0000-ba54-000000000132}";
#     hidden=$false;
#     name="Cmder"
#   }
# }
# 
# if (-not $cmderAsAdminFound) {
#   write-host "Adding 'Cmder as Admin' to Windows Terminal..."
# 
#   $json.profiles.list += @{
#     commandline="cmd.exe /k `"%USERPROFILE%/cmderdev/vendor/init.bat`"";
#     startingDirectory="%USERPROFILE%/cmderdev";
#     icon="%USERPROFILE%/cmderdev/icons/cmder_red.ico";
#     closeOnExit="graceful";
#     guid="{00000000-0000-0000-ba54-000000000133}";
#     hidden=$false;
#     elevate=$true;
#     name="Cmder as Admin"
#   }
# }
# 
# $json | ConvertTo-Json -depth 100 | set-content $windowsTerminalSettings
# 
# # C:\Users\vagrant\AppData\Roaming\Hyper
# #         // shell: '',
# #         shell: 'cmd.exe',
# #         // for setting shell arguments (i.e. for using interactive shellArgs: `['-i']`)
# #         // by default `['--login']` will be used
# #         // shellArgs: ['--login'],
# #         shellArgs: ['/k', 'C:\\users\\vagrant\\cmderdev\\vendor\\init.bat'],
# 
# C:/Users/Vagrant/bin/set-shortcut.ps1 -SourceExe "C:\\tools\\Cmder\\Cmder.exe" -DestinationPath "C:\\Users\\vagrant\\Desktop\\Cmder.lnk" -WorkingDirectory C:\\tools\\Cmder
# C:/Users/vagrant/bin/set-shortcut.ps1 -SourceExe "C:\\Users\\vagrant\\cmderdev\\Cmder.exe" -DestinationPath "C:\\Users\\vagrant\\Desktop\\Cmderdev.lnk" -WorkingDirectory C:\\Users\\vagrant\\cmderdev
# 
# SCRIPT

Vagrant.configure("2") do |config|
  required_plugins = %w( vagrant-vbguest )
  required_plugins.each do |plugin|
    system "vagrant plugin install #{plugin}" unless Vagrant.has_plugin? plugin
  end

  # config.vbguest.iso_path = "../../../../usr/share/virtualbox/VBoxGuestAdditions.iso"
  config.vbguest.allow_downgrade = true

  config.vm.define "cmderdev-10" do |win10|
    win10.vm.hostname = "cmderdev-10"
    win10.vm.box = "cmderdev-10"

    # win10.vm.network :private_network, ip: "192.168.56.101"

    win10.vm.provider :virtualbox do |v|
      # v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.customize ["modifyvm", :id, "--name", "cmderdev-10"]
      v.customize ["modifyvm", :id, "--ostype", "Windows10_64"]
      v.customize ["modifyvm", :id, "--graphicscontroller", "vboxsvga"]
      v.customize ["modifyvm", :id, "--memory", 8192]
      v.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      #v.customize ["setextradata", :id, "GUI/ScaleFactor", "1.75"]
    end
  end

  config.vm.define "cmderdev-11" do |win11|
    win11.vm.hostname = "cmderdev-11"
    win11.vm.box = "cmderdev-11"

    # win11.vm.network :private_network, ip: "192.168.56.111"

    win11.vm.provider :virtualbox do |v|
      # v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.customize ["modifyvm", :id, "--name", "cmderdev-11"]
      v.customize ["modifyvm", :id, "--ostype", "Windows11_64"]
      v.customize ["modifyvm", :id, "--graphicscontroller", "vboxvga"]
      v.customize ["modifyvm", :id, "--memory", 8192]
      v.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      #v.customize ["setextradata", :id, "GUI/ScaleFactor", "1.75"]
    end
  end

  config.vm.define "cmderdev-10-pro-scaled" do |cmderdev|
    cmderdev.vm.hostname = 'cmderdev-10-pro'
    cmderdev.vm.box = "cmderdev-10"

    cmderdev.vm.provider :virtualbox do |v|
      # v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.customize ["modifyvm", :id, "--name", "cmderdev-pro"]
      v.customize ["modifyvm", :id, "--graphicscontroller", "vboxsvga"]
      v.customize ["modifyvm", :id, "--memory", 8192]
      v.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      v.customize ["setextradata", :id, "GUI/ScaleFactor", "1.75"]
    end
  end

  config.vm.provision "file", source: "./scripts/vagrant/windows_terminal_settings.json.default", destination: "windows_terminal_settings.json.default"
  config.vm.provision "file", source: "./scripts/vagrant/windows_terminal_state.json.default", destination: "windows_terminal_state.json.default"
  config.vm.provision "shell", path: './scripts/vagrant/add-cmder.ps1'
  config.vm.provision "shell", path: './vendor/bin/add-vscodeprofile.ps1'
  config.vm.provision "shell", path: './vendor/bin/add-windowsterminalprofiles.ps1'
end
