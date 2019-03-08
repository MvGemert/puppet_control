# rubocop: disable Metrics/LineLength
# rubocop: disable Metrics/BlockLength
require 'yaml'

unless Vagrant.has_plugin?("vagrant-triggers")
  raise 'vagrant-triggers is not installed, please run: vagrant plugin install vagrant-triggers'
end
unless Vagrant.has_plugin?("vagrant-disksize")
  raise 'vagrant-disksize is not installed, please run: vagrant plugin install vagrant-disksize'
end

#
# This routine will read a ~/.software.yaml fileand make links to all the software defined.
#
def link_software
  # Read YAML file with box details
  software_file = File.expand_path('~/.software.yaml')
  if File.exist?(software_file)
    software_definition = YAML.load_file(software_file)
    software_locations = software_definition.fetch('software_locations') do
      raise "#{software_file} should contain key 'software_locations'"
    end
    raise "software_locations key in #{software_file} sshould contain array" unless software_locations.is_a?(Array)
  else
    software_locations = []
  end
  software_locations.unshift('./software') # Do local stuff first
  software_locations.each { |dir| link_sync(dir, './modules/software/files') }
end

def link_sync(dir, target)
  Dir.glob("#{dir}/*").each do |file|
    file_name = File.basename(file)
    if File.directory?(file)
      FileUtils.mkdir("#{target}/#{file_name}") unless File.exist?("#{target}/#{file_name}")
      link_sync(file, "#{target}/#{file_name}")
      next
    end
    full_target = "#{target}/#{file_name}"
    next if File.exist?(full_target)
    puts "Linking file #{file} to #{full_target}..."
    FileUtils.ln(file, full_target)
  end
end

VAGRANTFILE_API_VERSION = '2'.freeze

# Read YAML file with box details
servers = YAML.load_file('servers.yaml')
pe_puppet_user_id  = 495
pe_puppet_group_id = 496
#
# Choose your version of Puppet Enterprise
#
puppet_installer   = 'puppet-enterprise-2017.2.3-el-7-x86_64/puppet-enterprise-installer'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  link_software

  # Settings to enable private key authentication forwarding to host
  #config.ssh.private_key_path = "~/.ssh/id_rsa"
  config.ssh.insert_key = false
  config.ssh.forward_agent = true
  # End of settings for remote private key forwarding

  config.ssh.insert_key = false
  servers.each do |name, server|
    config.vm.define name do |srv|
      # Settings to enable private key authentication forwarding to host
      config.vm.provision :shell do |shell|
	shell.inline = "touch $1 && chmod 0440 $1 && echo $2 > $1"
        shell.args = %q{/etc/sudoers.d/ssh-auth-sock "Defaults env_keep += \"SSH_AUTH_SOCK\""}
      end
      # End of settings for remote private key forwarding

      # extend vm timeout to 10 minutes
      config.vm.boot_timeout = 600

      srv.vm.box = ENV['BASE_IMAGE'] ? (ENV['BASE_IMAGE']).to_s : server['box']
      hostname = name.split('-').drop(1).join('-')# First part contains type of node
      srv.vm.hostname = "#{hostname}.example.com"
      srv.vm.network 'private_network', ip: server['public_ip']
      srv.vm.network 'private_network', ip: server['private_ip'], virtualbox__intnet: true
      srv.vm.synced_folder '.', '/vagrant', type: :virtualbox
      case server['type']
      when 'masterless'
        srv.vm.box = 'enterprisemodules/centos-7.3-x86_64-nocm' unless server['box']
        config.vm.network 'forwarded_port', guest: 22, host: server['forwarded_ssh_port']

        config.trigger.after :up do
          #
          # Fix hostnames because Vagrant mixes it up.
          #
          run_remote <<-EOD
cat > /etc/hosts<< "EOF"
127.0.0.1 localhost.localdomain localhost4 localhost4.localdomain4
192.168.253.10 master.example.com puppet master
172.17.1.23 ad.vs.ccloud.vs.lan
172.17.1.10 mgt.mgt.ccloud.vs.lan mgt
192.168.253.31 ldap.example.com ldap

#{server['public_ip']} #{hostname}.example.com #{hostname}
EOF
EOD
#          run_remote  "bash /vagrant/scripts/create_seconddisk.sh"
#          run_remote  "bash /vagrant/scripts/create_seconddisk_mounts.sh"
          run_remote  "bash /vagrant/scripts/setup_ssh-knownhosts.sh"
          run_remote  "bash /vagrant/scripts/install_puppet.sh"
          run_remote  "bash /vagrant/scripts/setup_puppet.sh"
          run_remote  "puppet apply /etc/puppetlabs/code/environments/production/manifests/site.pp || true"
        end
        config.trigger.after :provision do
          run_remote  "puppet apply /etc/puppetlabs/code/environments/production/manifests/site.pp || true"
        end

      when 'pe-master'
        srv.vm.box = 'enterprisemodules/centos-7.3-x86_64-nocm' unless server['box']
        srv.vm.synced_folder '.', '/vagrant', owner: pe_puppet_user_id, group: pe_puppet_group_id
        srv.vm.provision :shell, inline: "/vagrant/modules/software/files/#{puppet_installer} -c /vagrant/pe.conf -y"
        config.vm.network 'forwarded_port', guest: 22, host: server['forwarded_ssh_port']
        #
        # For this vagrant setup, we make sure all nodes in the domain examples.com are autosigned. In production
        # you'dd want to explicitly confirm every node.
        #
        srv.vm.provision :shell, inline: "echo '*.example.com' > /etc/puppetlabs/puppet/autosign.conf"
        #
        # For now we stop the firewall. In the future we will add a nice puppet setup to the ports needed
        # for Puppet Enterprise to work correctly.
        #
        srv.vm.provision :shell, inline: 'systemctl stop firewalld.service'
        srv.vm.provision :shell, inline: 'systemctl disable firewalld.service'
        #
        # This script make's sure the vagrant paths's are symlinked to the places Puppet Enterprise looks for specific
        # modules, manifests and hiera data. This makes it easy to change these files on your host operating system.
        #
        srv.vm.provision :shell, path: 'scripts/setup_puppet.sh'
        #
        # Make sure all plugins are synced to the puppetserver before exiting and stating
        # any agents
        #
        srv.vm.provision :shell, inline: 'service pe-puppetserver restart'
        srv.vm.provision :shell, inline: 'puppet agent -t || true'
      when 'pe-agent'
        srv.vm.box = 'enterprisemodules/centos-7.3-x86_64-nocm' unless server['box']
        #
        # First we need to instal the agent.
        #
        config.trigger.after :up do
          #
          # Fix hostnames because Vagrant mixes it up.
          #
          run_remote <<-EOD
cat > /etc/hosts<< "EOF"
127.0.0.1 localhost.localdomain localhost4 localhost4.localdomain4
192.168.253.10 master.example.com puppet master
#{server['public_ip']} #{hostname}.example.com #{hostname}
EOF
EOD
          run_remote 'curl -k https://master.example.com:8140/packages/current/install.bash | sudo bash'
          #
          # The agent installation also automatically start's it. In production, this is what you want. For now we
          # want the first run to be interactive, so we see the output. Therefore, we stop the agent and wait
          # for it to be stopped before we start the interactive run
          #
          run_remote 'pkill -9 -f "puppet.*agent.*"'
          run_remote 'puppet agent -t; exit 0'
          #
          # After the interactive run is done, we restart the agent in a normal way.
          #
          run_remote 'systemctl start puppet'
        end
      end

      # setup the virtual box stuff

      # second disk to mount
#      mySecondDisk="./\.vagrant/machines/#{name}/secondDisk.vdi"
      #myCurrentDir = File.basename(Dir.getwd)

      config.vm.provider :virtualbox do |vb|
        # vb.gui = true
        vb.cpus = server['cpucount'] || 1
        vb.memory = server['ram'] || 4096
        vb.customize ['modifyvm', :id, '--ioapic', 'on']
        vb.customize ['modifyvm', :id, '--name', name]

#        unless File.exist?(mySecondDisk)
#	        vb.customize ['createhd', '--filename', mySecondDisk, '--format', 'VDI', '--variant', 'Standard', '--size', 20 * 1024]
#        end
#        vb.customize ['storageattach', :id,  '--storagectl', 'IDE Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', mySecondDisk]
#        if server['virtualboxorafix'] == 'enable'
#          vb.customize ['setextradata', :id, 'VBoxInternal/CPUM/HostCPUID/Cache/Leaf', '0x4']
#          vb.customize ['setextradata', :id, 'VBoxInternal/CPUM/HostCPUID/Cache/SubLeaf', '0x4']
#          vb.customize ['setextradata', :id, 'VBoxInternal/CPUM/HostCPUID/Cache/eax', '0']
#          vb.customize ['setextradata', :id, 'VBoxInternal/CPUM/HostCPUID/Cache/ebx', '0']
#          vb.customize ['setextradata', :id, 'VBoxInternal/CPUM/HostCPUID/Cache/ecx', '0']
#          vb.customize ['setextradata', :id, 'VBoxInternal/CPUM/HostCPUID/Cache/edx', '0']
#          vb.customize ['setextradata', :id, 'VBoxInternal/CPUM/HostCPUID/Cache/SubLeafMask', '0xffffffff']
#        end
      end
    end
  end
end