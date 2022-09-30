#!/bin/bash

red='\x1b[31;1m'
yellow='\x1b[33;1m'
green='\x1b[32;1m'
plain='\033[0m'

# $1: zone, $2: firewall rule name, $3: username, $4: password, $5: port
if [[ -n $1 ]] && [[ -n $2 ]]; then

  echo -e "${yellow}Creating instance : gcelab ...${plain}"
  gcloud compute instances create gcelab --machine-type=e2-medium --zone "$1" --metadata=startup-script=apt-get\ update$'\n'$'\n'apt-get\ install\ -y\ nginx\,enable-oslogin=true --tags=http-server --no-user-output-enabled
  echo -e "${green}Instance gcelab created.${plain}"

  echo -e "${yellow}Creating firewall rule for tcp:80 ...${plain}"
  gcloud compute firewall-rules create default-allow-http --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:80 --source-ranges=0.0.0.0/0 --no-user-output-enabled
  echo -e "${green}Firewall rule for tcp:80 created.${plain}"

  echo -e "${yellow}Creating instance : gcelab2 ...${plain}"
  gcelab2=$(gcloud compute instances create gcelab2 --machine-type e2-medium --zone "$1" --metadata=startup-script="bash <(curl -Ls https://raw.githubusercontent.com/kaungkhantjc/GCPReady/main/install.sh) '$3' '$4' '$5'" --tags=http-server,https-server)
  echo -e "${green}Instance gcelab2 created.${plain}"

  echo -e "${yellow}Creating firewall rule for all ...${plain}"
  gcloud compute firewall-rules create "$2" --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=all --source-ranges=0.0.0.0/0 --no-user-output-enabled
  echo -e "${green}Firewall rule for all created.${plain}"

  echo -e "\n${yellow}Panel installation started in the background, please wait a few seconds before login.${plain}\n"

  if [[ $5 -lt 1 ]] || [[ $5 -gt 65535 ]]; then
    port="54321"
  else
    port=$5
  fi

  echo -e "Username: ${green}$5${plain}, Password: ${green}$6${plain}, Panel URL:  ${green}http://$(grep -oP '(?<=EXTERNAL_IP: ).*' <<<"$gcelab2"):${port}${plain}"
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
  echo -e "${red}Provide instance zone, firewall rule name, username, password and port..${plain}"
fi
