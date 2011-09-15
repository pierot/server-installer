#!/usr/bin/env bash

wget -N --quiet https://raw.github.com/pierot/server-installer/master/linode-setup/lib.sh; . ./lib.sh

###############################################################################

curl http://repo.varnish-cache.org/debian/GPG-key.txt | apt-key add -

echo "deb http://repo.varnish-cache.org/ubuntu/ lucid varnish-3.0" >> /etc/apt/sources.list

apt-get update

apt-get install varnish

# configure nginx site 
#   with no server_name
#   at port 8080


