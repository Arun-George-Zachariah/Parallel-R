#!/usr/bin/env bash

# Input
MACHINES="$1"
USER="$2"
KEY="$3"

# Constants
NO_HSTFILE=()
NO_HSTNM=()

# Obtaining the number of machines.
machine_lst=($(cat $MACHINES))
no_of_machines=$(wc -l < $MACHINES | tr -d ' ')

# Verifying openssl installation.
[ -z "`which openssl`" ] && echo -e "\nERROR: openssl NOT FOUND. TERMINATING THE INSTALLATION." && exit 1

# Generating the password.
password=`openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | fold -w 128 | head -n 1`

echo -e "SETTING CLUSTER PASSWORD."

# Iterating over the machines.
for machine in $(cat $MACHINES)
do
  # Installing sshpass.
  ssh -o "StrictHostKeyChecking no" -i $KEY $USER@$machine "export DEBIAN_FRONTEND='noninteractive' && sudo apt-get update && sudo apt-get install sshpass --yes > /dev/null && exit" < /dev/null &> /dev/null

  # Changing the password and restarting ssh.
  ssh -o "StrictHostKeyChecking no" -i $KEY $USER@$machine "echo  -e '$password\n$password' | sudo passwd $USER && sudo sed -i -- 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config && echo 'StrictHostKeyChecking no' > ~/.ssh/config && sudo /etc/init.d/ssh restart && exit" < /dev/null &> /dev/null

  # Verfiying if machine has a hostname
  check_hostnm_cmd="
    result=0
    if [ ! -f  /etc/hostname ]; then
       result=1
    fi
    hstname=$(echo hostname)
    hstname_len=${#hstname}
    if [ "$hstname_len" -eq "0" ]; then
       result=2
    fi
    exit $result
  "

  check_hostname=$(ssh -o "StrictHostKeyChecking no" -i $KEY  $USER@$machine "$ssh_command" < /dev/null)
  check_hostname_status=$(echo $?)

  if [ "$check_hostname_status" -eq "1" ]; then
    NO_HSTFILE+=("$machine")
  fi

  if [ "$check_hostname_status" -eq "2" ]; then
    NO_HSTNM+=("$machine")
  fi

done

exit_status=0
if [ "${#NO_HSTFILE[@]}" -ne "0" ]; then
  echo -e "ERORR: THE FILE \"/etc/hostname\" WAS NOT FOUND IN THE MACHINE(S) BELOW."
  printf '  %s\n' "${NO_HSTFILE[@]}"
  exit_status=1
fi

if [ "${#NO_HSTNM[@]}" -ne "0" ]; then
   echo -e "ERROR: NO HOSTNAME DEFINED IN \"/etc/hostname\"  IN THE MACHINE(S) BELOW."
   printf '  %s\n' "${NO_HSTNM[@]}" 1>&3 2>&4
   exit_status=1
fi

if [ $exit_status -eq 1 ]; then
   exit 0
fi

# Configuring ssh keys.
echo -e "CONFIGURING SSH KEYS."

machine_count=0
for machine in $(cat $MACHINES)
do
  ssh -o "StrictHostKeyChecking no" -i $KEY $USER@$machine 'hostname > ~/hostname.txt'

  ssh_config_cmd="
    # copy to local user
    rm -f ~/.ssh/id_rsa
    ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa &> /dev/null
    ssh-keyscan -H $machine >> ~/.ssh/known_hosts 2> /dev/null
  	echo 'Copying key from '$machine 'to '$machine
    perl -e 'alarm 25; exec @ARGV'  sshpass -p $password ssh-copy-id $USER@$machine &> /dev/null
    # copy to 0.0.0.0 and localhost
    ssh-keyscan -H 0.0.0.0 >> ~/.ssh/known_hosts 2> /dev/null
	  echo 'Copying key from '$machine 'to '0.0.0.0
    perl -e 'alarm 25; exec @ARGV' sshpass -p $password ssh-copy-id $USER@0.0.0.0 &> /dev/null
    ssh-keyscan -H localhost >> ~/.ssh/known_hosts  2> /dev/null
	  echo 'Copying key from '$machine 'to localhost'
    perl -e 'alarm 25; exec @ARGV' sshpass -p $password ssh-copy-id $USER@localhost &> /dev/null
    # make all hosts (including workers) known
    cat /etc/hosts > ~/hosts.txt
    cat /etc/hosts > ~/back-up.hosts.txt
    grep -i -f ~/hostname.txt /etc/hosts | sort -nr | uniq | sed '1d' | xargs -I X sed -e s/X//g -i ~/hosts.txt
    sudo cp ~/hosts.txt /etc/hosts
    awk '{gsub(/[ \t]/,\"\n\")}1' ~/hosts.txt > ~/temp.txt
	  mv ~/temp.txt ~/hosts.txt
    ssh-keyscan -f ~/hosts.txt >> ~/.ssh/known_hosts  2> /dev/null
    rm ~/hosts.txt
    # copy to peers
    for mac in ${machine_lst[*]}; do
	    echo \"Copying key to peers from $machine to \$mac\"
      perl -e 'alarm 25; exec @ARGV' sshpass -p $password ssh-copy-id $USER@\$mac &> /dev/null
      ssh $USER@\$mac \"hostname\"
    done
    chmod 0600 ~/.ssh/authorized_keys
  "
  ssh -o "StrictHostKeyChecking no" -i $KEY $USER@$machine "$ssh_config_cmd"
done

echo -e "SCRIPT FINISHED SUCCESSFULLY."

exit 0