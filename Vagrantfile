Vagrant.configure("2") do |config|
  config.vbguest.installer_options = { allow_kernel_upgrade: true }
  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
    vb.customize ["modifyvm", :id, "--uartmode1", "file", File::NULL]
  end

  config.vm.define "focal" do |focal|
    focal.vm.box = "ubuntu/focal64"
    focal.ssh.insert_key = true
    focal.vm.hostname = "focal"
    focal.vm.boot_timeout = 600
   end

  config.vm.define "alma" do |alma|
    alma.vm.box = "almalinux/8"
    alma.ssh.insert_key = true
    alma.vm.hostname = "alma"
    alma.vm.boot_timeout = 600
  end
end
