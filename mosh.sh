#!/usr/bin/env bash

install_name='mosh'

###############################################################################

wget -N --quiet https://raw.github.com/pierot/server-installer/master/lib.sh; . ./lib.sh

_redirect_stdout $install_name
_check_root

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

_mosh() {
	_log "Install $install_name"

  _log "***** Install dependencies"

  _system_installs_install 'python-software-properties'

  sudo add-apt-repository ppa:keithw/mosh
  sudo apt-get update

  _log "***** Install mosh"

  _system_installs_install 'mosh'
}

###############################################################################

_mosh

_note_installation $install_name
