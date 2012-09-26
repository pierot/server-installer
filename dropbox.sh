#!/usr/bin/env bash

install_name='dropbox'
dir_list=''

###############################################################################

wget -N --quiet https://raw.github.com/pierot/server-installer/master/lib.sh; . ./lib.sh

_redirect_stdout $install_name
_check_root

###############################################################################

_usage() {
  _print "

Usage:              $install_name.sh -h [ -s 'DirName', 'Dirname2' ]

Remote Usage:       bash <( curl -s https://raw.github.com/pierot/server-installer/master/$install_name.sh ) [ -s 'DirName', 'Dirname2' ] 

Options:
 
  -h                Show this message
  -s                List of directories you want to exclude
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
      dir_list=$OPTARG
      ;;
    *)
      _error "Invalid option received"

      _usage

      exit 0
      ;;
  esac 
done

###############################################################################

_dropbox() {
	_log "Install $install_name"

  cd $HOME

  _log "***** Download dropbox binaries"

  wget -O - "http://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -

  _note_installation "$install_name-one"

  $HOME/.dropbox-dist/dropboxd
}

_dropbox_manage() {
	_log "Install $install_name and set up managers"

  mkdir $HOME/.dropbox-utils
  cd $HOME/.dropbox-utils

  _log "***** Download dropbox control script"

  wget -O ./dropbox.py "http://www.dropbox.com/download?dl=packages/dropbox.py"
  chmod +x dropbox.py

  _log "***** Download dropbox init script"

  wget -O ./dropbox.init.sh "https://raw.github.com/gist/3787880/2e3c1cfe2e62fd53ed735ea1c6179647bef85c1a/dropbix.init.sh"

  _log "***** Create dropbox init script"

  sudo mv ./dropbox.init.sh /etc/init.d/dropbox
  sudo chmod +x /etc/init.d/dropbox
  sudo update-rc.d dropbox defaults

  _log "***** Test dropbox init script"

  sudo service dropbox status
  sudo service dropbox start

  _note_installation "$install_name-two"
}

_dropbox_selective() {
	_log "Selective sync $install_name"

	if [ -z "$1" ]; then

    sudo service dropbox status
    sudo service dropbox start

    cd $HOME/.dropbox-utils

    IFS=","
    list=($1)
    i=0

    while [ $i -lt ${#list[@]} ]; do
      ./dropbox.py exclude add "$i:${list[$i]}" 

      (( i=i+1 ))
    done

    _note_installation "$install_name-three"
	fi
}

###############################################################################

if [ -f "$HOME/$install_name-two-installed" ]; then
  _dropbox_selective $dir_list
else
  if [ -f "$HOME/$install_name-one-installed" ]; then
    _dropbox_manage
  else
    _dropbox
  fi
fi

