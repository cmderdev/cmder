required_plugins = %w( vagrant-vbguest )
required_plugins.each do |plugin|
  unless Vagrant.has_plugin? plugin
    system "vagrant plugin install #{plugin}"
    p "Run 'vagrant up' again to continue."
    exit 0
  end
end

Vagrant.configure("2") do |config|
  # config.vbguest.iso_path = "../../../../usr/share/virtualbox/VBoxGuestAdditions.iso"
  config.vbguest.allow_downgrade = true

  config.vm.define "cmderdev-10" do |b|
    b.vm.hostname = "cmderdev-10"
    b.vm.box = "dgames/cmderdev-10"
    b.vm.box_version = "1.0.0"

    b.vm.provider :virtualbox do |v|
      # v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.customize ["modifyvm", :id, "--name", "cmderdev-10"]
      v.customize ["modifyvm", :id, "--ostype", "Windows10_64"]
      v.customize ["modifyvm", :id, "--graphicscontroller", "vboxsvga"]
      v.customize ["modifyvm", :id, "--memory", 8192]
      v.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    end
  end

  config.vm.define "cmderdev-10s" do |b|
    b.vm.hostname = 'cmderdev-10'
    b.vm.box = "dgames/cmderdev-10"
    b.vm.box_version = "1.0.0"

    b.vm.provider :virtualbox do |v|
      # v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.customize ["modifyvm", :id, "--name", "cmderdev-10s"]
      v.customize ["modifyvm", :id, "--ostype", "Windows10_64"]
      v.customize ["modifyvm", :id, "--graphicscontroller", "vboxsvga"]
      v.customize ["modifyvm", :id, "--memory", 8192]
      v.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      v.customize ["setextradata", :id, "GUI/ScaleFactor", "1.75"]
    end
  end

  config.vm.define "cmderdev-11" do |b|
    b.vm.box = "dgames/cmderdev-11"
    b.vm.box_version = "1.0.0"

    b.vm.provider :virtualbox do |v|
      # v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.customize ["modifyvm", :id, "--name", "cmderdev-11"]
      v.customize ["modifyvm", :id, "--ostype", "Windows11_64"]
      v.customize ["modifyvm", :id, "--graphicscontroller", "vboxvga"]
      v.customize ["modifyvm", :id, "--memory", 8192]
      v.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    end
  end

  config.vm.provision "file", source: "./scripts/vagrant/windows_terminal_settings.json.default", destination: "windows_terminal_settings.json.default"
  config.vm.provision "file", source: "./scripts/vagrant/windows_terminal_state.json.default", destination: "windows_terminal_state.json.default"
  config.vm.provision "shell", path: './scripts/vagrant/add-cmder.ps1'
  config.vm.provision "shell", path: './vendor/bin/add-vscodeprofile.ps1'
  config.vm.provision "shell", path: './vendor/bin/add-windowsterminalprofiles.ps1'
  config.vm.provision "shell", path: './vendor/bin/add-cmdertodesktop.ps1'
end
