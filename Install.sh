#!/bin/sh

tput sgr0; clear

## Load text color settings
source <(wget -qO- https://raw.githubusercontent.com/Xiaobin2333/Seedbox-Components/main/Miscellaneous/tput.sh)

## Allow user to decide whether they would like to install a component or not
function Decision {
    while true; do
        need_input; read -p "Do you wish to install $1? (Y/N):" yn; normal_1
        case $yn in
            [Yy]* ) echo "Installing $1"; $1; break;;
            [Nn]* ) echo "Skipping"; break;;
            * ) warn_1; echo "Please answer yes or no."; normal_2;;
        esac
    done
}


## Check Root Privilege since this script requires root privilege
if [ $(id -u) -ne 0 ]; then 
    warn_1; echo  "This script needs root permission to run"; normal_4 
    exit 1 
fi


## Check Linux Distro
distro_codename="$(source /etc/os-release && printf "%s" "${VERSION_CODENAME}")"
if [[ $distro_codename != buster ]] && [[ $distro_codename != bullseye ]] && [[ $distro_codename != focal ]] && [[ $distro_codename != jammy ]] && [[ $distro_codename != bionic ]] && [[ $distro_codename != stretch ]]; then
    warn_1; echo "Only Debian 9/10/11 and Ubuntu 18/20/22 is supported"; normal_4
    exit 1
fi


## Check System Architecture
ARCH=$(uname -m)
if [[ $ARCH != x86_64 ]] && [[ $ARCH != aarch64 ]]; then
    warn_1; echo "Only X86_64/Aarch64 is supported"; normal_4
    exit 1
fi


## Check Virtual Environment since part of the script might not work on virtual machine
systemd-detect-virt > /dev/null
if [ $? -eq 0 ]; then
    warn_1; echo "Virtualization is detected, part of the script might not run"; normal_4
fi


## Grabing the informations to be used for BitTorrent client setup
username=$1
password=$2
cache=$3

#Converting the cache size to Deluge's unit  (16KiB)
Cache_de=$(expr $cache \* 65536)
#Converting the cache to qBittorrent's unit (MiB)
Cache_qB=$(expr $cache \* 1024)


## Check existence of input argument in a Bash shell script

#Check if user fill in all the required variables
if [ -z "$3" ]
  then
    warn_1; echo "Please fill in all 3 arguments accordingly: <Username> <Password> <Cache Size(unit:GiB)>"; normal_4
    exit 1
fi

#Preventing user from filling in float number as it would make converting the cache size to deluge be difficult
re='^[0-9]+$'
if ! [[ $3 =~ $re ]] ; then
   warn_1; echo "Cache Size has to be an integer"; normal_4
   exit 1
fi


## Check unattended installation
AUTO="n"
if [[ "$@" == *"-auto"* ]]; then
  AUTO="y"
fi


## Creating User to contain the soon to be installed clients
warn_2
pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
useradd -m -p "$pass" "$username"
normal_2


## Install Seedbox Environment
tput sgr0; clear
normal_1; echo "Start Installing Seedbox Environment"; warn_2
source <(wget -qO- https://raw.githubusercontent.com/Xiaobin2333/Seedbox-Components/main/seedbox_installation.sh)
Update
if [ "$AUTO" = "y" ]; then
    qBittorrent
else
    Decision qBittorrent
    Decision Deluge
    Decision autoremove-torrents
fi


## Tweaking
tput sgr0; clear
normal_1; echo "Start Doing System Tweak"; warn_2
source <(wget -qO- https://raw.githubusercontent.com/Xiaobin2333/Seedbox-Components/main/tweaking.sh)
CPU_Tweaking
NIC_Tweaking
Network_Other_Tweaking
Scheduler_Tweaking
file_open_limit_Tweaking
kernel_Tweaking
if [ "$AUTO" = "y" ]; then
    Tweaked_BBR
else
    Decision Tweaked_BBR
fi

## Configue Boot Script
tput sgr0; clear
normal_1; echo "Start Configuing Boot Script"
source <(wget -qO- https://raw.githubusercontent.com/Xiaobin2333/Seedbox-Components/main/Miscellaneous/boot-script.sh)
boot_script
tput sgr0; clear

## Swap off
swapoff -a

normal_1; echo "Seedbox Installation Complete"
publicip=$(curl https://ipinfo.io/ip)
[[ ! -z "$qbport" ]] && echo "qBittorrent $version is successfully installed, visit at $publicip:$qbport"
[[ ! -z "$deport" ]] && echo "Deluge $Deluge_Ver is successfully installed, visit at $publicip:$dewebport"
[[ ! -z "$bbrx" ]] && echo "Tweaked BBR is successfully installed, please reboot for it to take effect"
