Vagrant.configure("2") do |config|
  config.vbguest.installer_options = { allow_kernel_upgrade: true }
  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
    vb.customize ["modifyvm", :id, "--uartmode1", "file", File::NULL]
  end

  config.vm.define "noble" do |focal|
    focal.vm.box = "bento/ubuntu-24.04"
    focal.ssh.insert_key = true
    focal.vm.hostname = "focal"
    focal.vm.boot_timeout = 600
   end

  config.vm.define "alma" do |alma|
    alma.vm.box = "almalinux/9"
    alma.ssh.insert_key = true
    alma.vm.hostname = "alma"
    alma.vm.boot_timeout = 600
  end
end
