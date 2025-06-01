#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/tteck/Proxmox/main/misc/build.func)
function ask_user() { ... }
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

# Version: 1.0.0
function header_info() {
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
header_info
echo -e "Loading..."
APP="EOS"
var_disk="32"
var_cpu="4"
var_ram="4096"
var_os="debian"
var_version="12"
variables
color
catch_errors

# This script is used to set up the environment for the EOS project.
# It sets the EOS_HOME variable to the current directory and adds the bin directory to the PATH.

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
  read -rp "🧑 Bitte gewünschten Benutzername angeben (wird im Container erstellt): " APP_USER
  [[ -z "$APP_USER" ]] && { echo "❌ Benutzername darf nicht leer sein."; exit 1; }
}

function update_script() {
  header_info
  LXC_ID=$CT_ID
  msg_info "📦 Installiere ${APP} in Container ${LXC_ID}"

  pct exec $LXC_ID -- apt update
  pct exec $LXC_ID -- apt install -y git python3 python3-pip python3-venv sudo

  # Benutzer anlegen
  pct exec $LXC_ID -- adduser --disabled-password --gecos "" "$APP_USER"
  pct exec $LXC_ID -- usermod -aG sudo "$APP_USER"

  # EOS klonen
  pct exec $LXC_ID -- sudo -u "$APP_USER" git clone https://github.com/Akkudoktor-EOS/EOS.git /home/"$APP_USER"/EOS

  # Python venv einrichten
  pct exec $LXC_ID -- bash -c "cd /home/$APP_USER/eos && python3 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt || true"

  # Systemd Service erstellen
pct exec $LXC_ID -- bash -c 'cat <<EOF > /etc/systemd/system/eos.service
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


    # Systemd Service erstellen
  pct exec $LXC_ID -- systemctl daemon-reexec
  pct exec $LXC_ID -- systemctl daemon-reload
  pct exec $LXC_ID -- systemctl enable eos.service
  pct exec $LXC_ID -- systemctl start eos.service

  msg_ok "✅ ${APP} erfolgreich installiert und als Service eingerichtet"
}

ask_user
start
build_container
description

