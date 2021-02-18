Vagrant.configure("2") do |config|
  config.vbguest.installer_options = { allow_kernel_upgrade: true }
  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
    vb.customize ["modifyvm", :id, "--uartmode1", "file", File::NULL]
  end

  config.vm.define "focal" do |focal|
    focal.vm.box = "bento/ubuntu-20.04"
    focal.ssh.insert_key = true
    focal.vm.network "private_network", ip: "10.2.3.47"
    focal.vm.hostname = "focal"
    focal.vm.boot_timeout = 600
    focal.vm.provision "shell",
      inline: "apt-get update && apt-get -y install ansible"
    focal.vm.provision "ansible" do |a|
      a.verbose = "v"
      a.limit = "all"
      a.playbook = "tests/test.yml"
     end
   end
end
