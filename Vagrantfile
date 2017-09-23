# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure('2') do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = 'ubuntu/xenial64'

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  config.vm.network 'forwarded_port', guest: 7474, host: 7474, host_ip: '127.0.0.1'
  config.vm.network 'forwarded_port', guest: 7473, host: 7473, host_ip: '127.0.0.1'
  config.vm.network 'forwarded_port', guest: 7472, host: 7472, host_ip: '127.0.0.1'

  # Share an additional folder to the guest VM or configure . The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.

  project_name = 'neo4j'
  fail 'Vagrantfile project_name variable cannot be blank' if project_name.nil? || project_name == ''

  config.vm.synced_folder '.', "/home/ubuntu/#{project_name}"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "2048"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Disable notify-forwarder plugin, if present, because it was messing with Neo4j and causing a database panic
  # https://discuss.elastic.co/t/es-cluster-in-docker-containers-alreadyclosedexception-underlying-file-changed-by-an-external-force/48874/8
  if Vagrant.has_plugin?('vagrant-notify-forwarder')
    config.notify_forwarder.enable = false
  end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.

  config.vm.provision 'bootstrapping', type: 'shell', privileged: false,
                                       keep_color: true, inline: <<-SHELL
      PURPLE='\033[1;35m'; GREEN='\033[1;32m'; NC='\033[0;0m'
      echo "${PURPLE}BEGINNING BOOTSTRAPPING PROCESS...Grab a drink. This could take a while.${NC}"
      echo ' '
      echo "${PURPLE}UPDATING .BASHRC FILE${NC}"
      echo "cd /home/ubuntu/#{project_name}" >> /home/ubuntu/.bashrc
      cd ~/#{project_name}
      echo "${GREEN}COMPLETED UPDATING .BASHRC FILE${NC}"
      echo ' '
      echo "${PURPLE}INSTALLING JAVA${NC}"
      # Updates apt-get to point to updated java8 package
      yes | sudo add-apt-repository ppa:webupd8team/java
      # Updates apt-get
      sudo apt-get update
      # Set debconf config file to mark java8 license prompts as completed
      # https://askubuntu.com/questions/190582/installing-java-automatically-with-silent-option#
      # Install java8 without prompts
      echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
      echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
      yes | sudo apt-get install oracle-java8-installer
      echo "${GREEN}COMPLETED INSTALLING JAVA${NC}"
      echo ' '
      echo "${PURPLE}INSTALLING RVM & RUBY${NC}"
      yes | sudo apt-get install gnupg2
      gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
      # Current issue with rvm: https://github.com/rvm/rvm/issues/4068
      # use this patch until fixed
      curl -sSL https://raw.githubusercontent.com/wayneeseguin/rvm/stable/binscripts/rvm-installer | bash -s stable --ruby=2.4
      # uncomment and use below after fixed
      # curl -sSL https://get.rvm.io | bash -s stable --ruby=2.4
      source /home/ubuntu/.rvm/scripts/rvm
      echo "${GREEN}COMPLETED INSTALLING RVM & RUBY${NC}"
      echo ' '
      echo "${PURPLE}INSTALLING GEMS${NC}"
      gem install bundler --no-rdoc --no-ri
      # also install libcurl3, libcurl3-gnutls, & libcurl4-openssl-dev
      # which are needed by the "curb" gem, used in some 3rd party rake tasks--tho not actually sure about neo4j
      yes | sudo apt-get install libcurl3 libcurl4-openssl-dev
      bundle install
      gem install overcommit --no-rdoc --no-ri
      overcommit --install
      echo "${GREEN}COMPLETED INSTALLING GEMS${NC}"
  SHELL

  unless Dir['./db/neo4j/development'].any?
    # With default configuration, Neo4j only accepts local connections (which, in this case, means local to the VM).
    # Vagrant has been set up to forward connections local to the VM to the appropriate ports on the host machine.
    # As such, we need to change neo4j's conf to accept non-local connections if we want to be able to connect to
    # neo4j from a browser on the host machine:
    update_neo4j_conf = <<-TEXT
      require 'fileutils'
      require 'tempfile'

      t_file = Tempfile.new('neo4j.conf')
      File.open('./db/neo4j/development/conf/neo4j.conf', 'r+').each do |line|
        case line.chomp
        when '#dbms.connectors.default_listen_address=0.0.0.0'
          t_file.puts 'dbms.connectors.default_listen_address=0.0.0.0'
        when 'dbms.connector.bolt.listen_address=localhost:7472'
          t_file.puts 'dbms.connector.bolt.listen_address=:7472'
        when 'dbms.connector.http.listen_address=localhost:7474'
          t_file.puts 'dbms.connector.http.listen_address=:7474'
        when 'dbms.connector.https.listen_address=localhost:7473'
          t_file.puts 'dbms.connector.https.listen_address=:7473'
        else
          t_file.puts line
        end
      end
      t_file.close
      FileUtils.mv(t_file.path, './db/neo4j/development/conf/neo4j.conf')
    TEXT

    config.vm.provision 'install neo4j', type: 'shell', privileged: false,
                                         keep_color: true, inline: <<-SHELL
        PURPLE='\033[1;35m'; GREEN='\033[1;32m'; NC='\033[0;0m'
        echo "${PURPLE}INSTALLING NEO4J INTO 'db/neo4j/development'${NC}"
        cd ~/#{project_name}
        rake neo4j:install[community-latest]
        ruby -e "#{update_neo4j_conf}"
        echo "${GREEN}COMPLETED INSTALLING NEO4J INTO 'db/neo4j/development'${NC}"
    SHELL
  end

  config.vm.provision 'bootstrapping complete', type: 'shell', privileged: false,
                                                keep_color: true, run: 'always', inline: <<-SHELL
      GREEN="\033[1;32m"; BLUE='\033[1;34m'; NC="\033[0;0m"
      echo "${GREEN}BOOTSTRAPPING COMPLETE!${NC}"
      echo "${BLUE}Database server not started${NC}"
      echo ' '
      echo "${BLUE}Once started, to connect to the neo4j dev database in your browser visit:${NC}"
      echo "${BLUE}- HTTP: http://localhost:7474${NC}"
      echo "${BLUE}- HTTPS: https://localhost:7473${NC}"
      echo "${BLUE}- BOLT: bolt://localhost:7472${NC}"
      echo "${BLUE}To kill the dev database server run 'rake neo4j:stop' inside the VM${NC}"
      echo ' '
      echo "${BLUE}With the neo4j server running, execute 'rspec' inside the VM to run the test suite${NC}"
    SHELL
end
