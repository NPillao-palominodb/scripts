#!/usr/bin/python
# Author: Narcis pillao <npillao@blackbirdit.com>
# Description: This script will check split brain process

import sys
import argparse
import MySQLdb.cursors

def parse_cfg_file(data_file):
  
  dic_vars = {}
  host_list = []
  array = [ 'user', 'password' ]

  for line in data_file.readlines():
    line = line.strip()
 
    if line.split('=')[0] in [ 'user', 'password' ]:
       k, v = line.split('=')
       dic_vars[k] = v
       
    elif 'hostname=' in line:
        host_list.append(line.split('=')[1])

  dic_vars['hostnames'] = host_list
  dic_vars['password']  = dic_vars['password'].replace('"', '')
  return dic_vars


def read_only(host, user, password='', port=3306, socket='' ):
  "Find out if the database is set as Read Only"

  try:
    conn = MySQLdb.connect(host=host, user=user, passwd=password, port=3306, unix_socket=socket, cursorclass=MySQLdb.cursors.DictCursor)
    cursor = conn.cursor()
    cursor.execute("show global variables like 'read_only'")
    result = cursor.fetchone()['Value']
    cursor.close()
  except Exception, err:
    print "UNKNOWN: - Unable to connect to: "+ host, sys.exc_info()[0]
    sys.exit(3)
    print result
    sys.exit()
  if result == 'OFF':
    return False
  else:
    return True

def check_status(L):

  L_ro = {}
  L_masters = []
  is_slave  = False
  exit_code = 0
  count_master = 0
  
   
  for dbs in L['hostnames']:
    L_ro[dbs] = read_only(dbs, L['user'], L['password'] )
    
    if L_ro[dbs] == True:
      is_slave = True
    elif L_ro[dbs] == False:
      count_master += 1
      L_masters.append(dbs)
  #print "DEBUG: " +  str(L_ro)
   
  if count_master == 0:
    print "CRITICAL: There is not any master present"
    exit_code = 2
  elif count_master > 1:
    print "CRITICAL: There is more than 1 master: " + str(L_masters)
    exit_code = 2
  elif is_slave == False:
    print "CRITICAL: No slaves found" 
    exit_code = 2
  else:
    print "OK"
    exit_code = 0
  
  return exit_code 

def get_cluster_info(host):

  cluster = host.split('.')[1]
  env = host.split('.')[2]

  return cluster, env

def main():

  #Arguments
  usage = 'Usage: %prog [options] arg1 arg2'
  parser = argparse.ArgumentParser()

  parser.add_argument('-c', '--cfg', dest='cfg', type=str,  help = 'MHA configure file')
  args = parser.parse_args()

  try:
    in_file = open(args.cfg, 'r')
  except IOError:
    print "Error: Cannot find file or read data. You maybe specified a wrong path or this file is being re-generated"
    sys.exit(2)

  L = parse_cfg_file(in_file)

  if len(L['hostnames']) == 0:
    print "WARNING: No databases found"
    sys.exit(1)

  cluster, env = get_cluster_info(L['hostnames'][0])
  print "Checking cluster "+ cluster + " environment: " + env

  return check_status(L)
      
  
if __name__ == "__main__":
  main()
