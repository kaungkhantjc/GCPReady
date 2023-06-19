#!/bin/bash

red='\x1b[31;1m'
yellow='\x1b[33;1m'
green='\x1b[32;1m'
plain='\033[0m'

# $1: username, $2: password, $3: message, $4: token

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Error: ${plain} You must use root user to run this script!\n" && exit 1

if [[ -n $4 ]] && [[ $(($(date +%s) - $4)) -lt 120 ]] && [[ $(($(date +%s) - $4)) -ge 0 ]]; then

sed -i 's/#\?AllowTcpForwarding .*/AllowTcpForwarding yes/' /etc/ssh/sshd_config && sed -i 's/#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config && sed -i 's/#\?Banner .*/Banner \/etc\/ssh\/gcp_ready/' /etc/ssh/sshd_config && /etc/init.d/ssh restart;
echo "$3" | tee /etc/ssh/gcp_ready >/dev/null
useradd "$1" --shell=/bin/false -M
echo "$1:$2" | chpasswd

else
  echo -e "${red}Token is invalid or expired. Contact the developer https://t.me/kaungkhantx for more information.${plain}"
fi

echo ""
echo "------------------------------------"
printf "  Proudly developed the script by  \n"
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

