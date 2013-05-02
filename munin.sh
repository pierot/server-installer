#!/usr/bin/env bash

wget -N --quiet https://raw.github.com/pierot/server-installer/master/lib.sh; . ./lib.sh

###############################################################################

install_name='munin'
nginx_dir='/opt/nginx'

###############################################################################

_redirect_stdout $install_name
_check_root
_print_h1 $install_name

###############################################################################

_usage() {
  _print "

Usage:              $install_name -d ['/opt/nginx']

Remote Usage:       bash <( curl -s https://raw.github.com/pierot/server-installer/master/$install_name ) [-d '/opt/nginx']

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
  _system_installs_install 'munin munin-node spawn-fcgi'

  _print_h2 "Add munin-config to /etc/munin/munin.conf"

  munin_config="\n
[noort.be]\n
\taddress 127.0.0.1\n
\tuse_node_name yes\n
"

  echo -e $munin_config | sudo tee -a /etc/munin/munin.conf > /dev/null

  _print "Add strategies to /etc/munin/munin-node.conf"

  sudo perl -pi -e "s/#html_strategy cgi/html_strategy cgi/" "/etc/munin/munin.conf"
  sudo perl -pi -e "s/#graph_strategy cgi/graph_strategy cgi/" "/etc/munin/munin.conf"

  # Find and replace
  _print "Add nginx-stub-status to "$nginx_dir"/conf/nginx.conf"

  stub_status_config="

        location \/nginx_status {
          stub_status on;
          access_print off;
          allow 127.0.0.1;
          deny all;
        }

  "

  search_string="s/[^#]server {/server {$stub_status_config/"

  sudo perl -pi -e "$search_string" $nginx_dir"/conf/nginx.conf"

  _print "Restart munin"

  sudo service munin-node restart

  _print "Setup permissions for log files"

  sudo chmod 0777 /var/log/munin/*.log

  _print "Configure graphing cgi-bins"

  spawn-fcgi -s /var/run/munin/fastcgi-html.sock -U nobody -u munin -g munin /usr/lib/cgi-bin/munin-cgi-html
  spawn-fcgi -s /var/run/munin/fastcgi-graph.sock -U nobody -u munin -g munin /usr/lib/cgi-bin/munin-cgi-graph

  _print "Add nginx virtual host for munin-stats"

  sudo touch $nginx_dir"/sites-available/stats.noort.be"
  sudo cat > $nginx_dir"/sites-available/stats.noort.be" <<EOS
server {
  listen        80;
  server_name   stats.noort.be;

  access_print    /srv/logs/stats.noort.be.access.log;
  error_print     /srv/logs/stats.noort.be.error.log;

  # pass the PHP scripts to FastCGI server
  location ~ \.php$ {
    root           html;
    fastcgi_split_path_info ^(.+\.php)(/.+)\$;
    fastcgi_pass unix:/var/run/php5-fpm.sock;
    fastcgi_index index.php;
    fastcgi_param  SCRIPT_FILENAME  /var/cache/munin/www$fastcgi_script_name;
    include fastcgi_params;
  }

  location / {
    auth_basic            "Restricted";
    auth_basic_user_file  /srv/www/htpasswd;

    fastcgi_split_path_info ^(/)(.*);
    fastcgi_param PATH_INFO \$fastcgi_path_info;
    fastcgi_pass  unix:/var/run/munin/fastcgi-html.sock;
    include       fastcgi_params;
  }

  location /static/ {
    alias         /etc/munin/static/;
  }

  location ^~ /cgi-bin/munin-cgi-graph/ {
    access_print    off;
    fastcgi_split_path_info ^(/cgi-bin/munin-cgi-graph)(.*);
    fastcgi_param PATH_INFO \$fastcgi_path_info;
    fastcgi_pass  unix:/var/run/munin/fastcgi-graph.sock;
    include       fastcgi_params;
  }
}
EOS

  sudo ln -s $nginx_dir"/sites-available/stats.noort.be" $nginx_dir"/sites-enabled/stats.noort.be"

  _print "Restart nginx"

  sudo service nginx reload
}

###############################################################################

_munin

_note_installation "munin"
