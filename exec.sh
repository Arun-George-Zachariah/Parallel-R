#!/usr/bin/env bash

# Input Defaults.
MACHINES="conf/machine_list.txt"
USER="arung"
KEY="~/.ssh/id_rsa"
INPUT="data/Sample_Data.csv"
OUT_DIR="/mydata/data"

# Usage.
usage()
{
    echo "usage: exec.sh [--machines MACHINE_LIST] [--user USER] [--key PRIVATE_KEY] [--inp INPUT_FILE] [--out DESTINATION_DIR][-h | --help]"
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
        --inp)
        	shift
        	INPUT=$1
        	;;
        --inp)
        	shift
        	OUT_DIR=$1
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

# Obtaining the no of nodes.
no_of_nodes=$(cat ${MACHINES} | wc -l)

# Splitting the input data based on the no of nodes. (Note that, if the number of nodes is >=100, increment argument a)
tail -n +2 ${INPUT} | split -da 1 -l $[ $(wc -l ${INPUT} |cut -d" " -f1) / ${no_of_nodes} ]  - --filter='sh -c "{ head -n1 ${INPUT}; cat; } > $FILE"'

# Copying the splits to the nodes.
i=0
for machine in $(cat "$cluster_machines")
do
  scp -o "StrictHostKeyChecking no" -i ${KEY} x${i} ${USER}@${machine}:${OUT_DIR}/data.csv
  i=$(( $i + 1 ))
done

# Executing the parallen bnlearn script.

# Deleting the splits.
rm -rf $(dirname ${INPUT})/x*