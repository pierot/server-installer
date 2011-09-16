#!/usr/bin/env bash

wget -N --quiet https://raw.github.com/pierot/server-installer/master/lib.sh; . ./lib.sh

###############################################################################

server_name=
nginx_version="1.0.6"
env_var="production"
pass=
nginx_dir='/opt/nginx'

###############################################################################

_usage() {
  _print "

Usage:              install.sh -h 'server_name' [-n '1.0.6' -e 'production']

Remote Usage:       bash <( curl -s https://raw.github.com/pierot/server-installer/master/install.sh ) -s 'tortuga' [-n '1.0.6' -e 'production']

Options:
 
  -h                Show this message
  -s 'server_name'  Set server name
  -d '/opt/nginx'   Sets nginx install dir
  -e 'environment'  Set RACK / RAILS environment variable
  -n '1.0.6'        nginx version number
  "

  exit 0
} 

###############################################################################

while getopts :hs:n:d:e: opt; do 
  case $opt in
    h)
      _usage
      ;;
    s)
      server_name=$OPTARG
      ;;
    d)
      nginx_dir=$OPTARG
      ;;
    n)
      nginx_version=$OPTARG
      ;;
    e)
      env_var=$OPTARG
      ;;
    *)
      _error "Invalid option received"

      _usage

      exit 0
      ;;
  esac 
done

if [ -z $server_name ]; then
  _error "-s 'server_name' not given."

  exit 0
fi

###############################################################################

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
  _system_installs_install 'chkconfig lsof'
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

_rvm() {
	_log "Installing RVM System wide"

  _log "***** Execute install-system-wide for rvm"

  sudo su -c bash < <( curl -L https://raw.github.com/wayneeseguin/rvm/1.3.0/contrib/install-system-wide )

  _log "***** Add sourcing of rvm in ~/.bashrc"

  ps_string='[ -z "$PS1" ] && return'
  search_string='s/\[ -z \"\$PS1\" \] \&\& return/if [[ -n \"\$PS1\" ]]; then/g'
  rvm_bin_source="fi\n
  if groups | grep -q rvm ; then\n
    source '/usr/local/lib/rvm'\n
  fi\n
  "

  if [ -f ~/.bashrc ]; then
    sudo perl -pi -e "$search_string" ~/.bashrc 

    echo -e $rvm_bin_source | sudo tee -a ~/.bashrc > /dev/null
  fi
  
  _log "***** Add sourcing of rvm in /etc/skel/.bashrc"
  
  if [ -f /etc/skel/.bashrc ]; then
    sudo perl -pi -e "$search_string" /etc/skel/.bashrc
  else
    sudo sh -c "$ps_string > /etc/skel/.bashrc"
  fi

  echo -e $rvm_bin_source | sudo tee -a /etc/skel/.bashrc > /dev/null

  _log "***** Now source!"

  source /usr/local/lib/rvm

  _log "***** Add bundler to global.gems"

  sudo sh -c 'echo "bundler" >> /usr/local/rvm/gemsets/global.gems'

  _log "***** Reload shell"
  
  rvm reload

  _log "***** Install Readline package shell"

  rvm pkg install readline

  _log "***** Installing Ruby 1.8.7"
   
  rvm install 1.8.7

  _log "***** Installing Ruby 1.9.2 (default)"

  rvm install 1.9.2
  rvm --default use 1.9.2
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

	# _log "***** Installing Bundler"

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
  passenger-install-nginx-module --nginx-source-dir="$temp_dir/nginx-$1" --prefix=$nginx_dir --auto --extra-configure-flags="--with-http_stub_status_module"

  _log "***** Create global wrapper 'passenger'"

  rvm wrapper 1.9.2@global passenger

  _log "***** Init nginx start-up script"

  curl -L -s https://raw.github.com/gist/1187950/c8825bf2e9c9243201e4e0e974626501592ce81e/nginx-init-d > ~/nginx
  sudo mv ~/nginx /etc/init.d/nginx
  sudo chmod +x /etc/init.d/nginx
  sudo /usr/sbin/update-rc.d -f nginx defaults

  _log "***** Adding sites-folders"

  sudo mkdir -p $nginx_dir"/sites-available"
  sudo mkdir -p $nginx_dir"/sites-enabled"

  _log "***** Add nginx config"

  nginx_dir_escaped=`echo $nginx_dir | sed 's/\//\\\\\//g'`

  sites_enabled_config="http {\ninclude $nginx_dir_escaped\/sites-enabled\/*;"
  gzip_level="gzip on;\ngzip_comp_level 2;\ngzip_disable \"msie6\";"

  _add_nginx_config "http {" "$sites_enabled_config"

  _add_nginx_config "\#gzip  on;" "$gzip_level"

  _add_nginx_config "keepalive_timeout  65;" "keepalive_timeout  15;"
  _add_nginx_config "worker_processes  1;" "worker_processes  3;"

  _add_nginx_config "\#tcp_nopush     on;" "tcp_nopush     on;"
  _add_nginx_config "tcp_nodelay        on;" "tcp_nodelay        off;"

  _add_nginx_config "listen       80;" "listen       8888;"
  _add_nginx_config "server_name  localhost;" "\# server_name  localhost;"

  _log "***** Verify nginx status"

  sudo /etc/init.d/nginx start
  sudo /etc/init.d/nginx stop
  sudo /etc/init.d/nginx start
}

_add_nginx_config() {
  sudo perl -pi -e "s/$1/$2/" $nginx_dir"/conf/nginx.conf"
}

_php() {
	_log "Install PHP"

  _system_installs_install 'php5-fpm php5-common'

  sudo /etc/init.d/php5-fpm start
}

_setup_www() {
	_log "Setup www directories"

  sudo mkdir -p /srv
  sudo mkdir -p /srv/www
  sudo mkdir -p /srv/logs
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

_rvm
_gem_config

_passenger_nginx $nginx_version
_php

_setup_www

_env_variables $env_var
_the_end

