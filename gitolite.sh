#!/usr/bin/env bash

wget -N --quiet https://raw.github.com/pierot/server-installer/master/lib.sh; . ./lib.sh

_check_root

###############################################################################

nginx_dir=

###############################################################################

_usage() {
  _print "

Usage:              gitolite.sh -d ['/opt/nginx']

Remote Usage:       bash <( curl -s https://raw.github.com/pierot/server-installer/master/munin.sh ) [-d '/opt/nginx']

Options:
 
  -h                Show this message
  -d '/opt/nginx'   Sets nginx install dir
  "

  exit 0
} 

###############################################################################

while getopts :hs:n:d:e: opt; do 
  case $opt in
    h)
      _usage
      ;;
    d)
      nginx_dir=$OPTARG
      ;;
    *)
      _error "Invalid option received"

      _usage

      exit 0
      ;;
  esac 
done

###############################################################################
# https://github.com/ericpaulbishop/yourchili/blob/master/library/git.sh

_note_installation "gitolite"
