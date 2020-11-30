#!/usr/bin/env bash

# Config Constants
DATA_DIR=/mydata
SHARE_DIR=
SCRIPTS=(\
  "set-cluster-etchost" \
  "set-cluster-passwd" \
  "set-cluster-dependencies")

# Input Defaults.
MACHINES=conf/machine_list.txt
USER=${USER}
KEY=~/.ssh/id_rsa

# Usage.
usage()
{
    echo "usage: configure.sh [--machines MACHINE_LIST] [--user USER] [--key PRIVATE_KEY] [-h | --help]"
}

# Read input parameters.
while [ "$1" != "" ]; do
    case $1 in
    	--machines)
        	shift
        	MACHINES=$1
        	;;
        --user)
        	shift
        	USER=$1
        	;;
        --key)
        	shift
        	KEY=$1
        	;;
        -h | --help )
        	usage
        	exit
        	;;
        * )
        	usage
            exit
    esac
    shift
done

# Creating the log directory.
if [ ! -d ../logs ]
  then mkdir ../logs
fi

# Creating a temp directory.
mkdir temp

# Iterating and executing the scripts.
for script in "${SCRIPTS[@]}"
do
  log_file="../logs/LOG-"$script".log"
  cmd="./$script.sh $MACHINES $USER $KEY &> $log_file"

  eval "$cmd"
  echo ">> FINISHED $script.sh LOG $log_file"
done

# Deleteing the temp directory.
rm -rf temp