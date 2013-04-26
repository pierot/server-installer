#!/usr/bin/env bash

wget -N --quiet https://raw.github.com/pierot/server-installer/master/lib.sh; . ./lib.sh

_redirect_stdout 'base'
_check_root
_print_h1 'Base'

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

	_print_h2 "Setting hostname to $1"

  full_server_name=$1
	short_server_name=`echo $full_server_name | awk -F. '{ print $1 }'`

  sudo sh -c "echo $short_server_name > /etc/hostname"
	sudo sh -c "echo '127.0.0.1 $full_server_name $short_server_name localhost' >> /etc/hosts"
	sudo hostname -F /etc/hostname

  sudo perl -pi -e "s/SET_HOSTNAME=\'yes\'/#SET_HOSTNAME=\'yes\'/" "/etc/default/dhcpcd"
}

_system_installs() {
	_print_h2 "System wide installs"

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
  _system_installs_install 'zsh'
}

_system_auto_update() {
	_print_2 "Install auto periodic update"

	_system_installs_install "unattended-upgrades"

  sudo cat > /etc/apt/apt.conf.d/10periodic <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF
}

_system_locales() {
	_print_h2 "Fix locales"

  _system_installs_install 'multipath-tools'

  # Fix locales
  export LANGUAGE=en_US.UTF-8
  export LANG=en_US.UTF-8
  export LC_ALL=en_US.UTF-8

  locale-gen en_US.UTF-8

  sudo dpkg-reconfigure locales
}

_system_timezone() {
	_print_h2 "System timezone"

  sudo dpkg-reconfigure tzdata

  sudo cp /usr/share/zoneinfo/Europe/Brussels /etc/localtime

  _system_installs_install 'ntp'

  sudo ntpdate ntp.ubuntu.com
}

_setup_security() {
	_print_h2 "Setup security"

  _print "***** Secure shared memory"

  sudo sh -c 'echo "tmpfs     /dev/shm     tmpfs     defaults,ro     0     0" >> /etc/fstab'

  # Do not permit source routing of incoming packets
  sudo sysctl -w net.ipv4.conf.all.accept_source_route=0
  sudo sysctl -w net.ipv4.conf.default.accept_source_route=0

  # Protect ICMP attacks
  sudo sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1

  # Turn on protection for bad icmp error messages
  sudo sysctl -w net.ipv4.icmp_ignore_bogus_error_responses=1

  # Turn on syncookies for SYN flood attack protection
  sudo sysctl -w net.ipv4.tcp_syncookies=1

  # Log suspcicious packets, such as spoofed, source-routed, and redirect
  sudo sysctl -w net.ipv4.conf.all.log_martians=1
  sudo sysctl -w net.ipv4.conf.default.log_martians=1

  # Enables RFC-reccomended source validation (dont use on a router)
  sudo sysctl -w net.ipv4.conf.all.rp_filter=1
  sudo sysctl -w net.ipv4.conf.default.rp_filter=1

  # Make sure no one can alter the routing tables
  sudo sysctl -w net.ipv4.conf.all.accept_redirects=0
  sudo sysctl -w net.ipv4.conf.default.accept_redirects=0
  sudo sysctl -w net.ipv4.conf.all.secure_redirects=0
  sudo sysctl -w net.ipv4.conf.default.secure_redirects=0

  # Host only (we're not a router)
  sudo sysctl -w net.ipv4.ip_forward=0
  sudo sysctl -w net.ipv4.conf.all.send_redirects=0
  sudo sysctl -w net.ipv4.conf.default.send_redirects=0

  # Turn on execshild
  # sudo sysctl -w kernel.exec-shield=1
  # sudo sysctl -w kernel.randomize_va_space=1

  # Tune IPv6
  sudo sysctl -w net.ipv6.conf.default.router_solicitations=0
  sudo sysctl -w net.ipv6.conf.default.accept_ra_rtr_pref=0
  sudo sysctl -w net.ipv6.conf.default.accept_ra_pinfo=0
  sudo sysctl -w net.ipv6.conf.default.accept_ra_defrtr=0
  sudo sysctl -w net.ipv6.conf.default.autoconf=0
  sudo sysctl -w net.ipv6.conf.default.dad_transmits=0
  sudo sysctl -w net.ipv6.conf.default.max_addresses=1

  # Optimization for port usefor LBs
  # Increase system file descriptor limit
  sudo sysctl -w fs.file-max=65535

  # Allow for more PIDs (to reduce rollover problems); may break some programs 32768
  sudo sysctl -w kernel.pid_max=65536

  # Increase system IP port limits
  sudo sysctl -w net.ipv4.ip_local_port_range=2000 65000

  # Increase TCP max buffer size setable using setsockopt()
  sudo sysctl -w net.ipv4.tcp_rmem=4096 87380 8388608
  sudo sysctl -w net.ipv4.tcp_wmem=4096 87380 8388608

  # Increase Linux auto tuning TCP buffer limits
  # min, default, and max number of bytes to use
  # set max to at least 4MB, or higher if you use very high BDP paths
  sudo sysctl -w net.core.rmem_max=8388608
  sudo sysctl -w net.core.wmem_max=8388608
  sudo sysctl -w net.core.netdev_max_backlog=5000
  sudo sysctl -w net.ipv4.tcp_window_scaling=1
}

_ssh() {
	_print_h2 "SSH Config"

  sudo perl -pi -e "s/Port 22/Port 33/" "/etc/ssh/sshd_config"
  sudo perl -pi -e "s/AcceptEnv LANG LC_*//" "/etc/ssh/sshd_config"

  echo "\nUseDNS no" >> /etc/ssh/sshd_config
  echo "\nCompression yes" >> /etc/ssh/sshd_config
}

_firewall() {
  # iptables-save > /root/firewall.rules
  # iptables-restore < /root/firewall.rules

  # clear all
  iptables -F
  iptables -X
  iptables -t nat -F
  iptables -t nat -X
  iptables -t mangle -F
  iptables -t mangle -X
  iptables -P INPUT ACCEPT
  iptables -P OUTPUT ACCEPT
  iptables -P FORWARD ACCEPT

  # Accepts all established inbound connections
  iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

  # Allows all outbound traffic
  # You could modify this to only allow certain traffic
  iptables -A OUTPUT -j ACCEPT

  # Allows HTTP and HTTPS connections from anywhere (the normal ports for websites)
  iptables -A INPUT -p tcp --dport 443 -j ACCEPT
  iptables -A INPUT -p tcp --dport 80 -j ACCEPT
  iptables -A INPUT -p tcp --dport 8080 -j ACCEPT

  # Allow mosh over udp
  iptables -I INPUT -p udp --dport 60000:61000 -j ACCEPT

  # Allows SSH connections
  iptables -A INPUT -p tcp -m state --state NEW --dport 33 -j ACCEPT

  # Allow ping
  iptables -A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT

  # Autoriser loopback
  iptables -A INPUT -i lo -j ACCEPT
  iptables -A OUTPUT -o lo -j ACCEPT

  # DNS
  iptables -A INPUT -p tcp --dport 53 -j ACCEPT
  iptables -A INPUT -p udp --dport 53 -j ACCEPT

  # Log iptables denied calls (access via 'dmesg' command)
  iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables denied: " --log-level 7

  # Reject all other inbound - default deny unless explicitly allowed policy:
  iptables -A INPUT -j REJECT
  iptables -A FORWARD -j REJECT
}

_failtoban() {
	_print_h2 "Install Fail2Ban"

  _system_installs_install 'fail2ban'

  sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

  sudo perl -0 -pwe -i "s/\[ssh-ddos\]\n\nenabled  = false\nport     = ssh/\[ssh-ddos\]\n\nenabled  = true\nport     = 33/" "/etc/fail2ban/jail.local"
  sudo perl -0 -pwe -i "s/\[ssh\]\n\nenabled  = true\nport     = ssh/\[ssh\]\n\nenabled  = true\nport     = 33/" "/etc/fail2ban/jail.local"
  sudo perl -0 -pwe -i "s/destemail = root@localhost/destemail = pieter@noort.be/" "/etc/fail2ban/jail.local"
  sudo perl -0 -pwe -i "s/ignoreip = 127.0.0.1\/8\nbantime  = 600\nmaxretry = 3/ignoreip = 127.0.0.1\/8\nbantime  = 3600\nmaxretry = 2/" "/etc/fail2ban/jail.local"

  sudo service fail2ban restart
}

_env_variables() {
	_print_h2 "Setting ENV variables"

  sudo cat > /etc/environment <<EOF
RAILS_ENV="$1"
RACK_ENV="$1"
EOF
}

_install_tmux() {
	_print_h2 "Installing tmux"

  _system_installs_install 'tmux'
}

_the_end() {
	_print_h2 "Finishing"

  _print "Cleaning up"

  sudo apt-get -qq autoremove
}

###############################################################################

_hostname $server_name
_system_installs
# _system_locales
_system_timezone
_ssh
_firewall
_failtoban
_setup_security

_install_tmux

_env_variables $env_var
_the_end

_note_installation "base"
