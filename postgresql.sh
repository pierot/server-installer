#!/usr/bin/env bash

wget -N --quiet https://raw.github.com/pierot/server-installer/master/lib.sh; . ./lib.sh

_check_root

###############################################################################

db_pass=

###############################################################################

_usage() {
  _print "

Usage:              postgresql.sh -p 'password'

Remote Usage:       bash <( curl -s https://raw.github.com/pierot/server-installer/master/postgresql.sh ) -p 'password'

Options:
 
  -h                Show this message
  -p 'password'     Password
  "

  exit 0
} 

###############################################################################

while getopts :hp: opt; do 
  case $opt in
    h)
      _usage
      ;;
    p)
      db_pass=$OPTARG
      ;;
    *)
      _error "Invalid option received"

      _usage

      exit 0
      ;;
  esac 
done

if [ -z $db_pass ]; then
  _error "-p 'pass' not given."

  exit 0
fi

###############################################################################

_postgresql() {
  _log "Install postgresql"

  _system_installs_install 'postgresql postgresql-contrib postgresql-client libpq-dev'

  _log "***** pg_hba.conf"

  pg_conf=$(find /etc/ -name "pg_hba.conf" | head -n 1)

  sudo sed -i -e  's/^.*local.*all.*all.*$/local\tall\tall\tmd5/g' $pg_conf

  # Make sure linux can access through 'postgres' account
  sudo sed -i -e  's/^local   all             postgres                                peer$/local   all             postgres                                md5/g' $pg_conf

  _log "***** Alter postgres user"

  PSQL_COMMAND="psql -c \"ALTER USER postgres WITH PASSWORD '$db_pass';\""

  sudo su - postgres -c "$PSQL_COMMAND"

  _log "***** Restart postgresql"
  sudo /etc/init.d/postgresql restart

  _log "***** Postgresql status"
  sudo /etc/init.d/postgresql status
}

###############################################################################

_postgresql
_note_installation "postgresql"
