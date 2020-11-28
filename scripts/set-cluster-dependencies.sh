#!/usr/bin/env bash

# Input
MACHINES="$1"
USER="$2"
KEY="$3"

# Constants.
INSTALL_COMMAND="
  sudo apt-get install -y build-essential
  sudo apt-get install -y git-core
  sudo apt-get install -y doxygen
  sudo apt-get install -y libpcre3-dev
  sudo apt-get install -y protobuf-compiler
  sudo apt-get install -y libprotobuf-dev
  sudo apt-get install -y libcrypto++-dev
  sudo apt-get install -y libevent-dev
  sudo apt-get install -y libboost-all-dev
  sudo apt-get install -y libgtest-dev
  sudo apt-get install -y libssl-dev
  sudo apt-get install -y htop
  sudo apt-get -y install r-base-dev
"

echo "SETTING DEPENDENCIES ON NODES."

for machine in $(cat $MACHINES)
do
  ssh -i $KEY -o "StrictHostKeyChecking no" $USER@$machine "$INSTALL_COMMAND" &> /dev/null &
  echo -e "\t + $machine ... OK"

  pid_list="$pid_list $!"
done

echo -e "\nWAITING FOR THE NODES TO FINISH."

while true; do
  # Iterating over the pid's to check for completed ones.
  for pid in $pid_list; do
    state=$(ps -o state $pid  |tail -n +2)
    if [[ ${#state} -eq 0 ]]; then
      # Removing the pid from the list.
      pid_list=$(remove_pid "${pid_list[@]}" $pid)
    fi
    done

  if [ -z "$pid_list" ]; then
    echo -e "\nALL NODES HAVE COMPLETED SETUP."
    break
  fi
done

echo -e "SETUP FINISHED."
exit 0