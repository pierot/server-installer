#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# COLORS
COL_BLUE="\x1b[34;01m"
COL_RESET="\x1b[39;49;00m"
COL_RED="\x1b[31;01m"

# TEMP DIR FOR INSTALLS
temp_dir='/tmp/src'
mkdir -p $temp_dir

_log() {
  _print "$1 ******************************************"
}

_print() {
  printf $COL_BLUE"\n$1\n"$COL_RESET
}

_error() {
  _print $COL_RED"Error:\n$1\n"
}

_system_installs_install() {
	[[ -z "$1" ]] && return 1

  _log "***** Install $1"

  sudo DEBIAN_FRONTEND=noninteractive apt-get -qq -y -f install $1
}

_check_root() {
  if [ $(/usr/bin/id -u) != "0" ]
  then
    _error 'Must be run by root user'

    exit 0
  fi
}

_cleanup_lib() {
  if [ -f "./lib.sh" ]; then
    rm ./lib.sh
  fi 
}

_note_installation() {
  touch "$HOME/$1-installed"
}

# _check_root
