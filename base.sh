#!/usr/bin/env bash

wget -N --quiet https://raw.github.com/pierot/server-installer/master/lib.sh; . ./lib.sh

###############################################################################

install_name='base'

###############################################################################

_redirect_stdout $install_name
_check_root
_print_h1 $install_name

###############################################################################

server_name=
user_name=
env_var="production"
pass=

###############################################################################

_usage() {
  _print "

Usage:              $install_name.sh -h 'noort.be' [-e 'production' -u 'user_name']

Remote Usage:       bash <( curl -s https://raw.github.com/pierot/server-installer/master/$install_name.sh ) -s 'noort.be' [-e 'production' -u 'user_name']

Options:

  -h                    Show this message
  -u                    User account
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
    s)
      user_name=$OPTARG
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

  if [ -f /etc/default/dhcpcd ]; then
    sudo perl -pi -e "s/SET_HOSTNAME=\'yes\'/#SET_HOSTNAME=\'yes\'/" "/etc/default/dhcpcd"
  fi
}

_system_installs() {
	_print_h2 "System wide installs"

  sudo apt-get -qq update
  # sudo apt-get -qq upgrade

  # _system_installs_install 'aptitude'

  # sudo aptitude -y full-upgrade

  _system_installs_install 'build-essential bison openssl libreadline5 libreadline-dev curl git-core zlib1g make'
  _system_installs_install 'zlib1g-dev libssl-dev vim libcurl4-openssl-dev gcc'
  _system_installs_install 'libsqlite3-0 libsqlite3-dev sqlite3'
  _system_installs_install 'libreadline-dev libxslt-dev libxml2-dev subversion autoconf gettext'
  _system_installs_install 'libmagickwand-dev imagemagick'
  _system_installs_install 'chkconfig lsof'
  _system_installs_install 'python-setuptools'
  _system_installs_install 'zsh tmux'
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

_add_user() {
	_print_h2 "Add user $1"

	sudo adduser -G admin $1
	sudo passwd $1

	sudo chown -R $1:users /home/$1
  sudo chsh -s $(which zsh) $1

	_print "Validate user $1"

	id $1
}

_env_variables() {
	_print_h2 "Setting ENV variables"

  sudo cat > /etc/environment <<EOF
RAILS_ENV="$1"
RACK_ENV="$1"
EOF
}

_the_end() {
	_print_h2 "Finishing"

  _print "Cleaning up"

  sudo apt-get -qq autoremove
}

###############################################################################

_hostname $server_name
_system_installs
_system_locales
_system_timezone

if [ ! -z $user_name ]; then
  _add_user $user_name
fi

_env_variables $env_var
_the_end

_note_installation $install_name
