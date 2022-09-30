#!/bin/bash

red='\x1b[31;1m'
yellow='\x1b[33;1m'
green='\x1b[32;1m'
plain='\033[0m'

# $1: username, $2: password, $3: port

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Error: ${plain} You must use root user to run this script!\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
  release="centos"
elif grep -Eqi "debian" /etc/issue; then
  release="debian"
elif grep -Eqi "ubuntu" /etc/issue; then
  release="ubuntu"
elif grep -Eqi "centos|red hat|redhat" /etc/issue; then
  release="centos"
elif grep -Eqi "debian" /proc/version; then
  release="debian"
elif grep -Eqi "ubuntu" /proc/version; then
  release="ubuntu"
elif grep -Eqi "centos|red hat|redhat" /proc/version; then
  release="centos"
else
  echo -e "${red}System version not detected, please contact the script author! ${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
  arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
  arch="arm64"
elif [[ $arch == "s390x" ]]; then
  arch="s390x"
else
  arch="amd64"
  echo -e "${red}Failed to check architecture, use default architecture: ${arch}${plain}"
fi

echo "Architecture: ${arch}"

if [ "$(getconf WORD_BIT)" != '32' ] && [ "$(getconf LONG_BIT)" != '64' ]; then
  echo "This software does not support 32-bit system (x86), please use 64-bit system (x86_64), if there are errors in the detection, please contact the author."
  exit 1
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
  os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
  os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
  if [[ ${os_version} -le 6 ]]; then
    echo -e "${red}Please use CentOS 7 or higher version of the system! ${plain}\n" && exit 1
  fi
elif [[ x"${release}" == x"ubuntu" ]]; then
  if [[ ${os_version} -lt 16 ]]; then
    echo -e "${red}Please use Ubuntu 16 or higher version system! ${plain}\n" && exit 1
  fi
elif [[ x"${release}" == x"debian" ]]; then
  if [[ ${os_version} -lt 8 ]]; then
    echo -e "${red}Please use Debian 8 or later system! ${plain}\n" && exit 1
  fi
fi

install_base() {
  echo -e "\n${green}Installing wget, curl, tar ...${plain}\n"
  if [[ x"${release}" == x"centos" ]]; then
    yum install wget curl tar -y
  else
    apt install wget curl tar -y
  fi
}

#This function will be called when user installed x-ui out of security
config_after_install() {
  external_ip=$(curl -Ls "https://api.ipify.org")

  # $1: username, $2: password, $3: port
  if [[ $# == 0 ]] || [[ $# -ne 3 ]] || [[ $3 -lt 1 ]] || [[ $3 -gt 65535 ]]; then
    echo -e "${yellow}For security reasons, please change the port and login details. ${plain}"
    echo -e "Username : ${green}admin${plain}"
    echo -e "Password : ${green}admin${plain}"
    echo -e "Port : ${green}54321${plain}"
    echo -e "Panel URL: ${green}http://${external_ip}:54321${plain}"
  else
    /usr/local/x-ui/x-ui setting -username "$1" -password "$2"
    /usr/local/x-ui/x-ui setting -port "$3"
    echo -e "\nUsername : ${green}$1${plain}"
    echo -e "Password : ${green}$2${plain}"
    echo -e "Port : ${green}$3${plain}"
    echo -e "Panel URL: ${green}http://${external_ip}:$3${plain}"
  fi
}

install_x-ui() {
  echo -e "\n${green}Installing Xray Panel ...${plain}\n"

  systemctl stop x-ui
  cd /usr/local/ || return

  # Download x-ui
  last_version=$(curl -Ls "https://api.github.com/repos/vaxilu/x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  if [[ -z "$last_version" ]]; then
    echo -e "${red}Failed to detect x-ui version, it may exceed the Github API limit, please try again later, or install x-ui version manually. ${plain}"
    exit 1
  fi
  echo -e "Detected x-ui latest version: ${last_version}，starting installation.."
  if ! wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz https://github.com/vaxilu/x-ui/releases/download/"${last_version}"/x-ui-linux-${arch}.tar.gz; then
    echo -e "${red}Download x-ui failed, please make sure your server can download the Github file. ${plain}"
    exit 1
  fi

  if [[ -e /usr/local/x-ui/ ]]; then
    rm /usr/local/x-ui/ -rf
  fi

  tar zxvf x-ui-linux-${arch}.tar.gz
  rm x-ui-linux-${arch}.tar.gz -f
  cd x-ui || return
  chmod +x x-ui bin/xray-linux-${arch}
  cp -f x-ui.service /etc/systemd/system/
  wget --no-check-certificate -O /usr/bin/x-ui https://raw.githubusercontent.com/vaxilu/x-ui/main/x-ui.sh
  chmod +x /usr/local/x-ui/x-ui.sh
  chmod +x /usr/bin/x-ui
  config_after_install "$1" "$2" "$3"

  systemctl daemon-reload
  systemctl enable x-ui
  systemctl start x-ui
  echo -e "${green}x-ui v${last_version}${plain} installation is completed and the panel is activated."
  echo ""
  echo "------------------------------------"
  printf "  Proudly simplified the script by  \n"
  echo "------------------------------------"
  echo ""

  echo -e "${yellow}
 _  __                         _  ___                 _     _  __
| |/ /                        | |/ / |               | |   | |/ /
| ' / __ _ _   _ _ __   __ _  | ' /| |__   __ _ _ __ | |_  | ' /_   _  __ ___      __
|  < / _\` | | | | '_ \ / _\` | |  < | '_ \ / _\` | '_ \| __| |  <| | | |/ _\` \ \ /\ / /
| . \ (_| | |_| | | | | (_| | | . \| | | | (_| | | | | |_  | . \ |_| | (_| |\ V  V /
|_|\_\__,_|\__,_|_| |_|\__, | |_|\_\_| |_|\__,_|_| |_|\__| |_|\_\__, |\__,_| \_/\_/  ${plain}(ɔ◔‿◔)ɔ ${red}♥${yellow}
                        __/ |                                    __/ |
                       |___/                                    |___/ ${green}https://t.me/kaungkhantx${plain}
"

}

install_base

# $1: username, $2: password, $3: port
install_x-ui "$1" "$2" "$3"
