#!/usr/bin/env bash

wget -N --quiet https://raw.github.com/pierot/server-installer/master/lib.sh; . ./lib.sh

_redirect_stdout 'postfix'
_check_root

###############################################################################

_postfix_loopback_only() {
	_log "Install postfix"

  # Installs postfix and configure to listen only on the local interface. Also allows for local mail delivery
  
  echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
  echo "postfix postfix/mailname string localhost" | debconf-set-selections
  echo "postfix postfix/destinations string localhost.localdomain, localhost" | debconf-set-selections

  _system_installs_install 'postfix'

  sudo /usr/sbin/postconf -e "inet_interfaces = loopback-only"
  
  sudo touch /tmp/restart-postfix
}

_testing() {
  _print "How to test:
$ telnet localhost 25

Trying 127.0.0.1...
Connected to localhost.localdomain.
Escape character is '^]'.
220 tortuga.local ESMTP Postfix (Ubuntu)

  HELO tortuga
250 tortuga.local

  MAIL FROM:<pieter@tortuga>
250 2.1.0 Ok

  RCPT TO:<pieter@noort.be>
250 2.1.5 Ok

  DATA
354 End data with <CR><LF>.<CR><LF>
  Subject: test message
  This is the body!
  .
250 2.0.0 Ok: queued as 8E2B854D5A

  QUIT
221 2.0.0 Bye

Connection closed by foreign host.
"
}

###############################################################################

_postfix_loopback_only

_testing
_note_installation "postfix"
