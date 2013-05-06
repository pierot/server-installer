#!/usr/bin/env bash

install_name='memcache'

###############################################################################

wget -N --quiet https://raw.github.com/pierot/server-installer/master/lib.sh; . ./lib.sh

_redirect_stdout $install_name
_check_root
_print_h1 $install_name

###############################################################################

_usage() {
  _print "

Usage:              $install_name.sh -h

Remote Usage:       bash <( curl -s https://raw.github.com/pierot/server-installer/master/$install_name.sh ) -p 'test'

Options:

  -h                Show this message
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

###############################################################################

_memcache() {
	_print_h2 "Install $install_name"

  _print "Install packages"

  _system_installs_install 'memcached php-pear php5-dev'

  _print "Install pecl memcache lib"

  sudo pecl install memcache

  _print "Add memcache.so to php ini and restart php-fpm"

  echo "extension=memcache.so" > /etc/php5/conf.d/memcache.ini

  sudo service php5-fpm restart

  _print "Test memcache is running"

  ps aux | grep memcache

  echo "stats settings" | nc localhost 11211
}

###############################################################################

_pptpd

_note_installation $install_name
