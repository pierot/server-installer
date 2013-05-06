#!/usr/bin/env bash

wget -N --quiet https://raw.github.com/pierot/server-installer/master/lib.sh; . ./lib.sh

###############################################################################

nginx_dir='/opt/nginx'
install_name='noort_be'

###############################################################################

_redirect_stdout $install_name
_check_root
_print_h1 $install_name

###############################################################################

_usage() {
  _print "

Usage:              $install_name.sh -d ['/opt/nginx']

Remote Usage:       bash <( curl -s https://raw.github.com/pierot/server-installer/master/$install_name.sh ) [-d '/opt/nginx']

Options:

  -h                Show this message
  -d '/opt/nginx'   Sets nginx install dir
  "

  exit 0
}

###############################################################################

while getopts :hs:d: opt; do
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
	_print_h2 "Setup noort.be"

  sudo mkdir -p /srv/www/noort.be/public

  git clone git://github.com/pierot/noort.be.git /srv/www/noort.be/public/

  sudo touch $nginx_dir"/sites-available/noort.be"
  sudo cat > $nginx_dir"/sites-available/noort.be" <<EOS
server {
  listen 80;
  listen [::]:80;

  server_name www.noort.be;

  rewrite ^ http://noort.be$uri permanent;
}

server {
  listen 80;
  listen [::]:80;

  server_name noort.be;

  access_print /srv/logs/noort.be.access.log;
  error_print /srv/logs/noort.be.error.log;

  location / {
    root /srv/www/noort.be/public/;
    index  index.html index.php;
  }
}
EOS

  sudo ln -s $nginx_dir"/sites-available/noort.be" $nginx_dir"/sites-enabled/noort.be"

  _print "Reload nginx"

  sudo /etc/init.d/nginx reload
}

_setup_site() {
	_print_h2 "Setup $1"

  sudo mkdir -p "/srv/www/$1/public"

  sudo touch $nginx_dir"/sites-available/$1"
  sudo cat > $nginx_dir"/sites-available/$1" <<EOS
server {
  listen 80;
  listen [::]:80;

  server_name $1;

  access_print /srv/logs/$1.access.log;
  error_print /srv/logs/$1.error.log;

  location / {
    root /srv/www/$1/public/;
    index  index.html index.php;
  }
}
EOS

  sudo ln -s $nginx_dir"/sites-available/$1" $nginx_dir"/sites-enabled/$1"

  _print "Reload nginx"

  sudo /etc/init.d/nginx reload
}

###############################################################################

_setup_noort
_setup_site 'dev.noort.be'

_note_installation "noort_be"
