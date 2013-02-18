#!/usr/bin/env bash

wget -N --quiet https://raw.github.com/pierot/server-installer/master/lib.sh; . ./lib.sh

_redirect_stdout 'base'
_check_root

###############################################################################

server_name=
env_var="production"
pass=

###############################################################################

_usage() {
  _print "

Usage:              base.sh -h 'server_name.com' [-e 'production']

Remote Usage:       bash <( curl -s https://raw.github.com/pierot/server-installer/master/base.sh ) -s 'noort.be' [-e 'production']

Options:
 
  -h                    Show this message
  -s 'server_name.com'  Set server name
  -e 'environment'      Set RACK / RAILS environment variable
  "

  exit 0
} 

###############################################################################

while getopts :hs:n:d:e: opt; do 
  case $opt in
    h)
      _usage
      ;;
    s)
      server_name=$OPTARG
      ;;
    e)
      env_var=$OPTARG
      ;;
    *)
      _error "Invalid option received"

      _usage

      exit 0
      ;;
  esac 
done

if [ -z $server_name ]; then
  _error "-s 'server_name.com' not given."

  exit 0
fi

###############################################################################

_hostname() {
	[[ -z "$1" ]] && return 1

	_log "Setting hostname to $1"

  full_server_name=$1
	short_server_name=`echo $full_server_name | awk -F. '{ print $1 }'`

  sudo sh -c "echo $short_server_name > /etc/hostname"
	sudo sh -c "echo '127.0.0.1 $full_server_name $short_server_name localhost' >> /etc/hosts"
	sudo hostname -F /etc/hostname

  sudo perl -pi -e "s/SET_HOSTNAME=\'yes\'/#SET_HOSTNAME=\'yes\'/" "/etc/default/dhcpcd"
}

_system_installs() {
	_log "System wide installs"

  sudo apt-get -qq update
  sudo apt-get -qq upgrade

  _system_installs_install 'aptitude'

  sudo aptitude -y full-upgrade
  
  _system_installs_install 'build-essential bison openssl libreadline5 libreadline-dev curl git-core zlib1g make'
  _system_installs_install 'zlib1g-dev libssl-dev vim libcurl4-openssl-dev gcc'
  _system_installs_install 'libsqlite3-0 libsqlite3-dev sqlite3'
  _system_installs_install 'libreadline-dev libxslt-dev libxml2-dev subversion autoconf gettext'
  _system_installs_install 'libmagickwand-dev imagemagick'
  _system_installs_install 'chkconfig lsof'
  _system_installs_install 'python-setuptools'
}

_system_locales() {
	_log "Fix locales"

  _system_installs_install 'multipath-tools'

  # Fix locales
  export LANGUAGE=en_US.UTF-8
  export LANG=en_US.UTF-8
  export LC_ALL=en_US.UTF-8

  locale-gen en_US.UTF-8

  sudo dpkg-reconfigure locales
}

_system_timezone() {
	_log "System timezone"

  sudo dpkg-reconfigure tzdata

  sudo cp /usr/share/zoneinfo/Europe/Brussels /etc/localtime

  _system_installs_install 'ntp'

  sudo ntpdate ntp.ubuntu.com
}

_setup_users() {
	_log "Setup user settings + security"

  _log "***** Secure shared memory"

  sudo sh -c 'echo "tmpfs     /dev/shm     tmpfs     defaults,noexec,nosuid     0     0" >> /etc/fstab'

  # Do not permit source routing of incoming packets
  sudo sysctl -w net.ipv4.conf.all.accept_source_route=0
  sudo sysctl -w net.ipv4.conf.default.accept_source_route=0

  # TODO
  # adduser pierot
  # usermod -a -G sudo pierot
}

_ssh() {
	_log "SSH Config"

  sudo perl -pi -e "s/Port 22/Port 33/" "/etc/ssh/sshd_config"
  sudo perl -pi -e "s/AcceptEnv LANG LC_*//" "/etc/ssh/sshd_config"
}

_firewall() {
  # open these ports
  iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
  iptables -A INPUT -p tcp -m tcp --dport 33 -j ACCEPT
  iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
  iptables -A INPUT -p tcp -m tcp --dport 8080 -j ACCEPT

  # local traffic
  iptables -A INPUT -i lo -j ACCEPT

  # block all ports
  iptables -A INPUT -j DROP

  # local traffic
  iptables -A OUTPUT -o lo -j ACCEPT
}

_failtoban() {
	_log "Install Fail2Ban"

  _system_installs_install 'fail2ban'

  sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

  sudo perl -pi -e "s/[33-ddos]\n\n enabled  = false\nport     = 33/[33-ddos]\n\n enabled  = true\nport     = 33/" "/etc/fail2ban/jail.local"
  # Set "enabled" to "true" in [ssh-ddos] section
  # Set "port" to "44444" in [ssh] and [ssh-ddos] sections

  sudo service fail2ban restart
}

_env_variables() {
	_log "Setting ENV variables"

  sudo cat > /etc/environment <<EOF
RAILS_ENV="$1"
RACK_ENV="$1"
EOF
}

_install_tmux() {
	_log "Installing tmux"

  _system_installs_install 'tmux'
}

_the_end() {
	_log "Finishing"

  _log "***** Cleaning up"
  sudo apt-get -qq autoremove
}

###############################################################################

_hostname $server_name
_system_installs
# _system_locales
# _system_timezone
# _ssh
# _firewall
# _setup_users

_install_tmux

_env_variables $env_var
_the_end

_note_installation "base"
