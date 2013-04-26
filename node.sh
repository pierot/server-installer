#!/usr/bin/env bash

install_name='node'

###############################################################################

wget -N --quiet https://raw.github.com/pierot/server-installer/master/lib.sh; . ./lib.sh

_redirect_stdout $install_name
_check_root
_print_h1 $install_name

###############################################################################

_usage() {
  _print "

Usage:              $install_name.sh -h

Remote Usage:       bash <( curl -s https://raw.github.com/pierot/server-installer/master/$install_name.sh )

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
    *)
      _error "Invalid option received"

      _usage

      exit 0
      ;;
  esac
done

###############################################################################

_node() {
  _print_h2 "Install dependencies"

  _system_installs_install 'g++ curl libssl-dev apache2-utils python make'

  _system_installs_install 'python-software-properties software-properties-common'

  sudo add-apt-repository -y ppa:chris-lea/node.js
  sudo apt-get -qq update

  _system_installs_install 'nodejs'
}

###############################################################################

_node $install_name
