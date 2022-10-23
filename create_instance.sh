#!/bin/bash

red='\x1b[31;1m'
yellow='\x1b[33;1m'
green='\x1b[32;1m'
plain='\033[0m'

# $1: instance name, $2: machine type, $3: zone, $4: firewall rule name, $5: username, $6: password, $7: port, $8: token
if [[ -n $1 ]] && [[ $2 == e2-* ]] && [[ -n $3 ]] && [[ -n $4 ]] && [[ -n $8 ]] && [[ $(($(date +%s) - $8)) -lt 120 ]] && [[ $(($(date +%s) - $8)) -ge 0 ]]; then

  echo -e "${yellow}Creating instance ...${plain}"
  instance=$(gcloud compute instances create "$1" --machine-type "$2" --zone "$3" --metadata=startup-script="bash <(curl -Ls https://raw.githubusercontent.com/kaungkhantjc/GCPReady/main/install.sh) '$5' '$6' '$7' '$8'" --tags=http-server,https-server)
  echo -e "${green}Instance created.${plain}"

  echo -e "${yellow}Checking firewall rule ...${plain}"
  if [[ $(gcloud compute firewall-rules list --format='value(allowed)') == *"'IPProtocol': 'all'"* ]]; then
    echo -e "${green}Firewall rule already exist.${plain}"
  else
    echo -e "${yellow}Creating firewall rule ...${plain}"
    gcloud compute firewall-rules create "$4" --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=all --source-ranges=0.0.0.0/0 --no-user-output-enabled
    echo -e "${green}Firewall rule created.${plain}"
  fi

  echo -e "\n${yellow}Panel installation started in the background, please wait a few seconds before login.${plain}\n"

  if [[ $7 -lt 1 ]] || [[ $7 -gt 65535 ]]; then
    port="54321"
  else
    port=$7
  fi

  echo -e "Username: ${green}$5${plain}, Password: ${green}$6${plain}, Panel URL:  ${green}http://$(grep -oP '(?<=EXTERNAL_IP: ).*' <<<"$instance"):${port}${plain}"
  echo -e "\nProudly developed by ...${yellow}
 _  __                         _  ___                 _     _  __
| |/ /                        | |/ / |               | |   | |/ /
| ' / __ _ _   _ _ __   __ _  | ' /| |__   __ _ _ __ | |_  | ' /_   _  __ ___      __
|  < / _\` | | | | '_ \ / _\` | |  < | '_ \ / _\` | '_ \| __| |  <| | | |/ _\` \ \ /\ / /
| . \ (_| | |_| | | | | (_| | | . \| | | | (_| | | | | |_  | . \ |_| | (_| |\ V  V /
|_|\_\__,_|\__,_|_| |_|\__, | |_|\_\_| |_|\__,_|_| |_|\__| |_|\_\__, |\__,_| \_/\_/  ${plain}(ɔ◔‿◔)ɔ ${red}♥${yellow}
                        __/ |                                    __/ |
                       |___/                                    |___/ ${green}https://t.me/kaungkhantx${plain}
"

else
  echo -e "${red}Token is invalid or expired. Contact the developer https://t.me/kaungkhantx for more information.${plain}"
fi
