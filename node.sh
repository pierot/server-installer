#!/usr/bin/env bash

wget -N --quiet https://raw.github.com/pierot/server-installer/master/lib.sh; . ./lib.sh

_redirect_stdout 'node'
_check_root

###############################################################################

install_name='node'
node_version="1.2.3"

###############################################################################

_usage() {
  _print "

Usage:              $install_name.sh -h [-n '1.2.3']

Remote Usage:       bash <( curl -s https://raw.github.com/pierot/server-installer/master/$install_name.sh ) [-n '1.2.3']

Options:
 
  -h                Show this message
  -n '1.2.3'        node version number
  "

  exit 0
} 

###############################################################################

while getopts :hs:n:d:e: opt; do 
  case $opt in
    h)
      _usage
      ;;
    n)
      node_version=$OPTARG
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
	_log "Install $install_name"

  _log "***** Install dependencies"

  _system_installs_install 'g++ curl libssl-dev apache2-utils'

  cd $temp_dir

  _log "***** Clone node"
  git clone git://github.com/ry/node.git
  cd node

  _log "***** Configure & make & make install"
  ./configure
  make
  sudo make install
}

###############################################################################

_node $nginx_version

_note_installation $install_name
