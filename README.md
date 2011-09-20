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
### Installs
* rvm + ruby 1.8.7 + ruby 1.9.7 + bundler
* rubygems
* passenger (latest) + nginx
* php-fpm

### Usage
`bash <( curl -s https://raw.github.com/pierot/server-installer/master/base.sh ) -s 'tortuga'  [-d '/opt/nginx' -n '1.0.6' -e 'production']`

or for help and instructions

`bash <( curl -s https://raw.github.com/pierot/server-installer/master/base.sh ) -h`

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
