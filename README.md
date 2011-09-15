Install scripts for server installations.
=========================================

Basic Linode install
-------------------
### Installs
* rvm + ruby 1.8.7 + ruby 1.9.7 + bundler
* rubygems
* passenger + nginx
* php-fpm

### Usage
`bash <( curl -s https://raw.github.com/pierot/server-installer/master/linode-setup/install.sh ) -s 'tortuga'  [-d '/opt/nginx' -n '1.0.6' -e 'production']`

or for help and instructions

`bash <( curl -s https://raw.github.com/pierot/server-installer/master/linode-setup/install.sh ) -h`

Postfix install
---------------
### Installs
Postfix!

###Usage
`bash <( curl -s https://raw.github.com/pierot/server-installer/master/linode-setup/postfix.sh )`

Munin install
---------------
### Installs
Munin

###Usage
`bash <( curl -s https://raw.github.com/pierot/server-installer/master/linode-setup/munin.sh ) -d '/opt/nginx'`

MySQL install
---------------
### Installs
MySQL

###Usage
`bash <( curl -s https://raw.github.com/pierot/server-installer/master/linode-setup/mysql.sh ) -p 'password'`
