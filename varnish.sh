#!/usr/bin/env bash

wget -N --quiet https://raw.github.com/pierot/server-installer/master/lib.sh; . ./lib.sh

###############################################################################

_install_varnish() {
  _log "Install Varnish"

  sudo curl http://repo.varnish-cache.org/debian/GPG-key.txt | apt-key add -

  sudo echo "deb http://repo.varnish-cache.org/ubuntu/ lucid varnish-3.0" >> /etc/apt/sources.list

  sudo apt-get update

  _system_installs_install "varnish"
}

_configure_varnish() {
  _log "Configure Varnish"

  sudo mv /etc/varnish/default.vcl /etc/varnish/default.vcl.bak

  sudo cat > /etc/varnish/default.vcl <<EOF
backend default { 
  .host = "127.0.0.1"; 
  .port = "8000"; 
  .first_byte_timeout = 5s; 
  .connect_timeout = 1s; 
  .between_bytes_timeout = 2s; 
} 
EOF

  sudo service varnish restart
}

_link_munin_varnish() {
  # https://github.com/basiszwo/munin-varnish

  _log "Add munin plugins for requests, status and memory"

  cd /usr/share/munin/plugins

  if [ -d "/usr/share/munin/plugins/munin-varnish" ]; then
    sudo rm -rf /usr/share/munin/plugins/munin-varnish
  fi

  sudo git clone git://github.com/basiszwo/munin-varnish.git
  sudo chmod a+x /usr/share/munin/plugins/munin-varnish/varnish_*
  
  sudo rm -f /etc/munin/plugins/varnish_*
  sudo ln -s /usr/share/munin/plugins/munin-varnish/varnish_* /etc/munin/plugins/

  _log "***** Edit /etc/munin/plugin-conf.d/munin-node"
 
  munin_env="\n
[varnish*]\n
user root\n
"

  echo -e $munin_env | sudo tee -a /etc/munin/plugin-conf.d/munin-node > /dev/null
  
  _log "***** Restart munin"

  sudo service munin-node restart
}

_final_info() {
  _print "
Configuration suggestion for /etc/default/varnish.
This will run Varnish on port 80.

DAEMON_OPTS=\"-a :80 \\\n
             -T localhost:6082 \\\n
             -f /etc/varnish/default.vcl \\\n
             -S /etc/varnish/secret \\\n
             -s malloc,256m\"

Varnish is set up to forward all traffic to port 8000 on 127.0.0.1
Setup your sites to listen for 127.0.0.1:8000

Files to remember: \`/etc/default/varnish\` and \`/etc/varnish/default.vcl\`
"
}

_install_varnish
_configure_varnish

_link_munin_varnish

_final_info
