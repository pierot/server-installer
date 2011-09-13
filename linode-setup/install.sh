#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

server_name=
nginx_version="1.0.6"
env_var="production"
pass=

temp_dir='/tmp/src'

###############################################################################
# HELPER FUNCTIONS

_log() {
  # echo -e $COL_BLUE"\n$1 ************************************\n"$COL_RESET
  _print "$1 ******************************************"
}

_print() {
	COL_BLUE="\x1b[34;01m"
	COL_RESET="\x1b[39;49;00m"

  printf $COL_BLUE"\n$1\n"$COL_RESET
}

_usage() {
  _print "

Usage:              install.sh -h 'server_name' -p 'password' [-n '1.0.6' -e 'production']

Remote Usage:       bash <( curl https://raw.github.com/pierot/server-installer/master/linode-setup/install.sh ) -s 'tortuga' -p 'test' [-n '1.0.6' -e 'production']

Options:
 
  -h                Show this message
  -s 'server_name'  Set server name
  -p 'environment'  Set RACK / RAILS environment variable
  -n '1.0.6'        nginx version number
  -p 'password'     MySQL password
  "

  exit 0
} 

###############################################################################

while getopts :hs:n:e:p: opt; do 
  case $opt in
    h)
      _usage
      ;;
    s)
      server_name=$OPTARG
      ;;
    n)
      nginx_version=$OPTARG
      ;;
    e)
      env_var=$OPTARG
      ;;
    p)
      pass=$OPTARG
      ;;
    *)
      _log "Invalid option received"

      _usage

      exit 0
      ;;
  esac 
done

if [ -z $server_name ]; then
  _log "-s 'server_name' not given."

  exit 0
fi

if [ -z $pass ]; then
  _log "-p 'password' not given."

  exit 0
fi

###############################################################################
# HELPER FUNCTION

_system_installs_install() {
	[[ -z "$1" ]] && return 1

  _log "***** Install $1"

  sudo DEBIAN_FRONTEND=noninteractive apt-get -qq -y -f install $1
}

###############################################################################

_prepare() {
  _log "Prepare"

  mkdir -p $temp_dir
}

_hostname() {
	[[ -z "$1" ]] && return 1

	_log "Setting hostname to $1"

  sudo sh -c "echo $1 > /etc/hostname"
	sudo sh -c "echo '127.0.0.1 $1.local $1 localhost' >> /etc/hosts"
	sudo hostname -F /etc/hostname
}

_system_installs() {
	_log "System wide installs"

  sudo apt-get -qq update
  sudo apt-get -qq upgrade

  _system_installs_install 'aptitude'

  sudo aptitude -y full-upgrade
  
  _system_installs_install 'build-essential bison openssl libreadline5 libreadline-dev curl git-core zlib1g make'
  _system_installs_install 'zlib1g-dev libssl-dev vim libsqlite3-0 libsqlite3-dev sqlite3 libcurl4-openssl-dev gcc'
  _system_installs_install 'libreadline-dev libxslt-dev libxml2-dev subversion autoconf gettext'
  _system_installs_install 'libmagickwand-dev imagemagick'
}

_system_timezone() {
	_log "System timezone"

  sudo cp /usr/share/zoneinfo/Europe/Brussels /etc/localtime

  _system_installs_install 'ntp'

  sudo ntpdate ntp.ubuntu.com
}

_setup_users() {
	_log "Setup user settings + security"

  _log "***** Secure shared memory"

  sudo sh -c 'echo "tmpfs     /dev/shm     tmpfs     defaults,noexec,nosuid     0     0" >> /etc/fstab'

  # Do not permit source routing of incoming packets
  sudo sysctl -w net.ipv4.conf.all.accept_source_route=0
  sudo sysctl -w net.ipv4.conf.default.accept_source_route=0
}

_postfix_loopback_only() {
	_log "Install postfix"

  # Installs postfix and configure to listen only on the local interface. Also allows for local mail delivery
  
  echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
  echo "postfix postfix/mailname string localhost" | debconf-set-selections
  echo "postfix postfix/destinations string localhost.localdomain, localhost" | debconf-set-selections

  _system_installs_install 'postfix'

  sudo /usr/sbin/postconf -e "inet_interfaces = loopback-only"
  
  sudo touch /tmp/restart-postfix
}

_rvm() {
	_log "Installing RVM System wide"

  sudo su -c bash < <( curl -L https://raw.github.com/wayneeseguin/rvm/1.3.0/contrib/install-system-wide )

  _log "***** Add sourcing of rvm"

  search_string='s/\[ -z \"\$PS1\" \] \&\& return/if [[ -n \"\$PS1\" ]]; then/g'

  sudo perl -pi -e "$search_string" ~/.bashrc 
  
  if [ -f /etc/skel/.bashrc ]; then
    sudo perl -pi -e "$search_string" /etc/skel/.bashrc
  else
  	ps_string='[ -z "$PS1" ] && return'
    sudo sh -c "$ps_string > /etc/skel/.bashrc"
  fi

  rvm_bin_source="fi\n
  if groups | grep -q rvm ; then\n
    source '/usr/local/lib/rvm'\n
  fi\n
  "

  echo -e $rvm_bin_source | sudo tee -a ~/.bashrc > /dev/null
  echo -e $rvm_bin_source | sudo tee -a /etc/skel/.bashrc > /dev/null

  source /usr/local/lib/rvm

  _log "***** Reload shell"
  
  rvm reload

  _log "***** Install Readline package shell"

  rvm pkg install readline

  _log "***** Installing Ruby 1.8.7"
   
  rvm install 1.8.7

  _log "***** Installing Ruby 1.9.2"

  rvm install 1.9.2
  rvm use 1.9.2 --default
  
  _log "***** Add bundler to global.gems"

  sudo sh -c 'echo "bundler" >> /usr/local/rvm/gemsets/global.gems'
}

_gem_config() {
	_log "Updating Rubygems"

  gem update --system

	_log "***** Adding no-rdoc and no-ri rules to gemrc"

	gemrc_settings="
---\n
:sources:\n
- http://gems.rubyforge.org\n
- http://gems.github.com\n
gem: --no-ri --no-rdoc\n
"

  sudo touch /etc/skel/.gemrc
  sudo touch ~/.gemrc

  echo -e $gemrc_settings | sudo tee -a /etc/skel/.gemrc > /dev/null
  echo -e $gemrc_settings | sudo tee -a ~/.gemrc > /dev/null

  # Bundler
	_log "***** Installing Bundler"

  rvm gemset use global
  
  gem install bundler

  rvm gemset clear
}

_passenger_nginx() {
	_log "Install Passenger with nginx"

  _log "***** Download nginx source $1"
  
  cd $temp_dir
  sudo wget "http://nginx.org/download/nginx-$1.tar.gz"
  sudo tar -xzvf "nginx-$1.tar.gz" > /dev/null

  _log "***** Install passenger gem"

  gem install passenger

  _log "***** Install passenger nginx module"

  # rvmsudo 
  passenger-install-nginx-module --nginx-source-dir="$temp_dir/nginx-$1" --prefix="/opt/nginx" --auto --extra-configure-flags="--with-http_stub_status_module"

  _log "***** Create global wrapper 'passenger'"

  rvm wrapper 1.9.2@global passenger

  _log "***** Init nginx start-up script"

  curl -L -s https://raw.github.com/gist/1187950/c8825bf2e9c9243201e4e0e974626501592ce81e/nginx-init-d > ~/nginx
  sudo mv ~/nginx /etc/init.d/nginx
  sudo chmod +x /etc/init.d/nginx
  sudo /usr/sbin/update-rc.d -f nginx defaults

  _log "***** Adding sites-folders"

  sudo mkdir -p /opt/nginx/sites-available
  sudo mkdir -p /opt/nginx/sites-enabled

  _log "***** Add sites-enabled config"

  sites_enabled_config="
      include \/opt\/nginx\/sites-enabled\/*;
  "

  search_string="s/http {/http {$sites_enabled_config/"

  sudo perl -pi -e "$search_string" /opt/nginx/conf/nginx.conf

  _log "***** Add nginx gzip level"

  gzip_level="
gzip  on;
gzip_comp_level 2;
gzip_disable \"msie6\";"
  
  search_string="s/\#gzip  on;/$gzip_lebel/"

  sudo perl -pi -e "$search_string" /opt/nginx/conf/nginx.conf
  
  _log "***** Add nginx worker_processes"

  worker_processes="worker_processes  3;"

  search_string="s/worker_processes  1;/$worker_processes/"

  sudo perl -pi -e "$search_string" /opt/nginx/conf/nginx.conf

  _log "***** Verify nginx status"

  sudo /etc/init.d/nginx start
  sudo /etc/init.d/nginx stop
  sudo /etc/init.d/nginx start
}

_php() {
	_log "Install PHP"

  _system_installs_install 'php5-fpm php5-common'

  sudo /etc/init.d/php5-fpm start
}

_create_nginx_site() {
	_log "Create site $1 at $3/"

  sudo touch "/opt/nginx/sites-available/$1"
  sudo cat > "/opt/nginx/sites-available/$1" <<EOS
server {
  listen 80;
  server_name $2;

  access_log /srv/logs/$1.access.log;
  error_log /srv/logs/$1.error.log;

  # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
  location ~ \.php$ {
    root           html;
    fastcgi_pass   127.0.0.1:9000;
    fastcgi_index  index.php;
    fastcgi_param  SCRIPT_FILENAME  $3\$fastcgi_script_name;
    include        fastcgi_params;
  }

  location / {
    root $3/;
    index  index.html index.php;
  }
}
EOS

  sudo ln -s "/opt/nginx/sites-available/$1" "/opt/nginx/sites-enabled/$1"
  
  _log "***** Restart nginx"

  sudo /etc/init.d/nginx reload
}

_setup_www() {
	_log "Setup www directories"

  sudo mkdir -p /srv
  sudo mkdir -p /srv/www
  sudo mkdir -p /srv/logs
}

_setup_noort() {
	_log "Setup noort.be"

  sudo mkdir -p /srv/www/noort.be/public

  git clone git://github.com/pierot/noort.be.git /srv/www/noort.be/public/

  _create_nginx_site "noort.be" "noort.be www.noort.be" "/srv/www/noort.be/public"
}

_mysql_install() {
	_log "Install MySQL"

  if [ ! -n "$1" ]; then
    _log "mysql_install() requires the root pass as its first argument"
    return 1;
  fi

  echo "mysql-server-5.1 mysql-server/root_password password $1" | debconf-set-selections
  echo "mysql-server-5.1 mysql-server/root_password_again password $1" | debconf-set-selections

  _system_installs_install 'mysql-server mysql-client libmysqlclient15-dev libmysql-ruby'

	_log "***** Sleeping while MySQL starts up for the first time..."

  sleep 5

  gem install mysql -- --with-mysql-dir=/usr/bin --with-mysql-lib=/usr/lib/mysql --with-mysql-include=/usr/include/mysql
}

_mysql_tune() {
  _log "MySQL Tune: $1"

  # Tunes MySQL's memory usage to utilize the percentage of memory you specify, defaulting to 40%
  # $1 - the percent of system memory to allocate towards MySQL

  if [ ! -n "$1" ];
    then PERCENT=40
    else PERCENT="$1"
  fi

  sudo sed -i -e 's/^#skip-innodb/skip-innodb/' /etc/mysql/my.cnf # disable innodb - saves about 100M

  MEM=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo) # how much memory in MB this system has
  MYMEM=$((MEM*PERCENT/100)) # how much memory we'd like to tune mysql with
  MYMEMCHUNKS=$((MYMEM/4)) # how many 4MB chunks we have to play with
  
  # mysql config options we want to set to the percentages in the second list, respectively
  OPTLIST=(key_buffer sort_buffer_size read_buffer_size read_rnd_buffer_size myisam_sort_buffer_size query_cache_size)
  DISTLIST=(75 1 1 1 5 15)

  for opt in ${OPTLIST[@]}; do
    sudo sed -i -e "/\[mysqld\]/,/\[.*\]/s/^$opt/#$opt/" /etc/mysql/my.cnf
  done

  for i in ${!OPTLIST[*]}; do
    val=$(echo | awk "{print int((${DISTLIST[$i]} * $MYMEMCHUNKS/100))*4}")
    
    if [ $val -lt 4 ]
      then val=4
    fi

    config="${config}\n${OPTLIST[$i]} = ${val}M"
  done

  sudo sed -i -e "s/\(\[mysqld\]\)/\1\n$config\n/" /etc/mysql/my.cnf

  sudo touch /tmp/restart-mysql
}

_munin() {
  # https://github.com/jnstq/munin-nginx-ubuntu
  _log "Install Munin"

  _system_installs_install 'munin munin-node'

  _log "***** Add munin-config to /etc/munin/munin.conf"

  munin_config="\n
[noort.be]\n
\taddress 127.0.0.1\n
\tuse_node_name yes\n
"

  echo -e $munin_config | sudo tee -a /etc/munin/munin.conf > /dev/null

  _log "***** Add munin-node-config to /etc/munin/munin-node.conf"

  munin_node_config="
allow ^127\.0\.0\.1$\n
host 127.0.0.1\n
"

  echo -e $munin_node_config | sudo tee -a /etc/munin/munin-node.conf > /dev/null

  # Find and replace
  _log "***** Add nginx-stub-status to /opt/nginx/conf/nginx.conf"

  stub_status_config="

        location \/nginx_status {
          stub_status on;
          access_log off;
          allow 127.0.0.1;
          deny all;
        }

  "

  search_string="s/[^#]server {/server {$stub_status_config/"

  sudo perl -pi -e "$search_string" /opt/nginx/conf/nginx.conf
  
  _log "***** Add munin plugins for requests, status and memory"

  cd /usr/share/munin/plugins
  sudo wget -q -O nginx_request http://exchange.munin-monitoring.org/plugins/nginx_request/version/2/download
  sudo wget -q -O nginx_status http://exchange.munin-monitoring.org/plugins/nginx_status/version/3/download
  sudo wget -q -O nginx_memory http://exchange.munin-monitoring.org/plugins/nginx_memory/version/1/download  

  sudo chmod +x nginx_request
  sudo chmod +x nginx_status
  sudo chmod +x nginx_memory    

  sudo ln -s /usr/share/munin/plugins/nginx_request /etc/munin/plugins/nginx_request
  sudo ln -s /usr/share/munin/plugins/nginx_status /etc/munin/plugins/nginx_status
  sudo ln -s /usr/share/munin/plugins/nginx_memory /etc/munin/plugins/nginx_memory     

  _log "***** Edit /etc/munin/plugin-conf.d/munin-node"
 
  munin_env="\n
[nginx*]\n
env.url http://localhost/nginx_status\n
"

  echo -e $munin_env | sudo tee -a /etc/munin/plugin-conf.d/munin-node > /dev/null
  
  _log "***** Restart munin"

  sudo service munin-node restart

  _log "***** Add nginx virtual host for munin-stats"

  _create_nginx_site "stats.noort.be" "stats.noort.be s.noort.be" "/var/cache/munin/www"
}

_env_variables() {
  sudo cat > /etc/environment <<EOF
RAILS_ENV="$1"
RACK_ENV="$1"
EOF
}

_the_end() {
	_log "Finishing"

  # MySQL
  # echo "Please run mysql_secure_installation in order to configure your mysql installation"

  _log "***** Cleaning up"
  sudo apt-get -qq autoremove
}

###############################################################################

_hostname $server_name
_system_installs
_system_timezone
_setup_users

_postfix_loopback_only

_rvm
_gem_config
_mysql_install $pass && _mysql_tune 90
_passenger_nginx $nginx_version
_php

_setup_www
_setup_noort

_munin

_env_variables $env_var
_the_end

