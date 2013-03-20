#!/usr/bin/env bash

wget -N --quiet https://raw.github.com/pierot/server-installer/master/lib.sh; . ./lib.sh

_redirect_stdout 'mysql'
_check_root

###############################################################################

_usage() {
  _print "

Usage:              mysql.sh -p 'password'

Remote Usage:       bash <( curl -s https://raw.github.com/pierot/server-installer/master/mysql.sh ) -p 'test'

Options:
 
  -h                Show this message
  -p 'password'     MySQL password
  "

  exit 0
} 

###############################################################################

pass=

while getopts :hp: opt; do 
  case $opt in
    h)
      _usage
      ;;
    p)
      pass=$OPTARG
      ;;
    *)
      _error "Invalid option received"

      _usage

      exit 0
      ;;
  esac 
done

if [ -z $pass ]; then
  _error "-p 'pass' not given."

  exit 0
fi

###############################################################################

_mysql_install() {
	_log "Install MySQL"

  if [ ! -n "$1" ]; then
    _log "mysql_install() requires the root pass as its first argument"
    return 1;
  fi

  echo "mysql-server-5.5 mysql-server/root_password password $1" | sudo debconf-set-selections
  echo "mysql-server-5.5 mysql-server/root_password_again password $1" | sudo debconf-set-selections

  _system_installs_install 'php5-mysql'
  _system_installs_install 'mysql-server mysql-client'
  _system_installs_install 'libmysqlclient15-dev libmysql-ruby'

	_log "***** Sleeping while MySQL starts up for the first time..."

  sleep 5

  gem install mysql -- --with-mysql-dir=/usr/bin --with-mysql-lib=/usr/lib/mysql --with-mysql-include=/usr/include/mysql
}

_mysql_tune() {
  _log "MySQL Tune: $1"

  # Tunes MySQL's memory usage to utilize the percentage of memory you specify, defaulting to 40%
  # $1 - the percent of system memory to allocate towards MySQL

  if [ ! -n "$1" ];
    then PERCENT=40
    else PERCENT="$1"
  fi

  sudo sed -i -e 's/^#skip-innodb/skip-innodb/' /etc/mysql/my.cnf # disable innodb - saves about 100M

  MEM=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo) # how much memory in MB this system has
  MYMEM=$((MEM*PERCENT/100)) # how much memory we'd like to tune mysql with
  MYMEMCHUNKS=$((MYMEM/4)) # how many 4MB chunks we have to play with
  
  # mysql config options we want to set to the percentages in the second list, respectively
  OPTLIST=(key_buffer sort_buffer_size read_buffer_size read_rnd_buffer_size myisam_sort_buffer_size query_cache_size)
  DISTLIST=(75 1 1 1 5 15)

  for opt in ${OPTLIST[@]}; do
    sudo sed -i -e "/\[mysqld\]/,/\[.*\]/s/^$opt/#$opt/" /etc/mysql/my.cnf
  done

  for i in ${!OPTLIST[*]}; do
    val=$(echo | awk "{print int((${DISTLIST[$i]} * $MYMEMCHUNKS/100))*4}")
    
    if [ $val -lt 4 ]
      then val=4
    fi

    config="${config}\n${OPTLIST[$i]} = ${val}M"
  done

  sudo sed -i -e "s/\(\[mysqld\]\)/\1\n$config\n/" /etc/mysql/my.cnf

  sudo touch /tmp/restart-mysql
}

###############################################################################

_mysql_install $pass
_mysql_tune 40

_note_installation "mysql"
