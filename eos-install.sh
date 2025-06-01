#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/tteck/Proxmox/main/misc/build.func)
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
var_disk="16"
var_cpu="4"
var_ram="2048"
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

function update_script() {
  header_info
  LXC_ID=$CT_ID
  msg_info "Installing ${APP} in container ${LXC_ID}"

  pct exec $LXC_ID -- apt-get update
  pct exec $LXC_ID -- apt-get install -y git python3 python3-pip

  pct exec $LXC_ID -- git clone https://github.com/AndreS2016/EOS.git /opt/eos

  pct exec $LXC_ID -- bash -c "if [ -f /opt/eos/requirements.txt ]; then pip3 install -r /opt/eos/requirements.txt; fi"

  pct exec $LXC_ID -- bash -c "cat <<EOF > /etc/systemd/system/eos.service

[Unit]
 Description=EOS Service
 After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /opt/eos/main.py
WorkingDirectory=/opt/eos
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF"

  pct exec $LXC_ID -- systemctl daemon-reexec
  pct exec $LXC_ID -- systemctl daemon-reload
  pct exec $LXC_ID -- systemctl enable eos.service
  pct exec $LXC_ID -- systemctl start eos.service

  msg_ok "${APP} installation and systemd setup complete"
}

start
build_container
description

msg_ok "Completed Successfully!\n"