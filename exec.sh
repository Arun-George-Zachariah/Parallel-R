#!/usr/bin/env bash

# Input Defaults.
MACHINES="conf/machine_list.txt"
USER="arung"
KEY="~/.ssh/id_rsa"
INPUT="data/Sample_Data.csv"
DATA_DIR="/mydata"

# Constants.
R_LIB="/usr/local/lib/R/site-library"
BNLEARN_PACKAGE="https://www.bnlearn.com/releases/bnlearn_latest.tar.gz"

# Usage.
usage()
{
    echo "usage: exec.sh [--machines MACHINE_LIST] [--user USER] [--key PRIVATE_KEY] [--inp INPUT_FILE] [--data DATA_DIR] [-h | --help]"
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
        --data)
        	shift
        	DATA_DIR=$1
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
tail -n +2 ${INPUT} | split -da 1 -l $[ $(wc -l ${INPUT} | cut -d" " -f1) / ${no_of_nodes} ]  - --filter='sh -c "{ head -n1 '${INPUT}'; cat; } > $FILE"'

# Initialization of the file counter.
i=0

# Iterating over all the machines.
for machine in $(cat ${MACHINES})
do
#  # Downloading the bnlearn package
#  ssh -o "StrictHostKeyChecking no" -i ${KEY} ${USER}@${machine} "wget ${BNLEARN_PACKAGE} -O ${DATA_DIR}/bnlearn_latest.tar.gz"
#
#  # Installing the bnlearn package.
#  ssh -o "StrictHostKeyChecking no" -i ${KEY} ${USER}@${machine} "R CMD INSTALL -l ${DATA_DIR} ${DATA_DIR}/bnlearn_latest.tar.gz"

  # Copying the splits to the nodes.
  scp -o "StrictHostKeyChecking no" -i ${KEY} x${i} ${USER}@${machine}:${DATA_DIR}/data.csv
  i=$(( $i + 1 ))
done

# Executing the parallen bnlearn script.
./learn.R ${DATA_DIR} ${MACHINES} ${DATA_DIR}/data.csv $(head -n1 ${INPUT})

# Deleting the splits.
rm -rvf x*