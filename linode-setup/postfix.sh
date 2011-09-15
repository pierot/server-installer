#!/usr/bin/env bash

wget -N --quiet https://raw.github.com/pierot/server-installer/master/linode-setup/lib.sh; . ./lib.sh

###############################################################################

_postfix_loopback_only() {
	_log "Install postfix"

  # Installs postfix and configure to listen only on the local interface. Also allows for local mail delivery
  
  echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
  echo "postfix postfix/mailname string localhost" | debconf-set-selections
  echo "postfix postfix/destinations string localhost.localdomain, localhost" | debconf-set-selections

  _system_installs_install 'postfix'

  sudo /usr/sbin/postconf -e "inet_interfaces = loopback-only"
  
  sudo touch /tmp/restart-postfix
}

###############################################################################

_postfix_loopback_only
