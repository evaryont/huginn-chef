# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.omnibus.chef_version = "11.16.0"

  config.vm.provider "virtualbox" do |vb|
     vb.customize ["modifyvm", :id, "--memory", "1024"]
  end

  config.vm.provision "chef_solo" do |chef|
    chef.cookbooks_path = "site-cookbooks/"
    chef.roles_path = "roles"
    chef.data_bags_path = "data_bags"
    chef.add_role "huginn_production"
    # You may also specify custom JSON attributes:
    #chef.json = { mysql_password: "foo" }
  end

  config.vm.define "ubuntu14", primary: true do |ubu|
    ubu.vm.box = "ubuntu/trusty64"
  end

  config.vm.define "ubuntu12" do |ubu|
    ubu.vm.box = "hashicorp/precise64"
  end

  config.vm.define "centos6" do |cent|
    cent.vm.box = "hfm4/centos6"
  end

  config.vm.define "centos7" do |cent|
    cent.vm.box = "hfm4/centos7"
  end
end
