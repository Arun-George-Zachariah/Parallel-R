#!/usr/bin/env bash

MACHINES="$1"
USER="$2"
KEY="$3"

ssh_command="sudo su -c 'hostname > /etc/hostname'"

echo "READY TO DISTRIBUTE COMMAND:"
echo -e "$ssh_command\n"

echo "ON NODES:"
for machine in $(cat $MACHINES)
do
  ssh -o "StrictHostKeyChecking no" -i $KEY $USER@$machine "$ssh_command"
  echo -e "\t + $machine ... OK"
done

echo -e "SCRIPT FINISHED SUCCESSFULLY."