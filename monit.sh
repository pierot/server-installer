#!/usr/bin/env bash

wget -N --quiet https://raw.github.com/pierot/server-installer/master/lib.sh; . ./lib.sh

_redirect_stdout 'monit'
_check_root

###############################################################################

server_name='tortuga'
nginx_dir='/opt/nginx'

###############################################################################

_usage() {
  _print "

Usage:              monit.sh [-n 'tortuga']

Remote Usage:       bash <( curl -s https://raw.github.com/pierot/server-installer/master/monit.sh ) [-n 'tortuga'] [-d '/opt/nginx']

Options:
 
  -h                Show this message
  -n 'tortuga'      Sets server name
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
    n)
      server_name=$OPTARG
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

_monit() {
  _log "Install Monit"

  _system_installs_install 'monit'

  _log "***** Add monit-config to /etc/monit/conf.d/"$server_name

  monit_config="\n
# setup\n
set mailserver smtp.gmail.com port 587 # if you want to use Gmail/Google app mail as a sender\n
\tusername \"pieter@noort.be\" password \"haha\"\n
\tusing tlsv1\n
\twith timeout 30 seconds\n
\n\n
set alert pieter@noort.be # set this to recive alerts and notifications\n
\n\n
set httpd port 2812\n
\t# use address localhost # only accept connection from localhost\n
\tallow localhost # allow localhost to connect to the server and\n
\tallow 127.0.0.1 # allow localhost to connect to the server and\n
\tallow 192.168.1.0/255.255.255.0 # allow any host on 192.168.1.* subnet\n
\tallow admin:admin # require user 'admin' with password 'pa$$w0rd'\n
\n\n
set logfile /var/log/monit.log\n
"
  
  echo -e $monit_config > /etc/monit/conf.d/$server_name
  
  _log "***** Restart monit"

  sudo service monit restart

  _log "***** Add nginx virtual host for monit"

  sudo touch $nginx_dir"/sites-available/monit.noort.be"
  sudo cat > $nginx_dir"/sites-available/monit.noort.be" <<EOS
server {
  listen 127.0.0.1:8000;
  server_name monit.noort.be;

  access_log /srv/logs/monit.noort.be.access.log;
  error_log /srv/logs/monit.noort.be.error.log;

  location / {
    proxy_pass http://127.0.0.1:2812;
    proxy_set_header Host \$host;
  }
}
EOS

  sudo ln -s $nginx_dir"/sites-available/monit.noort.be" $nginx_dir"/sites-enabled/monit.noort.be"
  
  _log "***** Reload nginx"

  sudo /etc/init.d/nginx reload

  _log "***** Restart varnish"

  sudo /etc/init.d/varnish restart
}

###############################################################################

_monit
_note_installation "monit"
