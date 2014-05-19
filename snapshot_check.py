#!/usr/bin/python
# Author: Narcis pillao
import sys
import time
import os
import boto.ec2
from datetime import datetime, timedelta
import argparse


def get_volume(vol_id, region):

  conn = boto.ec2.connect_to_region(region)
  return conn.get_all_volumes(vol_id)[0]


def get_all_snapshots(region):
  
  conn = boto.ec2.connect_to_region(region)
  return conn.get_all_snapshots()[0]

def find_delays(snapshot, deltatime):

  now = datetime.now()
  hour = timedelta(hours=int(deltatime))

  # Time formats
  snap_time = datetime.strptime(snapshot.start_time, '%Y-%m-%dT%H:%M:%S.%fZ')
  current_time =  now.strftime('%Y-%m-%d %H:%M:%S')
  delta_time = now - hour

  if delta_time > snap_time:
      print " Problem: Last snapshot was executed more than " + deltatime + "hours ago! Please, review it."
      print "\t Snapshot ID: " + snapshot.id 
      print "\t Instance: " + snapshot.description 
      print "\t Started at: " + snapshot.start_time
      print "\t Current time: " + str(now)
      print "\t Volume ID: " + snapshot.volume_id

def volume_attched(region, vol_id):
  conn = boto.ec2.connect_to_region(region)
  vol = conn.volume.AttachmentSet()
  print vol.instance_id()
  exit (1)

def main():
  
  #Arguments
  usage = 'Usage: %prog [options] arg1 arg2'
  parser = argparse.ArgumentParser()

  parser.add_argument('-v', '--volumes', dest='volumes', nargs='+', type=str,  help = 'List of volumes to scan snapshots')
  parser.add_argument('-z', '--zone', dest='zone', default='us-west-2',  help = 'AWS zone')
  parser.add_argument('-t', '--time', dest='time', default=4,  help = 'Delay (in hours) allowed from last snapshot')
  args = parser.parse_args()

  volumes = args.volumes
  zone = args.zone
  deltatime = args.time
  
  for volume in volumes:
    vol = get_volume(volume, zone)
    snaps = vol.snapshots()
    last_snap = snaps[-1]
    print "Checking last snapshot for: " + last_snap.description
    find_delays(last_snap, deltatime)


if __name__ == "__main__":
    main()

