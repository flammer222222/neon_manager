#!/bin/bash
#set -x -e

echo "|||__________________________________________________|||"
echo "|||                                                  |||"
echo "|||  ELAGABAL X NODES CREW NEON OPERATOR INSTALLING  |||"
echo "|||      AUTOMATED ANSIBLE SCRIPT FOR COMMUNITY      |||"
echo "|||__________________________________________________|||"

install_operator () {

  echo "Please enter a name for your operator: "
  read neonevm_user_var
  echo "Please enter a config network (devnet, testnet, mainnet): "
  read neonevm_network_var
  echo "Enter solana RPC endpoints: " 
  read rpc_var
  echo "Enter network for postgres data base (localhost in case): "
  read postgres_host_var
  echo "Enter postgres database name: "
  read postgres_db_var
  echo "Enter postgres user: " 
  read postgres_user_var
  echo "Please enter a databae password: "
  read -s postgres_password_var

  rm -rf sv_manager/

  if [[ $(which apt | wc -l) -gt 0 ]]
  then
  pkg_manager=apt
  elif [[ $(which yum | wc -l) -gt 0 ]]
  then
  pkg_manager=yum
  fi

  echo "Updating packages..."
  $pkg_manager update

  echo "Installing ansible, curl, unzip..."
  $pkg_manager install ansible curl unzip --yes

  ansible-galaxy collection install ansible.posix
  ansible-galaxy collection install community.general  

  echo "Installing Docker"

  $pkg_manager install -y \
    gnupg \
    ca-certificates \
    lsb-release \
    software-properties-common

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  
  echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  # Linux post-install
  groupadd docker
  usermod -aG docker $USER
  systemctl enable docker

  echo "Downloading Neon operator manager"
  cmd="https://github.com/Marcus718/neon_manager/archive/refs/tags/v0.1.0.zip"
  echo "starting $cmd"
  curl -fsSL "$cmd" --output neon_manager.zip
  echo "Unpacking"
  unzip ./neon_manager.zip -d .

  mv nevm-manager* neon_manager
  rm ./neon_manager.zip
  cd ./neon_manager || exit
  cp -r ./inventory_example ./inventory

  shellcheck disable=SC2154
  echo "pwd: $(pwd)"
  ls -lah ./

#Сюда нужно указать роль в которой будут все эти переменные. 
  ansible-playbook --connection=local playbooks/install.yml --extra-vars "{ \
  'neonevm_user_var':'$neonevm_user', \
  'neonevm_network_var': '$neonevm_network', \
  'rpc_var': '$neonevm_solana_rpc', \
  'postgres_host_var': '$postgres_host', \
  'postgres_db_var': '$postgres_db', \
  'postgres_user_var': '$postgres_user', \
  'postgres_password_var': '$postgres_password', \
  }"

  echo "See your logs by: docker logs neonevm "

}


while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare ${param}="$2"
        echo $1 $2 // Optional to see the parameter:value result
   fi

  shift
done

sv_manager_version=${sv_manager_version:-latest}


echo "This script will bootstrap a NEON operator. Proceed?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) install_operator break;;  
        No ) echo "Aborting install. No changes will be made."; exit;;
    esac
done
