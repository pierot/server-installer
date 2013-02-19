#!/usr/bin/env bash

install_name='pptpd'
vpn_user='vpn'
vpn_pass=

###############################################################################

wget -N --quiet https://raw.github.com/pierot/server-installer/master/lib.sh; . ./lib.sh

_redirect_stdout $install_name
_check_root

###############################################################################

_usage() {
  _print "

Usage:              $install_name.sh -h

Remote Usage:       bash <( curl -s https://raw.github.com/pierot/server-installer/master/$install_name.sh ) -p 'test'

Options:
 
  -h                Show this message
  -p 'password'     password for user `vpn`
  "

  exit 0
} 

###############################################################################

while getopts :hs:n:d:e: opt; do 
  case $opt in
    h)
      _usage
      ;;
    p)
      vpn_pass=$OPTARG
      ;;
    *)
      _error "Invalid option received"

      _usage

      exit 0
      ;;
  esac 
done

if [ -z $pass ]; then
  _error "-p 'pass' not given."

  exit 0
fi

###############################################################################

_pptpd() {
	_log "Install $install_name"

  _log "***** Add VPN user"

  useradd $vpn_user
  echo "$vpn_pass:$vpn_user" | chpasswd

  _log "***** Install dependencies"

  _system_installs_install 'pptpd'

  # sudo perl -pi -e "s/$1/$2/" $nginx_dir"/conf/nginx.conf"

  _log "***** pptpd Config"

  echo "localip 192.168.0.1" >> /etc/pptpd.conf
  echo "remoteip 192.168.0.234-244" >> /etc/pptpd.conf

  _log "***** Add VPN user to pptpd"

  echo "$vpn_user pptpd $vpn_pass *" >> /etc/ppp/chap-secrets

  _log "***** Add VPN DNS Servers"

  echo "ms-dns 8.8.8.8" >> /etc/ppp/pptpd-options
  echo "ms-dns 8.8.4.4" >> /etc/ppp/pptpd-options

  _log "***** Configure NAT for PPTP connections"

  sudo perl -pi -e "s/exit 0/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE\\nexit 0/" "/etc/rc.local"

  _log "***** Enable IPv4 forwading"

  sudo perl -pi -e "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/" "/etc/sysctl.conf"

  sudo sysctl -p
}

###############################################################################

_pptpd

_note_installation $install_name
