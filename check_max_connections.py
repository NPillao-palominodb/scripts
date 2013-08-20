#!/usr/bin/python
# -*- coding: utf8 -*-
# ======================================================================
# Author: Narcis Pillao
# License: GPL License (see COPYING)
# Copyright 2013 PalominoDB Inc.
# ======================================================================

from optparse import OptionParser
import sys
import os
import MySQLdb.cursors

def current_connections(host, user, password='', port='', socket='' ):
  "Number of current connections"
  try:
    conn = MySQLdb.connect(host=host, user=user, passwd=password, port=port, unix_socket=socket, cursorclass=MySQLdb.cursors.DictCursor)
    cursor = conn.cursor()
    cursor.execute("show global status like 'Threads_connected';")
    result = cursor.fetchone()['Value']
    cursor.close()
  except Exception, err:
    print "UNKNOWN: - Unable to connect to: "+ host, sys.exc_info()[0]
    sys.exit(3)
    print result
    sys.exit()
  return result


def max_connections(host, user, password='', port='', socket=''):
  "Number of allowed max connections"
  try:
    conn = MySQLdb.connect(host=host, user=user, passwd=password, port=port, unix_socket = socket, cursorclass=MySQLdb.cursors.DictCursor)
    cursor = conn.cursor()
    cursor.execute("show variables like 'max_connections';")
    result = cursor.fetchone()['Value']
    cursor.close()
  except Exception, err:
    print "UNKNOWN: - Unable to connect to: "+ host
    sys.exit(3)

  return result

if __name__ == "__main__":
  #Arguments
  usage = 'Usage: %prog [options] arg1 arg2'
  parser = OptionParser(usage = usage)
  parser.add_option('-H', '--host', dest = 'host', help = 'Database host')
  parser.add_option('-u', '--user', dest = 'user', help = 'Database username')
  parser.add_option('-p', '--password', dest = 'password', help = 'Database Password')
  parser.add_option('-P', '--port', dest = 'port', help = 'Database port')
  parser.add_option('-s', '--socket', dest = 'socket', help = 'Unix socket path')
  parser.add_option('-w', '--warning', dest = 'warning', help = 'Warning threshold is the % between current connections and max connections (int).')
  parser.add_option('-c', '--critical', dest = 'critical', help = 'Critical threshhold is the % between current connections and max connections (int).')
  (options,args) = parser.parse_args()

  host = options.host
  user = options.user
  passwd = options.password
  port = options.port
  socket = options.socket
  warning = int(options.warning)
  critical = int(options.critical)

  # Sanity check. Ugly but there is a bug which has not allow to define a default int value on funcion definition.
  if not port:
    port = 3306
  else:
    port=int(port)
  if not socket:
    socket='/var/lib/mysql/mysql.sock'
  
  if warning > critical:
    print "UNKNOWN: - Warning threshold has to be lower than critical "
    sys.exit(3)

  cc = current_connections(host, user, passwd, port, socket)
  mc = max_connections(host, user, passwd,port,socket)
  utilitzation = 100 - int(100 - (float(cc) / float(mc) * 100))
  if utilitzation >= critical:
    print "CRITICAL - This node is using " + str(utilitzation) + "% of its maximum allowed connections |",
    print " Current connections: "+cc,
    print "| Max connections: "+mc,
    sys.exit(2)
  elif utilitzation >= warning:
    print "WARNING - This node is using " + str(utilitzation) + "% of its maximum allowed connections |",
    print " Current connections: "+cc,
    print "| Max connections: "+mc,
  else:
    print "OK - It currently takes:" + str(utilitzation) + "% |",
    print " Current connections: "+cc,
    print "| Max connections: "+mc,
