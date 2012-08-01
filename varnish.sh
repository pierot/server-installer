#!/usr/bin/env bash

wget -N --quiet https://raw.github.com/pierot/server-installer/master/lib.sh; . ./lib.sh

_redirect_stdout 'varnish'
_check_root

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

  sudo mv /etc/default/varnish /etc/default/varnish.bak

  sudo cat > /etc/default/varnish <<EOF
START=yes
MEMLOCK=82000
NFILES=$(ulimit -n)
INSTANCE=$(uname -n)
DAEMON_OPTS="-a :80 -T localhost:6082 -f /etc/varnish/default.vcl -S /etc/varnish/secret -s malloc,256m"
EOF

  sudo mv /etc/varnish/default.vcl /etc/varnish/default.vcl.bak

  sudo cat > /etc/varnish/default.vcl <<EOF
backend default { 
  .host = "127.0.0.1"; 
  .port = "8000"; 
  .first_byte_timeout = 25s; 
  .connect_timeout = 20s; 
  .between_bytes_timeout = 30s; 
} 

acl purge {
  "localhost";
  "127.0.0.1";
  "noort.be";
}

sub vcl_recv {
  # unset req.http.cookie;

  # Insert the client's ip address into the request header
  if (req.restarts == 0) {
    if (req.http.x-forwarded-for) {
      set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " + client.ip;
    } else {
      set req.http.X-Forwarded-For = client.ip;
    }
  }

  # Don't cache POST, PUT, or DELETE requests
  if (req.request != "GET") {
    return(pass);
  }

  # Strip cookies from static content
  if (req.request == "GET" && req.url ~ "\.(png|gif|jpg|swf|css|js)$") {
    unset req.http.cookie;
  }

  if (req.request == "PURGE") {
    if (!client.ip ~ purge) {
      error 405 "not allowed.";
    }

    return(lookup);
  }
 
  return(lookup);
}

sub vcl_hit {
  if (req.request == "PURGE") {
    purge;

    error 200 "Purged.";
  }
}

sub vcl_miss {
  if (req.request == "PURGE") {
    purge;

    error 200 "Purged.";
  }
}

sub vcl_deliver {
  # The below provides custom headers to indicate whether the response came from varnish cache or directly from the app.
  if (obj.hits > 0) {
    set resp.http.X-Varnish-Cache = "HIT";
  } else {
    set resp.http.X-Varnish-Cache = "MISS";
  }
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
  _print "Varnish is set up to forward all traffic to port 8000 on 127.0.0.1
Setup your sites to listen for 127.0.0.1:8000

Files to remember: \`/etc/default/varnish\` and \`/etc/varnish/default.vcl\`
"
}

_install_varnish
_configure_varnish

_link_munin_varnish

_final_info
_note_installation "varnish"
