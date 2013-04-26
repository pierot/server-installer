#!/usr/bin/env bash

wget -N --quiet https://raw.github.com/pierot/server-installer/master/lib.sh; . ./lib.sh

###############################################################################

db_pass=
install_name='postgresql'

###############################################################################

_redirect_stdout $install_name
_check_root
_print_h1 $install_name

###############################################################################

_usage() {
  _print "

Usage:              $install_name.sh -p 'password'

Remote Usage:       bash <( curl -s https://raw.github.com/pierot/server-installer/master/$install_name.sh ) -p 'password'

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
  _print_h2 "Install postgresql"

  _system_installs_install 'postgresql postgresql-contrib postgresql-client libpq-dev'

  _print "pg_hba.conf"

  pg_conf=$(find /etc/ -name "pg_hba.conf" | head -n 1)

  sudo sed -i -e  's/^.*local.*all.*all.*$/local\tall\tall\tmd5/g' $pg_conf

  # Make sure linux can access through 'postgres' account
  sudo sed -i -e  's/^local   all             postgres                                peer$/local   all             postgres                                md5/g' $pg_conf

  _print "Alter postgres user"

  PSQL_COMMAND="psql -c \"ALTER USER postgres WITH PASSWORD '$db_pass';\""

  sudo su - postgres -c "$PSQL_COMMAND"

  _print "Restart postgresql"
  sudo /etc/init.d/postgresql restart

  _print "Postgresql status"
  sudo /etc/init.d/postgresql status
}

###############################################################################

_postgresql
_note_installation "postgresql"
