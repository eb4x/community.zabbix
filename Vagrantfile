# -*- mode: ruby -*-
# vi: set ft=ruby :

# vagrant plugin install vagrant-libvirt
# export VAGRANT_DEFAULT_PROVIDER=libvirt

# vagrant plugin install vagrant-hostmanager
# /etc/sudoers.d/vagrant_hostmanager
# Cmnd_Alias VAGRANT_HOSTMANAGER_UPDATE = /bin/cp <home-directory>/.vagrant.d/tmp/hosts.local /etc/hosts
# %<admin-group> ALL=(root) NOPASSWD: VAGRANT_HOSTMANAGER_UPDATE

Vagrant.configure("2") do |config|

  # Allow messing with the hypervisor /etc/hosts file
  # for dns
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true

  config.vm.synced_folder '.', '/vagrant', disabled: true

  config.vm.provider "libvirt" do |lv|
    lv.machine_type = "q35" # qemu-system-x86_64 -machine help

    # https://libvirt.org/formatdomain.html#bios-bootloader
    lv.loader = '/usr/share/OVMF/OVMF_CODE.fd'
    #lv.loader = '/usr/share/OVMF/OVMF_CODE.secboot.fd'
    #lv.nvram = '/usr/share/OVMF/OVMF_VARS.secboot.fd'

    lv.cpus = 2
    lv.memory = 2048

    lv.disk_bus = "scsi"
    lv.disk_controller_model = "virtio-scsi"

    lv.graphics_type = "vnc"
    lv.video_type = "virtio"
  end

  ENV['ANSIBLE_ROLES_PATH'] = "#{File.dirname(__FILE__)}/roles"
  #ENV['HTTP_PROXY'] = "http://squid_zbx_user:squid_zbx_pass@zabbix-integrations.vagrant.local:3128"

  config.vm.define "zabbix-agent-win10" do |subconfig|
    subconfig.vm.hostname = "zabbix-agent-win10.vagrant.local"
    #subconfig.vm.box = "windows-server/2022"
    subconfig.vm.box = "windows/10"

    subconfig.vm.provider "libvirt" do |lv|
      lv.input type: "tablet", bus: "usb"
    end

    subconfig.vm.provision "windoze", type: "ansible", compatibility_mode: "2.0",
      raw_arguments: ["--diff"], playbook: "extensions/vagrant/windoze.yml"
  end

  config.vm.define "zabbix-server-db" do |subconfig|
    subconfig.vm.hostname = "zabbix-server-db.vagrant.local"
    subconfig.vm.box = "almalinux/8"

    subconfig.vm.provision "vagrant os image fixes", type: "ansible", compatibility_mode: "2.0",
      raw_arguments: ["--diff"], playbook: "extensions/vagrant/vagrant-os-image-fixes.yml"

    subconfig.vm.provision "zabbix server database", type: "ansible", compatibility_mode: "2.0",
      raw_arguments: ["--diff"], playbook: "extensions/vagrant/database-mysql.yml"
  end

  config.vm.define "zabbix-server-mysql" do |subconfig|
    subconfig.vm.hostname = "zabbix-server.vagrant.local"

    subconfig.vm.box = "almalinux/9"
    #subconfig.vm.box = "almalinux/8"
    #subconfig.vm.box = "debian/bookworm64"
    #subconfig.vm.box = "debian/bullseye64"
    #subconfig.vm.box = "debian/buster64"
    #subconfig.vm.box = "ubuntu/noble64"
    #subconfig.vm.box = "ubuntu/jammy64"
    #subconfig.vm.box = "ubuntu/focal64"
    #subconfig.vm.box = "ubuntu/bionic64"

#    subconfig.vm.provision "collection build", type: "ansible", compatibility_mode: "2.0",
#      galaxy_command: "ansible-galaxy collection build --force",
#      galaxy_role_file: "extensions/vagrant/galaxy-dummy-requirements.yml",
#      playbook: "extensions/vagrant/galaxy-dummy-playbook.yml",
#      extra_vars: { collection_action: "Build" }
#
#    subconfig.vm.provision "collection install", type: "ansible", compatibility_mode: "2.0",
#      galaxy_command: "ansible-galaxy collection install --force community-zabbix-3.1.2.tar.gz",
#      galaxy_role_file: "extensions/vagrant/galaxy-dummy-requirements.yml",
#      playbook: "extensions/vagrant/galaxy-dummy-playbook.yml",
#      extra_vars: { collection_action: "Install" }

    subconfig.vm.provision "vagrant os image fixes", type: "ansible", compatibility_mode: "2.0",
      raw_arguments: ["--diff"], playbook: "extensions/vagrant/vagrant-os-image-fixes.yml"

#    subconfig.vm.provision "install database for zabbix-server", type: "ansible", compatibility_mode: "2.0",
#      raw_arguments: ["--diff"], playbook: "extensions/vagrant/database-mysql.yml"

    #export ANSIBLE_COLLECTIONS_PATHS=$(pwd)/../..:${HOME}/.ansible/collections
    mysql_login_unix_socket = case subconfig.vm.box
                              when /debian|ubuntu/          then "/run/mysqld/mysqld.sock"
                              when /almalinux|centos|rocky/ then "/var/lib/mysql/mysql.sock"
                              else "" end
    subconfig.vm.provision "install zabbix-server", type: "ansible", compatibility_mode: "2.0",
      force_remote_user: false,
      raw_arguments: ["--diff"], playbook: "molecule/zabbix_server/converge.yml",
      extra_vars: {
        zabbix_server_database: "mysql",
        zabbix_server_dbhost_run_install: true,
        zabbix_server_install_database_client: false,
        zabbix_server_mysql_login_unix_socket: mysql_login_unix_socket,
        selinux_allow_zabbix_can_network: true
      }
      #extra_vars: {
      #  zabbix_server_database: "mysql",
      #  zabbix_server_dbtlsconnect: "required",
      #  zabbix_server_dbhost: "zabbix-server-db.vagrant.local",
      #  zabbix_server_dbhost_run_install: true,
      #  zabbix_server_install_database_client: false,
      #  zabbix_server_dbuser_append_priv: "{{ zabbix_server_dbname }}.*:REQUIRESSL",

      #  selinux_allow_zabbix_can_network: true,
      #  #zabbix_server_mysql_login_host: "zabbix-server-mysql.vagrant.local",
      #  zabbix_server_privileged_host: "zabbix-server.vagrant.local",
      #  zabbix_server_mysql_login_unix_socket: "/var/lib/mysql/mysql.sock", #RedHat
      #  #zabbix_server_mysql_login_unix_socket: "/run/mysqld/mysqld.sock",   #Debian
      #}
  end

  config.vm.define "zabbix-server-pgsql" do |subconfig|
    subconfig.vm.hostname = "zabbix-server.vagrant.local"

    subconfig.vm.box = "almalinux/9"
    #subconfig.vm.box = "almalinux/8"
    #subconfig.vm.box = "debian/bookworm64"
    #subconfig.vm.box = "debian/bullseye64"
    #subconfig.vm.box = "debian/buster64"
    #subconfig.vm.box = "ubuntu/noble64"
    #subconfig.vm.box = "ubuntu/jammy64"
    #subconfig.vm.box = "ubuntu/focal64"
    #subconfig.vm.box = "ubuntu/bionic64"

    subconfig.vm.synced_folder '.', '/vagrant', disabled: true

    subconfig.vm.provision "python3", type: "shell",
      privileged: true,
      inline: <<-SHELL
        source /etc/os-release
        case "$ID" in
          almalinux|rockylinux)
            if [ "${VERSION_ID%%.*}" -eq 8 ]; then
              dnf install -y "@python39/common"
            fi

            dnf module disable -y postgresql
            ;;
          debian)
            ;;
          *)
            ;;
        esac
      SHELL

    subconfig.vm.provision "vagrant os image fixes", type: "ansible", compatibility_mode: "2.0",
      raw_arguments: ["--diff"], playbook: "extensions/vagrant/vagrant-os-image-fixes.yml"

    subconfig.vm.provision "install database for zabbix-server", type: "ansible", compatibility_mode: "2.0",
      raw_arguments: ["--diff"], playbook: "extensions/vagrant/database-pgsql.yml"

    subconfig.vm.provision "install zabbix-server", type: "ansible", compatibility_mode: "2.0",
      force_remote_user: false,
      raw_arguments: ["--diff"], playbook: "molecule/zabbix_server/converge.yml",
      extra_vars: {
        zabbix_server_database: "pgsql",
        zabbix_server_database_timescaledb: false,
        zabbix_server_dbhost_run_install: true,
        zabbix_server_install_database_client: false,
        selinux_allow_zabbix_can_network: true,
        selinux_allow_zabbix_run_sudo: true
      }

    subconfig.vm.provision "install zabbix-agent", type: "ansible", compatibility_mode: "2.0",
      force_remote_user: false,
      raw_arguments: ["--diff"], playbook: "molecule/zabbix_agent_tests/common/playbooks/converge.yml",
      extra_vars: {
        zabbix_agent_hostname: "Zabbix server",
        zabbix_agent_server: "127.0.0.1,zabbix-server.vagrant.local"
      }

  end
  config.vm.define "zabbix-proxy-mysql" do |subconfig|
    subconfig.vm.hostname = "zabbix-proxy.vagrant.local"

    #subconfig.vm.box = "almalinux/9"
    subconfig.vm.box = "almalinux/8"

    subconfig.vm.provision "python3", type: "shell",
      privileged: true,
      inline: <<-SHELL
        source /etc/os-release
        case "$ID" in
          almalinux|rockylinux)
            if [ "${VERSION_ID%%.*}" -eq 8 ]; then
              dnf install -y "@python39/common"
            fi

            dnf module disable -y postgresql
            ;;
          debian)
            ;;
          *)
            ;;
        esac
      SHELL

    subconfig.vm.provision "vagrant os image fixes", type: "ansible", compatibility_mode: "2.0",
      raw_arguments: ["--diff"], playbook: "extensions/vagrant/vagrant-os-image-fixes.yml"

    subconfig.vm.provision "install database for zabbix-proxy", type: "ansible", compatibility_mode: "2.0",
      raw_arguments: ["--diff"], playbook: "extensions/vagrant/database-pgsql.yml"

    mysql_login_unix_socket = case subconfig.vm.box
                              when /debian|ubuntu/          then "/run/mysqld/mysqld.sock"
                              when /almalinux|centos|rocky/ then "/var/lib/mysql/mysql.sock"
                              else "" end
    subconfig.vm.provision "install zabbix-proxy", type: "ansible", compatibility_mode: "2.0",
      force_remote_user: false,
      raw_arguments: ["--diff"], playbook: "molecule/zabbix_proxy/converge.yml",
      extra_vars: {
        zabbix_proxy_hostname: "zabbix-proxy.vagrant.local",
        zabbix_proxy_database: "mysql",
        zabbix_proxy_dbhost_run_install: true,
        zabbix_proxy_install_database_client: false,
        zabbix_proxy_mysql_login_unix_socket: mysql_login_unix_socket,
        zabbix_proxy_server: "zabbix-server.vagrant.local",
        zabbix_api_server_host: "zabbix-web.vagrant.local",
        ansible_zabbix_url_path: "",
        zabbix_api_create_proxy: true,
        selinux_allow_zabbix_can_network: true
      }

    subconfig.vm.provision "install zabbix-agent", type: "ansible", compatibility_mode: "2.0",
      force_remote_user: false,
      raw_arguments: ["--diff"], playbook: "molecule/zabbix_agent_tests/common/playbooks/converge.yml",
      extra_vars: {
        zabbix_agent_hostname: "zabbix-proxy.vagrant.local",
        zabbix_agent_server: "127.0.0.1,zabbix-proxy.vagrant.local",
        zabbix_agent_monitored_by: "proxy",
        zabbix_agent_proxy: "zabbix-proxy.vagrant.local",
        zabbix_api_server_host: "zabbix-web.vagrant.local",
        ansible_zabbix_url_path: "",
        zabbix_api_create_hosts: true
      }
  end

  config.vm.define "zabbix-proxy-pgsql" do |subconfig|
    subconfig.vm.hostname = "zabbix-proxy.vagrant.local"

    subconfig.vm.box = "almalinux/9"
    #subconfig.vm.box = "almalinux/8"

    subconfig.vm.provision "python3", type: "shell",
      privileged: true,
      inline: <<-SHELL
        source /etc/os-release
        case "$ID" in
          almalinux|rockylinux)
            if [ "${VERSION_ID%%.*}" -eq 8 ]; then
              dnf install -y "@python39/common"
            fi

            dnf module disable -y postgresql
            ;;
          debian)
            ;;
          *)
            ;;
        esac
      SHELL

    subconfig.vm.provision "vagrant os image fixes", type: "ansible", compatibility_mode: "2.0",
      raw_arguments: ["--diff"], playbook: "extensions/vagrant/vagrant-os-image-fixes.yml"

    subconfig.vm.provision "install database for zabbix-proxy", type: "ansible", compatibility_mode: "2.0",
      raw_arguments: ["--diff"], playbook: "extensions/vagrant/database-pgsql.yml"

    subconfig.vm.provision "install zabbix-proxy", type: "ansible", compatibility_mode: "2.0",
      force_remote_user: false,
      raw_arguments: ["--diff"], playbook: "molecule/zabbix_proxy/converge.yml",
      extra_vars: {
        zabbix_proxy_hostname: "zabbix-proxy.vagrant.local",
        zabbix_proxy_database: "pgsql",
        zabbix_proxy_database_timescaledb: false,
        zabbix_proxy_dbhost_run_install: true,
        zabbix_proxy_install_database_client: false,
        zabbix_proxy_server: "zabbix-server.vagrant.local",
        zabbix_api_server_host: "zabbix-web.vagrant.local",
        ansible_zabbix_url_path: "",
        zabbix_api_create_proxy: true,
        selinux_allow_zabbix_can_network: true
      }

    subconfig.vm.provision "install zabbix-agent", type: "ansible", compatibility_mode: "2.0",
      force_remote_user: false,
      raw_arguments: ["--diff"], playbook: "molecule/zabbix_agent_tests/common/playbooks/converge.yml",
      extra_vars: {
        zabbix_agent_hostname: "zabbix-proxy.vagrant.local",
        zabbix_agent_server: "127.0.0.1,zabbix-proxy.vagrant.local",
        zabbix_agent_monitored_by: "proxy",
        zabbix_agent_proxy: "zabbix-proxy.vagrant.local",
        zabbix_api_server_host: "zabbix-web.vagrant.local",
        ansible_zabbix_url_path: "",
        zabbix_api_create_hosts: true
      }
  end

  config.vm.define "zabbix-proxy-sqlite3" do |subconfig|
    subconfig.vm.hostname = "zabbix-proxy.vagrant.local"

    subconfig.vm.box = "almalinux/9"
    #subconfig.vm.box = "almalinux/8"

    subconfig.vm.provision "python3", type: "shell",
      privileged: true,
      inline: <<-SHELL
        source /etc/os-release
        case "$ID" in
          almalinux|rockylinux)
            if [ "${VERSION_ID%%.*}" -eq 8 ]; then
              dnf install -y "@python39/common"
            fi

            dnf module disable -y postgresql
            ;;
          debian)
            ;;
          *)
            ;;
        esac
      SHELL

    subconfig.vm.provision "vagrant os image fixes", type: "ansible", compatibility_mode: "2.0",
      raw_arguments: ["--diff"], playbook: "extensions/vagrant/vagrant-os-image-fixes.yml"

    subconfig.vm.provision "install zabbix-proxy", type: "ansible", compatibility_mode: "2.0",
      force_remote_user: false,
      raw_arguments: ["--diff"], playbook: "molecule/zabbix_proxy/converge.yml",
      extra_vars: {
        zabbix_proxy_hostname: "zabbix-proxy.vagrant.local",
        zabbix_proxy_database: "sqlite3",
        zabbix_proxy_server: "zabbix-server.vagrant.local",
        zabbix_api_server_host: "zabbix-web.vagrant.local",
        ansible_zabbix_url_path: "",
        zabbix_api_create_proxy: true,
        selinux_allow_zabbix_can_network: true
      }

    subconfig.vm.provision "install zabbix-agent", type: "ansible", compatibility_mode: "2.0",
      force_remote_user: false,
      raw_arguments: ["--diff"], playbook: "molecule/zabbix_agent_tests/common/playbooks/converge.yml",
      extra_vars: {
        zabbix_agent_hostname: "zabbix-proxy.vagrant.local",
        zabbix_agent_server: "127.0.0.1,zabbix-proxy.vagrant.local",
        zabbix_agent_monitored_by: "proxy",
        zabbix_agent_proxy: "zabbix-proxy.vagrant.local",
        zabbix_api_server_host: "zabbix-web.vagrant.local",
        ansible_zabbix_url_path: "",
        zabbix_api_create_hosts: true
      }
  end

  config.vm.define "zabbix-web-nginx-pgsql" do |subconfig|
    subconfig.vm.hostname = "zabbix-web.vagrant.local"

    subconfig.vm.box = "almalinux/9"
    #subconfig.vm.box = "almalinux/8"

    subconfig.vm.provision "python3", type: "shell",
      privileged: true,
      inline: <<-SHELL
        source /etc/os-release
        case "$ID" in
          almalinux|rockylinux)
            if [ "${VERSION_ID%%.*}" -eq 8 ]; then
              dnf install -y "@python39/common"
            fi

            dnf module disable -y postgresql
            ;;
          debian)
            ;;
          *)
            ;;
        esac
      SHELL

    subconfig.vm.provision "vagrant os image fixes", type: "ansible", compatibility_mode: "2.0",
      raw_arguments: ["--diff"], playbook: "extensions/vagrant/vagrant-os-image-fixes.yml"

    subconfig.vm.provision "install web pre-requisites", type: "ansible", compatibility_mode: "2.0",
      raw_arguments: ["--diff"], playbook: "extensions/vagrant/php.yml"

    subconfig.vm.provision "install zabbix-web", type: "ansible", compatibility_mode: "2.0",
      force_remote_user: false,
      raw_arguments: ["--diff"], playbook: "molecule/zabbix_web/converge.yml",
      extra_vars: {
        zabbix_web_http_server: "nginx",
        zabbix_server_database: "pgsql",
        zabbix_server_dbuser: "zabbix-server",
        zabbix_server_dbpassword: "zabbix-server",
        zabbix_server_dbhost: "zabbix-server.vagrant.local",
        zabbix_server_dbname: "zabbix-server",
        zabbix_server_hostname: "zabbix-server.vagrant.local",
        zabbix_server_name: "Zabbix web service",
        zabbix_api_server_url: "zabbix-web.vagrant.local",
        selinux_allow_httpd_can_connect_zabbix: true,
        selinux_allow_httpd_can_network_connect_db: true
      }

    subconfig.vm.provision "install zabbix-agent", type: "ansible", compatibility_mode: "2.0",
      force_remote_user: false,
      raw_arguments: ["--diff"], playbook: "molecule/zabbix_agent_tests/common/playbooks/converge.yml",
      extra_vars: {
        zabbix_agent_hostname: "zabbix-web.vagrant.local",
        zabbix_agent_server: "zabbix-server.vagrant.local,zabbix-proxy.vagrant.local",
        #zabbix_agent_monitored_by: "proxy",
        #zabbix_agent_proxy: "zabbix-proxy.vagrant.local"
        zabbix_api_server_host: "zabbix-web.vagrant.local",
        zabbix_api_server_port: "80", # REMOVE
        ansible_zabbix_url_path: "",
        zabbix_api_create_hosts: true
      }
  end

  config.vm.define "zabbix-agent-debian-selinux" do |subconfig|
    subconfig.vm.hostname = "zabbix-agent-debian-selinux.vagrant.local"
    subconfig.vm.box = "debian/bookworm64"

    subconfig.vm.provision "vagrant os image fixes", type: "ansible", compatibility_mode: "2.0",
      raw_arguments: ["--diff"], playbook: "extensions/vagrant/vagrant-os-image-fixes.yml"

    subconfig.vm.provision "debian-selinux", type: "ansible", compatibility_mode: "2.0",
      raw_arguments: ["--diff"], playbook: "extensions/vagrant/debian-selinux.yml"

    subconfig.vm.provision "install zabbix-agent", type: "ansible", compatibility_mode: "2.0",
      force_remote_user: false,
      raw_arguments: ["--diff"], playbook: "molecule/zabbix_agent_tests/common/playbooks/converge.yml",
      extra_vars: {
        zabbix_agent_hostname: "zabbix-web.vagrant.local",
        zabbix_agent_server: "zabbix-server.vagrant.local,zabbix-proxy.vagrant.local",
        #zabbix_agent_monitored_by: "proxy",
        #zabbix_agent_proxy: "zabbix-proxy.vagrant.local"
        zabbix_api_server_host: "zabbix-web.vagrant.local",
        zabbix_api_server_port: "80", # REMOVE
        ansible_zabbix_url_path: "",
        #zabbix_http_proxy: "http://squid_zbx_user:squid_zbx_pass@zabbix-integrations.vagrant.local:3128",
        #zabbix_https_proxy: "http://squid_zbx_user:squid_zbx_pass@zabbix-integrations.vagrant.local:3128",
        zabbix_api_create_hosts: true
      }
  end

  config.vm.define "zabbix-integrations" do |subconfig|
    subconfig.vm.hostname = "zabbix-integrations.vagrant.local"

    subconfig.vm.box = "almalinux/9"
    #subconfig.vm.box = "almalinux/8"

    subconfig.vm.synced_folder '.', '/vagrant', disabled: true

    # Testing proxy that requires auth;
    #
    # export https_proxy=http://zabbix-integrations.vagrant.local:3128
    # curl -v --proxy-header 'Proxy-Authorization: Basic c3F1aWRfemJ4X3VzZXI6c3F1aWRfemJ4X3Bhc3M='
    subconfig.vm.provision "squid", type: "ansible", compatibility_mode: "2.0",
      raw_arguments: ["--diff"], playbook: "extensions/vagrant/squid.yml"
  end
end
