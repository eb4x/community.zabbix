# -*- mode: ruby -*-
# vi: set ft=ruby :

# vagrant plugin install vagrant-libvirt
# export VAGRANT_DEFAULT_PROVIDER=libvirt

# vagrant plugin install vagrant-hostmanager
# /etc/sudoers.d/vagrant_hostmanager
# Cmnd_Alias VAGRANT_HOSTMANAGER_UPDATE = /bin/cp <home-directory>/.vagrant.d/tmp/hosts.local /etc/hosts
# %<admin-group> ALL=(root) NOPASSWD: VAGRANT_HOSTMANAGER_UPDATE

def loader_for_box(box)
  # https://libvirt.org/formatdomain.html#bios-bootloader
  #lv.loader = '/usr/share/OVMF/OVMF_CODE.fd'
  #lv.loader = '/usr/share/OVMF/OVMF_CODE.secboot.fd'
  #lv.nvram = '/usr/share/OVMF/OVMF_VARS.secboot.fd'
  case box
  when /debian|ubuntu/          then nil
  when /almalinux|centos|rocky|windows/ then "/usr/share/OVMF/OVMF_CODE.fd"
  else nil end
end

#BOX = "almalinux/10"
#BOX = "almalinux/9"
#BOX = "almalinux/8"
#BOX = "debian/bookworm64"
#BOX = "debian/bullseye64"
#BOX = "debian/buster64"
#BOX = "opensuse/Leap-15.6.x86_64"
#BOX = "ubuntu/jammy64"
#BOX = "ubuntu/focal64"
#BOX = "ubuntu/bionic64"

# https://github.com/alchemy-solutions/vagrant-cloud-images
#BOX = "cloud-image/almalinux-10"
#BOX = "cloud-image/almalinux-9"
#BOX = "cloud-image/almalinux-8"
#BOX = "cloud-image/centos-10-stream"
#BOX = "cloud-image/centos-9-stream"
#BOX = "cloud-image/centos-8-stream"
#BOX = "cloud-image/centos-7"
BOX = "cloud-image/debian-13"
#BOX = "cloud-image/debian-12"
#BOX = "cloud-image/debian-11"
#BOX = "cloud-image/opensuse-leap-16.0"
#BOX = "crystax/suse15sp7"
#BOX = "crystax/suse15sp6"
#BOX = "crystax/suse15sp5"
#BOX = "crystax/suse15sp4"
#BOX = "crystax/suse15sp3"
#BOX = "cloud-image/ubuntu-24.04"
#BOX = "cloud-image/ubuntu-22.04"


PROVISIONERS = {
  squid_client: proc do |subconfig|
    subconfig.vm.provision "squid client", type: "shell", privileged: true,
      inline: <<~SHELL
        tee /etc/environment > /dev/null <<EOF
        http_proxy="http://squid_zbx_user:squid_zbx_pass@zabbix-integrations.vagrant.local:3128"
        https_proxy="http://squid_zbx_user:squid_zbx_pass@zabbix-integrations.vagrant.local:3128"
        no_proxy=localhost,127.0.0.1,::1,.vagrant.local
        EOF
      SHELL
  end,
  python3: proc do |subconfig|
    subconfig.vm.provision "python3", type: "shell",
      privileged: true,
      inline: <<~SHELL
        source /etc/os-release
        if [[ "$VERSION_ID" =~ ^7 ]]; then
          if [[ "$(sha256sum /etc/yum.repos.d/CentOS-Base.repo | awk '{print $1}')" != "00b0cc7dbae97ecf4447c0db0c5e20b563c2b6b14278169e20ae5f464c101d00" ]]; then
            curl https://el7.repo.almalinux.org/centos/CentOS-Base.repo -o /etc/yum.repos.d/CentOS-Base.repo
          fi
        fi
        case "$ID" in
          almalinux|rockylinux)
            if [ "${VERSION_ID%%.*}" -eq 8 ]; then
              dnf install -y "@python39/common"
            fi

            #dnf module disable -y postgresql
            ;;
          debian|ubuntu)
            ;;
          opensuse-leap)
            # python311 has corresponding PyMySQL and psycopg2 packages
            zypper install -y python311
            ;;
          *)
            ;;
        esac
      SHELL
  end,
  vagrant_os_image_fixes: proc do |subconfig|
    subconfig.vm.provision "vagrant os image fixes", type: "ansible", compatibility_mode: "2.0",
      raw_arguments: ["--diff"], playbook: "extensions/vagrant/vagrant-os-image-fixes.yml"
  end,
  letsencrypt: proc do |subconfig|
    subconfig.vm.provision "letsencrypt", type: "ansible", compatibility_mode: "2.0",
      raw_arguments: ["--diff"], playbook: "extensions/vagrant/letsencrypt.yml"
  end,
  database: proc do |subconfig, opts = {}|
    type = opts.fetch(:type) { raise ArgumentError, "Database type required (mysql/pgsql/timescale)" }

    extra_vars = {}
    if type == "timescale"
      extra_vars[:install_timescaledb] = true
    end

    type = (type == "timescale") ? "pgsql" : type
    subconfig.vm.provision "database", type: "ansible", compatibility_mode: "2.0",
      raw_arguments: ["--diff"], playbook: "extensions/vagrant/database-#{type}.yml",
      extra_vars: extra_vars
  end,
  php: proc do |subconfig, opts = {}|
    extra_vars = {}
    extra_vars[:http_server] = opts.fetch(:http_server) { raise ArgumentError, "Web server type required (apache/nginx)" }

    subconfig.vm.provision "php", type: "ansible", compatibility_mode: "2.0",
      raw_arguments: ["--diff"], playbook: "extensions/vagrant/php.yml",
      extra_vars: extra_vars
  end,

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

  zabbix_repo: proc do |subconfig, extra_vars = {}|
    subconfig.vm.provision "zabbix_repo", type: "ansible", compatibility_mode: "2.0",
      force_remote_user: false,
      raw_arguments: ["--diff"], playbook: "molecule/zabbix_repo/converge.yml",
      extra_vars: extra_vars
  end,

  zabbix_server: proc do |subconfig, extra_vars = {}|
    if extra_vars[:zabbix_server_database] == "mysql"
      extra_vars[:zabbix_server_mysql_login_unix_socket] =
        case subconfig.vm.box
        when /debian|ubuntu/          then "/run/mysqld/mysqld.sock"
        when /almalinux|centos|rocky/ then "/var/lib/mysql/mysql.sock"
        when /suse/                   then "/run/mysql/mysql.sock"
        else "" end
    end

    extra_vars[:zabbix_manage_repo] = false
    extra_vars[:zabbix_server_install_database_client] = false

    subconfig.vm.provision "zabbix_server", type: "ansible", compatibility_mode: "2.0",
      force_remote_user: false,
      raw_arguments: ["--diff"], playbook: "molecule/zabbix_server/converge.yml",
      extra_vars: extra_vars

      #extra_vars: {
      #  zabbix_server_database: "mysql",
      #  selinux_allow_zabbix_run_sudo: true
      #}
      #extra_vars: {
      #  zabbix_server_database: "mysql", zabbix_server_dbtlsconnect: "required", zabbix_server_dbhost: "zabbix-server-db.vagrant.local",
      #  zabbix_server_dbhost_run_install: true,
      #  zabbix_server_install_database_client: false,
      #  zabbix_server_dbuser_append_priv: "{{ zabbix_server_dbname }}.*:REQUIRESSL",
      #  zabbix_server_mysql_login_host: "zabbix-server-mysql.vagrant.local",
      #  zabbix_server_privileged_host: "zabbix-server.vagrant.local",
      #  selinux_allow_zabbix_run_sudo: true
      #}
      #extra_vars: {
      #  zabbix_manage_repo: false,
      #  zabbix_server_database: "pgsql", zabbix_server_database_timescaledb: false,
      #  selinux_allow_zabbix_can_network: true,
      #  selinux_allow_zabbix_run_sudo: true
      #}
  end,
  zabbix_proxy: proc do |subconfig, extra_vars = {}|
    if extra_vars[:zabbix_proxy_database] == "mysql"
      extra_vars[:zabbix_proxy_mysql_login_unix_socket] =
        case subconfig.vm.box
        when /debian|ubuntu/          then "/run/mysqld/mysqld.sock"
        when /almalinux|centos|rocky/ then "/var/lib/mysql/mysql.sock"
        when /suse/                   then "/run/mysql/mysql.sock"
        else "" end
    end

    extra_vars[:zabbix_manage_repo] = false
    extra_vars[:zabbix_proxy_install_database_client] = false

    subconfig.vm.provision "zabbix_proxy", type: "ansible", compatibility_mode: "2.0",
      force_remote_user: false,
      raw_arguments: ["--diff"], playbook: "molecule/zabbix_proxy/converge.yml",
      extra_vars: extra_vars
  end,
  zabbix_web: proc do |subconfig, extra_vars = {}|
    extra_vars[:zabbix_manage_repo] = false

    subconfig.vm.provision "zabbix_web", type: "ansible", compatibility_mode: "2.0",
      force_remote_user: false,
      raw_arguments: ["--diff"], playbook: "molecule/zabbix_web/converge.yml",
      extra_vars: extra_vars
      #extra_vars: {
      #  zabbix_web_http_server: "nginx",
      #  zabbix_server_database: "pgsql",
      #  zabbix_server_name: "Zabbix web service",
      #  zabbix_api_server_url: "zabbix-aio.vagrant.local",
      #  selinux_allow_httpd_can_connect_zabbix: true,
      #  selinux_allow_httpd_can_network_connect_db: true
      #}
  end,
  zabbix_agent: proc do |subconfig, extra_vars = {}|
    extra_vars[:zabbix_manage_repo] = false

    subconfig.vm.provision "zabbix_agent", type: "ansible", compatibility_mode: "2.0",
      force_remote_user: false,
      raw_arguments: ["--diff"], playbook: "molecule/zabbix_agent_tests/common/playbooks/converge.yml",
      extra_vars: extra_vars
      #extra_vars: {
      #  zabbix_agent_hostname: "zabbix-proxy.vagrant.local",
      #  zabbix_agent_server: "127.0.0.1,zabbix-proxy.vagrant.local",
      #  zabbix_agent_monitored_by: "proxy",
      #  zabbix_agent_proxy: "zabbix-proxy.vagrant.local",
      #  zabbix_api_server_host: "zabbix-web.vagrant.local",
      #  ansible_zabbix_url_path: "",
      #  zabbix_api_create_hosts: true
      #}
  end,
}

def apply_provisioners(subconfig, *provs)
  provs.each do |p|
    key, opts = p.is_a?(Array) ? p : [p, {}]
    PROVISIONERS[key].call(subconfig, opts)
  end
end

Vagrant.configure("2") do |config|

  # Allow messing with the hypervisor /etc/hosts file
  # for dns
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true

  config.vm.synced_folder '.', '/vagrant', disabled: true

  config.trigger.before :up do |trigger|
    trigger.name = "Generate certificates"
    trigger.run = {
      inline: 'bash -c "set -e; cd extensions/vagrant; ./generate-vagrant-certs.sh"'
    }
  end

  config.vm.provider "libvirt" do |lv|
    lv.machine_type = "q35" # qemu-system-x86_64 -machine help

    lv.cpus = 2
    lv.memory = 2048

    lv.disk_bus = "scsi"
    lv.disk_controller_model = "virtio-scsi"

    lv.graphics_type = "vnc"
    lv.video_type = "virtio"
  end

  ENV['ANSIBLE_ROLES_PATH'] = "#{File.dirname(__FILE__)}/roles"
  #ENV['HTTP_PROXY'] = "http://squid_zbx_user:squid_zbx_pass@zabbix-integrations.vagrant.local:3128"

  zabbix_aio_matrix = [
    "apache-mysql", "apache-pgsql", "apache-timescale",
    "nginx-mysql", "nginx-pgsql", "nginx-timescale"
  ]

  zabbix_aio_matrix.each do |variant|
    config.vm.define "zabbix-aio-#{variant}" do |subconfig|
      subconfig.vm.hostname = "zabbix-aio.vagrant.local"
      subconfig.vm.box = BOX

      subconfig.vm.provider "libvirt" do |lv|
        lv.loader = loader_for_box(subconfig.vm.box)
      end

      zabbix_version = "7.4"

      http_server, db = variant.split("-")
      database = (db == "timescale") ? "pgsql" : db

      apply_provisioners(subconfig,
        :python3,
        :vagrant_os_image_fixes,
        :letsencrypt,
        [:database, {
          type: db,
        }],
        [:zabbix_repo, {
          zabbix_repo_version: zabbix_version,
          zabbix_repo_package: "zabbix-server-#{database}",
        }],
        [:zabbix_server, {
          zabbix_server_version: zabbix_version,
          zabbix_server_database: database,
          zabbix_server_database_timescaledb: (db == "timescale"),
        }],
        [:php, {
          http_server: http_server,
        }],
        [:zabbix_web, {
          zabbix_web_version: zabbix_version,
          zabbix_web_http_server: http_server,
          zabbix_server_database: database,
          zabbix_server_hostname: "zabbix-aio.vagrant.local",
          zabbix_api_server_url: "zabbix-aio.vagrant.local",
          #zabbix_web_tls: true,
          #zabbix_web_tls_key: "/etc/letsencrypt/live/zabbix-aio.vagrant.local/privkey.pem",
          #zabbix_web_tls_crt: "/etc/letsencrypt/live/zabbix-aio.vagrant.local/cert.pem",
          #zabbix_web_tls_chain: "/etc/letsencrypt/live/zabbix-aio.vagrant.local/chain.pem",
        }],
        [:zabbix_agent, {
          zabbix_agent_version: zabbix_version,
          zabbix_agent_hostname: "Zabbix server",
          zabbix_agent_server: "127.0.0.1,zabbix-aio.vagrant.local",
        }],
      )
    end
  end

  zabbix_server_matrix = [
    "mysql", "pgsql", "timescale",
  ]

  zabbix_server_matrix.each do |variant|
    config.vm.define "zabbix-server-#{variant}-db" do |subconfig|
      subconfig.vm.hostname = "zabbix-server-db.vagrant.local"
      subconfig.vm.box = BOX

      subconfig.vm.provider "libvirt" do |lv|
        lv.loader = loader_for_box(subconfig.vm.box)
      end

      apply_provisioners(subconfig,
        :python3,
        :vagrant_os_image_fixes,
        [:database, { type: variant }],
      )
    end

    config.vm.define "zabbix-server-#{variant}" do |subconfig|
      subconfig.vm.hostname = "zabbix-server.vagrant.local"
      subconfig.vm.box = BOX

      subconfig.vm.provider "libvirt" do |lv|
        lv.loader = loader_for_box(subconfig.vm.box)
      end

      zabbix_version = "7.4"

      database = (variant == "timescale") ? "pgsql" : variant
      apply_provisioners(subconfig,
        :python3,
        :vagrant_os_image_fixes,
        [:zabbix_repo, {
          zabbix_repo_version: zabbix_version,
          zabbix_repo_package: "zabbix-server-#{database}",
        }],
        [:zabbix_server, {
          zabbix_server_version: zabbix_version,
          zabbix_server_database: database,
          zabbix_server_database_timescaledb: (variant == "timescale"),
          zabbix_server_mysql_login_user: "root",
          zabbix_server_mysql_login_password: "changeme",
          zabbix_server_mysql_login_host: "zabbix-server-db.vagrant.local",
          #zabbix_server_dbuser: zabbix-server,
          #zabbix_server_dbpassword: zabbix-server,
          zabbix_server_privileged_host: '%',
          #zabbix_server_privileged_host: 'zabbix-server.vagrant.local',
          zabbix_server_dbhost: "zabbix-server-db.vagrant.local",
          #zabbix_server_dbname: zabbix-server,
        }],
        [:zabbix_agent, {
          zabbix_agent_hostname: "Zabbix server",
          zabbix_agent_server: "127.0.0.1,zabbix-server.vagrant.local",
        }],
      )
    end
  end

  zabbix_web_matrix = [
    "apache-mysql", "apache-pgsql",
    "nginx-mysql", "nginx-pgsql"
  ]

  zabbix_web_matrix.each do |variant|
    config.vm.define "zabbix-web-#{variant}" do |subconfig|
      subconfig.vm.hostname = "zabbix-web.vagrant.local"
      subconfig.vm.box = BOX

      subconfig.vm.provider "libvirt" do |lv|
        lv.loader = loader_for_box(subconfig.vm.box)
      end

      zabbix_version = "7.4"

      http_server, database = variant.split("-")

      apply_provisioners(subconfig,
        :python3,
        :vagrant_os_image_fixes,
        [:zabbix_repo, {
          zabbix_repo_version: zabbix_version,
          zabbix_repo_package: "zabbix-web-#{database}",
        }],
        [:php, {
          http_server: http_server,
        }],
        [:zabbix_web, {
          zabbix_web_version: zabbix_version,
          zabbix_web_http_server: http_server,
          zabbix_server_database: database,
          zabbix_server_dbhost: "zabbix-server-db.vagrant.local",
          zabbix_server_hostname: "zabbix-server.vagrant.local",
          zabbix_api_server_url: "zabbix-web.vagrant.local",
          #zabbix_web_tls: true,
          #zabbix_web_tls_key: "/etc/letsencrypt/live/zabbix-aio.vagrant.local/privkey.pem",
          #zabbix_web_tls_crt: "/etc/letsencrypt/live/zabbix-aio.vagrant.local/cert.pem",
          #zabbix_web_tls_chain: "/etc/letsencrypt/live/zabbix-aio.vagrant.local/chain.pem",
        }],
#        [:zabbix_agent, {
#          zabbix_agent_hostname: "zabbix-web.vagrant.local",
#          zabbix_agent_server: "zabbix-server.vagrant.local,zabbix-proxy.vagrant.local",
##          zabbix_agent_monitored_by: "proxy",
##          zabbix_agent_proxy: "zabbix-proxy.vagrant.local",
#          zabbix_api_create_hosts: true,
#          zabbix_api_server_host: "zabbix-web.vagrant.local",
#          ansible_zabbix_url_path: "",
#        }],
      )
    end
  end

  zabbix_proxy_matrix = [
    "mysql", "pgsql", "sqlite3", "timescale"
  ]

  zabbix_proxy_matrix.each do |variant|
    config.vm.define "zabbix-proxy-#{variant}" do |subconfig|
      subconfig.vm.hostname = "zabbix-proxy.vagrant.local"
      subconfig.vm.box = BOX

      subconfig.vm.provider "libvirt" do |lv|
        lv.loader = loader_for_box(subconfig.vm.box)
      end

      database = (variant == "timescale") ? "pgsql" : variant
      apply_provisioners(subconfig,
        :python3,
        :vagrant_os_image_fixes,
        [:database, { type: database }],
        :zabbix_repo,
        [:zabbix_proxy, {
          zabbix_proxy_database: database,
          zabbix_proxy_database_timescaledb: (variant == "timescale"),
          zabbix_proxy_hostname: "zabbix-proxy.vagrant.local",
          zabbix_proxy_server: "zabbix-server.vagrant.local",
          zabbix_api_create_proxy: true,
          zabbix_api_server_host: "zabbix-web.vagrant.local",
          ansible_zabbix_url_path: "",
        }],
        [:zabbix_agent, {
          zabbix_agent_hostname: "zabbix-proxy.vagrant.local",
          zabbix_agent_server: "127.0.0.1,zabbix-proxy.vagrant.local",
          zabbix_agent_monitored_by: "proxy",
          zabbix_agent_proxy: "zabbix-proxy.vagrant.local",
          zabbix_api_create_hosts: true,
          zabbix_api_server_host: "zabbix-web.vagrant.local",
          ansible_zabbix_url_path: "",
        }],
      )
    end
  end

  config.vm.define "zabbix-agent-via-proxy" do |subconfig|
    subconfig.vm.hostname = "zabbix-agent-via-proxy.vagrant.local"

    subconfig.vm.provider "libvirt" do |lv|
      lv.loader = loader_for_box(subconfig.vm.box)
    end

    apply_provisioners(subconfig,
      :vagrant_os_image_fixes,
      [:zabbix_repo, {
        #zabbix_http_proxy: "http://squid_zbx_user:squid_zbx_pass@zabbix-integrations.vagrant.local:3128",
        #zabbix_https_proxy: "http://squid_zbx_user:squid_zbx_pass@zabbix-integrations.vagrant.local:3128",
      }],
      [:zabbix_agent, {
        zabbix_manage_repo: false,
        zabbix_agent_hostname: "zabbix-agent-almalinux9.vagrant.local",
        zabbix_agent_server: "zabbix-aio.vagrant.local,zabbix-server.vagrant.local,zabbix-proxy.vagrant.local",
        #zabbix_agent_monitored_by: "proxy",
        #zabbix_agent_proxy: "zabbix-proxy.vagrant.local"
        zabbix_api_create_hosts: false,
        zabbix_api_server_host: "zabbix-aio.vagrant.local",
        ansible_zabbix_url_path: "",
        #zabbix_http_proxy: "http://squid_zbx_user:squid_zbx_pass@zabbix-integrations.vagrant.local:3128",
        #zabbix_https_proxy: "http://squid_zbx_user:squid_zbx_pass@zabbix-integrations.vagrant.local:3128",
      }],
    )
  end

  config.vm.define "zabbix-agent-debian-selinux" do |subconfig|
    subconfig.vm.hostname = "zabbix-agent-debian-selinux.vagrant.local"
    subconfig.vm.box = "debian/bookworm64"

    subconfig.vm.provider "libvirt" do |lv|
      lv.loader = loader_for_box(subconfig.vm.box)
    end

    subconfig.vm.provision "vagrant os image fixes", type: "ansible", compatibility_mode: "2.0",
      raw_arguments: ["--diff"], playbook: "extensions/vagrant/vagrant-os-image-fixes.yml"

    subconfig.vm.provision "debian-selinux", type: "ansible", compatibility_mode: "2.0",
      raw_arguments: ["--diff"], playbook: "extensions/vagrant/debian-selinux.yml"

    subconfig.vm.provision "install zabbix-repo", type: "ansible", compatibility_mode: "2.0",
      force_remote_user: false,
      raw_arguments: ["--diff"], playbook: "molecule/zabbix_repo/converge.yml"

    subconfig.vm.provision "install zabbix-agent", type: "ansible", compatibility_mode: "2.0",
      force_remote_user: false,
      raw_arguments: ["--diff"], playbook: "molecule/zabbix_agent_tests/common/playbooks/converge.yml",
      extra_vars: {
        zabbix_manage_repo: false,
        zabbix_agent_hostname: "zabbix-agent-debian-selinux.vagrant.local",
        zabbix_agent_server: "zabbix-aio.vagrant.local,zabbix-server.vagrant.local,zabbix-proxy.vagrant.local",
        #zabbix_agent_monitored_by: "proxy",
        #zabbix_agent_proxy: "zabbix-proxy.vagrant.local"
        zabbix_api_create_hosts: true,
        zabbix_api_server_host: "zabbix-aio.vagrant.local",
        ansible_zabbix_url_path: "",
        #zabbix_http_proxy: "http://squid_zbx_user:squid_zbx_pass@zabbix-integrations.vagrant.local:3128",
        #zabbix_https_proxy: "http://squid_zbx_user:squid_zbx_pass@zabbix-integrations.vagrant.local:3128",
      }
  end

  config.vm.define "zabbix-agent-freebsd" do |subconfig|
    subconfig.vm.hostname = "zabbix-agent-freebsd.vagrant.local"
    subconfig.vm.box = "generic-x64/freebsd14"

    subconfig.vm.provider "libvirt" do |lv|
      lv.loader = loader_for_box(subconfig.vm.box)
    end

    subconfig.vm.provision "vagrant os image fixes", type: "ansible", compatibility_mode: "2.0",
      raw_arguments: ["--diff"], playbook: "extensions/vagrant/vagrant-os-image-fixes.yml"

    subconfig.vm.provision "install zabbix-agent", type: "ansible", compatibility_mode: "2.0",
      force_remote_user: false,
      raw_arguments: ["--diff"], playbook: "molecule/zabbix_agent_tests/common/playbooks/converge.yml",
      extra_vars: {
        zabbix_manage_repo: false,
        zabbix_agent_hostname: "zabbix-agent-freebsd.vagrant.local",
        zabbix_agent_server: "zabbix-aio.vagrant.local,zabbix-server.vagrant.local,zabbix-proxy.vagrant.local",
        #zabbix_agent_monitored_by: "proxy",
        #zabbix_agent_proxy: "zabbix-proxy.vagrant.local"
        zabbix_api_create_hosts: true,
        zabbix_api_server_host: "zabbix-aio.vagrant.local",
        ansible_zabbix_url_path: "",
        #zabbix_http_proxy: "http://squid_zbx_user:squid_zbx_pass@zabbix-integrations.vagrant.local:3128",
        #zabbix_https_proxy: "http://squid_zbx_user:squid_zbx_pass@zabbix-integrations.vagrant.local:3128",
      }
  end

  config.vm.define "zabbix-agent-win11" do |subconfig|
#    subconfig.vm.hostname = "zabbix-agent-win11.vagrant.local"
    subconfig.vm.box = "windows/11-x64"

    subconfig.vm.provider "libvirt" do |lv|
      lv.loader = loader_for_box(subconfig.vm.box)
      lv.input type: "tablet", bus: "usb"
    end

    subconfig.vm.provision "windoze", type: "ansible", compatibility_mode: "2.0",
      raw_arguments: ["--diff"], playbook: "extensions/vagrant/windoze.yml"
    subconfig.vm.provision "install zabbix-agent", type: "ansible", compatibility_mode: "2.0",
      force_remote_user: false,
      raw_arguments: ["--diff"], playbook: "molecule/zabbix_agent_tests/common/playbooks/converge.yml",
      extra_vars: {
        zabbix_manage_repo: false,
        zabbix_agent_hostname: "zabbix-agent-win11.vagrant.local",
        zabbix_agent_server: "zabbix-aio.vagrant.local,zabbix-server.vagrant.local,zabbix-proxy.vagrant.local",
        #zabbix_agent_monitored_by: "proxy",
        #zabbix_agent_proxy: "zabbix-proxy.vagrant.local"
        zabbix_api_create_hosts: true,
        zabbix_api_server_host: "zabbix-aio.vagrant.local",
        ansible_zabbix_url_path: "",
        #zabbix_http_proxy: "http://squid_zbx_user:squid_zbx_pass@zabbix-integrations.vagrant.local:3128",
        #zabbix_https_proxy: "http://squid_zbx_user:squid_zbx_pass@zabbix-integrations.vagrant.local:3128",
      }
  end

  config.vm.define "zabbix-agent-win2k25" do |subconfig|
#    subconfig.vm.hostname = "zabbix-agent-win2k25.vagrant.local"
    subconfig.vm.box = "windows/server-2025-x64"

    subconfig.vm.provider "libvirt" do |lv|
      lv.loader = loader_for_box(subconfig.vm.box)
      lv.input type: "tablet", bus: "usb"
    end

    subconfig.vm.provision "windoze", type: "ansible", compatibility_mode: "2.0",
      raw_arguments: ["--diff"], playbook: "extensions/vagrant/windoze.yml"
    subconfig.vm.provision "install zabbix-agent", type: "ansible", compatibility_mode: "2.0",
      force_remote_user: false,
      raw_arguments: ["--diff"], playbook: "molecule/zabbix_agent_tests/common/playbooks/converge.yml",
      extra_vars: {
        zabbix_manage_repo: false,
        zabbix_agent_hostname: "zabbix-agent-win2k25.vagrant.local",
        zabbix_agent_server: "zabbix-aio.vagrant.local,zabbix-server.vagrant.local,zabbix-proxy.vagrant.local",
        zabbix_host_groups: [ "Virtual machines" ],
        zabbix_agent_link_templates: [ "Windows by Zabbix agent" ],
        #zabbix_agent_monitored_by: "proxy",
        #zabbix_agent_proxy: "zabbix-proxy.vagrant.local"
        zabbix_api_create_hosts: true,
        zabbix_api_server_host: "zabbix-aio.vagrant.local",
        ansible_zabbix_url_path: "",
        #zabbix_http_proxy: "http://squid_zbx_user:squid_zbx_pass@zabbix-integrations.vagrant.local:3128",
        #zabbix_https_proxy: "http://squid_zbx_user:squid_zbx_pass@zabbix-integrations.vagrant.local:3128",
      }
  end

  config.vm.define "zabbix-integrations" do |subconfig|
    subconfig.vm.hostname = "zabbix-integrations.vagrant.local"

    subconfig.vm.box = "almalinux/9"
    #subconfig.vm.box = "almalinux/8"

    subconfig.vm.provider "libvirt" do |lv|
      lv.loader = loader_for_box(subconfig.vm.box)
    end

    # Testing proxy that requires auth;
    #
    # export https_proxy=http://zabbix-integrations.vagrant.local:3128
    # curl -v --proxy-header 'Proxy-Authorization: Basic c3F1aWRfemJ4X3VzZXI6c3F1aWRfemJ4X3Bhc3M='
    subconfig.vm.provision "squid", type: "ansible", compatibility_mode: "2.0",
      raw_arguments: ["--diff"], playbook: "extensions/vagrant/squid.yml"
  end
end
