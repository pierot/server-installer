#!/usr/bin/env bash

wget -N --quiet https://raw.github.com/pierot/server-installer/master/lib.sh; . ./lib.sh

_check_root

###############################################################################

nginx_dir='/opt/nginx'

###############################################################################

_usage() {
  _print "

Usage:              munin.sh -d ['/opt/nginx']

Remote Usage:       bash <( curl -s https://raw.github.com/pierot/server-installer/master/munin.sh ) [-d '/opt/nginx']

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

#   _log "***** Add munin-node-config to /etc/munin/munin-node.conf"
# 
#   munin_node_config="
# allow ^127\.0\.0\.1$\n
# host 127.0.0.1\n
# "
# 
#   echo -e $munin_node_config | sudo tee -a /etc/munin/munin-node.conf > /dev/null

  # Find and replace
  _log "***** Add nginx-stub-status to "$nginx_dir"/conf/nginx.conf"

  stub_status_config="

        location \/nginx_status {
          stub_status on;
          access_log off;
          allow 127.0.0.1;
          deny all;
        }

  "

  search_string="s/[^#]server {/server {$stub_status_config/"

  sudo perl -pi -e "$search_string" $nginx_dir"/conf/nginx.conf"
  
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

  sudo touch $nginx_dir"/sites-available/stats.noort.be"
  sudo cat > $nginx_dir"/sites-available/stats.noort.be" <<EOS
server {
  listen 80;
  server_name stats.noort.be s.noort.be;

  access_log /srv/logs/stats.noort.be.access.log;
  error_log /srv/logs/stats.noort.be.error.log;

  # pass the PHP scripts to FastCGI server
  location ~ \.php$ {
    root           html;
    fastcgi_pass   127.0.0.1:9000;
    fastcgi_index  index.php;
    fastcgi_param  SCRIPT_FILENAME  /var/cache/munin/www\$fastcgi_script_name;
    include        fastcgi_params;
  }

  location / {
    root /var/cache/munin/www/;
    index  index.html index.php;
  }
}
EOS

  sudo ln -s $nginx_dir"/sites-available/stats.noort.be" $nginx_dir"/sites-enabled/stats.noort.be"
  
  _log "***** Restart nginx"

  sudo /etc/init.d/nginx reload
}

###############################################################################

_munin
