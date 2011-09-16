#!/usr/bin/env bash

wget -N --quiet https://raw.github.com/pierot/server-installer/master/lib.sh; . ./lib.sh

###############################################################################

nginx_dir='/opt/nginx'

###############################################################################

_usage() {
  _print "

Usage:              noort_be.sh -d ['/opt/nginx']

Remote Usage:       bash <( curl -s https://raw.github.com/pierot/server-installer/master/noort_be.sh ) [-d '/opt/nginx']

Options:
 
  -h                Show this message
  -d '/opt/nginx'   Sets nginx install dir
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
    *)
      _error "Invalid option received"

      _usage

      exit 0
      ;;
  esac 
done

###############################################################################

_setup_noort() {
	_log "Setup noort.be"

  sudo mkdir -p /srv/www/noort.be/public

  git clone git://github.com/pierot/noort.be.git /srv/www/noort.be/public/

  sudo touch $nginx_dir"/sites-available/noort.be"
  sudo cat > $nginx_dir"/sites-available/noort.be" <<EOS
server {
  listen 80;
  server_name noort.be www.noort.be;

  access_log /srv/logs/noort.be.access.log;
  error_log /srv/logs/noort.be.error.log;

  location / {
    root /srv/www/noort.be/public/;
    index  index.html index.php;
  }
}
EOS

  sudo ln -s $nginx_dir"/sites-available/noort.be" $nginx_dir"/sites-enabled/noort.be"
  
  _log "***** Restart nginx"

  sudo /etc/init.d/nginx reload
}

###############################################################################

_setup_noort
