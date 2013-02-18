#!/usr/bin/env bash

wget -N --quiet https://raw.github.com/pierot/server-installer/master/lib.sh; . ./lib.sh

_redirect_stdout 'nginx-passenger'
_check_root

###############################################################################

nginx_version="1.2.7"
nginx_dir='/opt/nginx'

###############################################################################

_usage() {
  _print "

Usage:              base.sh -h [-n '1.2.7' -d '/opt/nginx']

Remote Usage:       bash <( curl -s https://raw.github.com/pierot/server-installer/master/base.sh ) [-n '1.2.7' -d '/opt/nginx']

Options:
 
  -h                Show this message
  -d '/opt/nginx'   Sets nginx install dir
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
    d)
      nginx_dir=$OPTARG
      ;;
    n)
      nginx_version=$OPTARG
      ;;
    *)
      _error "Invalid option received"

      _usage

      exit 0
      ;;
  esac 
done

###############################################################################

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

  rvm wrapper 1.9.3@global passenger

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
  gzip_config="gzip            on;\ngzip_comp_level 3;\ngzip_types      text/plain application/xml text/javascript text/css application/json application/x-javascript text/html;\ngzip_disable    \"msie6\";"

  _add_nginx_config "http {" "$sites_enabled_config"
  _add_nginx_config "http {" "http {\nserver_tokens off;"

  _add_nginx_config "\#gzip  on;" "$gzip_config"

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
  _system_installs_install 'php5-curl php5-gd php-pear php5-imagick php5-imap php5-mcrypt php5-sqlite'

  sudo /etc/init.d/php5-fpm start
}

_setup_www() {
	_log "Setup www directories"

  sudo mkdir -p /srv
  sudo mkdir -p /srv/www
  sudo mkdir -p /srv/logs
}

###############################################################################

_passenger_nginx $nginx_version
_php

_setup_www

_note_installation "nginx-passenger"
