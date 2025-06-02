#!/usr/bin/env bash
#source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

# Version: 1.0.0
# header_info
echo -e "⏳ Loading..."

APP="EOS"
var_disk="32"
var_cpu="4"
var_ram="4096"
var_os="debian"
var_version="12"

header_info "$APP"
variables
color
catch_errors

function header_print() {
clear
cat <<'EOF'
          _____                   _______                   _____          
         /\    \                 /::\    \                 /\    \         
        /::\    \               /::::\    \               /::\    \        
       /::::\    \             /::::::\    \             /::::\    \       
      /::::::\    \           /::::::::\    \           /::::::\    \      
     /:::/\:::\    \         /:::/~~\:::\    \         /:::/\:::\    \     
    /:::/__\:::\    \       /:::/    \:::\    \       /:::/__\:::\    \    
   /::::\   \:::\    \     /:::/    / \:::\    \      \:::\   \:::\    \   
  /::::::\   \:::\    \   /:::/____/   \:::\____\   ___\:::\   \:::\    \  
 /:::/\:::\   \:::\    \ |:::|    |     |:::|    | /\   \:::\   \:::\    \ 
/:::/__\:::\   \:::\____\|:::|____|     |:::|    |/::\   \:::\   \:::\____\
\:::\   \:::\   \::/    / \:::\    \   /:::/    / \:::\   \:::\   \::/    /
 \:::\   \:::\   \/____/   \:::\    \ /:::/    /   \:::\   \:::\   \/____/ 
  \:::\   \:::\    \        \:::\    /:::/    /     \:::\   \:::\    \     
   \:::\   \:::\____\        \:::\__/:::/    /       \:::\   \:::\____\    
    \:::\   \::/    /         \::::::::/    /         \:::\  /:::/    /    
     \:::\   \/____/           \::::::/    /           \:::\/:::/    /     
      \:::\    \                \::::/    /             \::::::/    /      
       \:::\____\                \::/____/               \::::/    /       
        \::/    /                                         \::/    /        
         \/____/                                           \/____/         
EOF
}


function default_Settings() {
    CT_TYPE="l"
    PW=""
    CT_ID=$NEXTID
    HN=$NSAPP
    DISK_SIZE="$var_disk"
    CORE_COUNT="$var_cpu"
    RAM_SIZE="$var_ram"
    BRG="vmbr0"
    NET="dhcp"
    GATE=""
    APT_CACHER=""
    APT_CACHER_IP=""
    DISABLEIP6="no"
    MTU=""
    SD=""
    NS=""
    MAC=""
    VLAN=""
    SSH="no"
    VERB="no"
    echo_default
}

function ask_user() {
  local default_user="eosuser"
  echo "ℹ️  You will now be asked to specify a username for the container."
  echo "👉 Press [Enter] to use the default username '${default_user}'."
  read -p "🧑 Enter username (Default: ${default_user}): " -ei "${default_user}" APP_USER
  APP_USER=${APP_USER:-$default_user}

  while true; do
    echo -n "🔐 Enter password for user '$APP_USER': "
    read -rs APP_PASS
    echo
    echo -n "🔁 Confirm password: "
    read -rs APP_PASS2
    echo
    if [[ "$APP_PASS" != "$APP_PASS2" ]]; then
      echo "❌ Passwords do not match. Please try again."
    else
      break
    fi
  done
}

function update_script() {
  #header_info
  header_print

  LXC_ID=$CT_ID
  msg_info "📦 Installing ${APP} in container ${LXC_ID}"

  pct exec $LXC_ID -- apt update
  pct exec $LXC_ID -- apt install -y git python3 python3-pip python3-venv sudo

  # Benutzer mit Passwort anlegen und sudo-Rechte geben
  pct exec $LXC_ID -- bash -c "useradd -m -s /bin/bash $APP_USER && echo '$APP_USER:$APP_PASS' | chpasswd && usermod -aG sudo $APP_USER"

  # EOS klonen
  pct exec $LXC_ID -- sudo -u "$APP_USER" git clone https://github.com/Akkudoktor-EOS/EOS.git /home/"$APP_USER"/EOS

  # Python venv einrichten
  pct exec $LXC_ID -- bash -c "cd /home/$APP_USER/EOS && python3 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt"

  # Systemd Service erstellen
  pct exec $LXC_ID -- bash -c 'cat > /etc/systemd/system/eos.service <<EOF
[Unit]
Description=EOS Service
After=network.target

[Service]
Type=simple
ExecStart=/home/'"${APP_USER}"'/EOS/.venv/bin/python /home/'"${APP_USER}"'/EOS/eos.py
WorkingDirectory=/home/'"${APP_USER}"'/EOS
Restart=always
RestartSec=5
User='"${APP_USER}"'

[Install]
WantedBy=multi-user.target
EOF'

  # Systemd Service aktivieren
  pct exec $LXC_ID -- systemctl daemon-reexec
  pct exec $LXC_ID -- systemctl daemon-reload
  pct exec $LXC_ID -- systemctl enable eos.service
  pct exec $LXC_ID -- systemctl start eos.service
  exit
  
}

ask_user
start
build_container
description

msg_ok "✅ ${APP} successfully installed and configured as a service"