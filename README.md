Install scripts for server installations.
=========================================

Library
-------
### Functions:
* _log
* _error
* _print
* _system_installs_install
* _check_root
* _redirect_stdout

### Variables:
* $temp_dir
* $COL_BLUE
* $COL_RED
* $COL_REST

###Usage
`wget -N --quiet https://raw.github.com/pierot/server-installer/master/lib.sh; . ./lib.sh`

At the top of your bash script. This way you can use all functions and variables in your script.


Basic Linode install
-------------------
### Usage
`bash <( curl -s https://raw.github.com/pierot/server-installer/master/base.sh ) -s 'tortuga.com'  [-e 'production']`

or for help and instructions

`bash <( curl -s https://raw.github.com/pierot/server-installer/master/base.sh ) -h`

Rbenv install
-----------
### Installs
* rbenv + ruby 1.9.3-p125 + bundler
* rubygems

### Usage
`bash <( curl -s https://raw.github.com/pierot/server-installer/master/rbenv.sh )`

NGINX + PHP5 install
--------------------------------
### Installs
* nginx
* php-fpm

### Usage
`bash <( curl -s https://raw.github.com/pierot/server-installer/master/nginx.sh ) [-d '/opt/nginx' -n '1.2.7']`


RVM install
-----------
### Installs
* rvm + ruby 1.8.7 + ruby 1.9.3 + bundler
* rubygems

### Usage
`bash <( curl -s https://raw.github.com/pierot/server-installer/master/rvm.sh )`

NGINX + PASSENGER + PHP5 install
--------------------------------
### Installs
* passenger (latest) + nginx
* php-fpm

### Usage
`bash <( curl -s https://raw.github.com/pierot/server-installer/master/nginx-passenger-php.sh ) [-d '/opt/nginx' -n '1.2.7']`

Postfix install
---------------
### Installs
Postfix!

###Usage
`bash <( curl -s https://raw.github.com/pierot/server-installer/master/postfix.sh )`

Munin install
---------------
### Installs
Munin

###Usage
`bash <( curl -s https://raw.github.com/pierot/server-installer/master/munin.sh ) -d '/opt/nginx'`

MySQL install
---------------
### Installs
MySQL

###Usage
`bash <( curl -s https://raw.github.com/pierot/server-installer/master/mysql.sh ) -p 'password'`

PostgreSQL install
---------------
### Installs
PostgreSQL

###Usage
`bash <( curl -s https://raw.github.com/pierot/server-installer/master/postgresql.sh ) -p 'password'`

Noort.be site
------------

###Usage
`bash <( curl -s https://raw.github.com/pierot/server-installer/master/noort_be.sh )`

Varnish install
---------------
### Installs
Varnish!

###Usage
`bash <( curl -s https://raw.github.com/pierot/server-installer/master/varnish.sh )`

Mosh install
---------------
### Installs
mosh

###Usage
`bash <( curl -s https://raw.github.com/pierot/server-installer/master/mosh.sh )`

Monit install
---------------
### Installs
monit

###Usage
`bash <( curl -s https://raw.github.com/pierot/server-installer/master/monit.sh )` -n 'tortuga'
