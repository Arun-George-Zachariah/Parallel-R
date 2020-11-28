#!/usr/bin/env bash

# Function to remove a process id from a list of process id's.
function remove_pid() {
  for pid in $1;do
    if [ $pid != $2 ]; then
	    ret_lst="$ret_lst $pid"
	  fi
  done
  echo $ret_lst
}