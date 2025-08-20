#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'
local_ip=$(hostname -I | awk '{print $1}') 

echo -e "${GREEN}============================ Install GenieACS. =============================${NC}"
echo -e "${GREEN}======================== NodeJS, MongoDB, GenieACS, ========================${NC}"

echo -e "${GREEN}Sebelum melanjutkan, silahkan baca terlebih dahulu. Apakah anda ingin melanjutkan? (y/n)${NC}"
read confirmation

if [ "$confirmation" != "y" ]; then
    echo -e "${GREEN}Install dibatalkan..${NC}"
    exit 1
fi

for ((i = 5; i >= 1; i--)); do
	sleep 1
    echo "Tunggu Untuk Melanjutkan... $i. Tekan ctrl+c untuk membatalkan"
done

set -e

echo -e "${GREEN}================= STEP 1: Check Node.js v18 =================${NC}"
if command -v node > /dev/null 2>&1; then
    NODE_VERSION=$(node -v | cut -d 'v' -f 2)
    echo -e "${GREEN}Node.js versi ${NODE_VERSION} sudah terinstall.${NC}"
else
    echo -e "${GREEN}Installing Node.js v18...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
fi

echo -e "${GREEN}================= STEP 2: MongoDB (Manual Installation Required) =================${NC}"
echo -e "${YELLOW}Pastikan MongoDB sudah terinstall secara manual sebelum melanjutkan.${NC}"

echo -e "${GREEN}================= STEP 3: Install GenieACS 1.2.13 ================${NC}"

if ! systemctl is-active --quiet genieacs-cwmp 2>/dev/null; then
    echo -e "${GREEN}Installing GenieACS...${NC}"
    npm install -g genieacs@1.2.13

    useradd --system --no-create-home --user-group genieacs || true

    mkdir -p /opt/genieacs/ext
    chown genieacs:genieacs /opt/genieacs/ext

    cat << 'EOF' > /opt/genieacs/genieacs.env
GENIEACS_CWMP_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-cwmp-access.log
GENIEACS_NBI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-nbi-access.log
GENIEACS_FS_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-fs-access.log
GENIEACS_UI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-ui-access.log
GENIEACS_DEBUG_FILE=/var/log/genieacs/genieacs-debug.yaml
GENIEACS_EXT_DIR=/opt/genieacs/ext
GENIEACS_UI_JWT_SECRET=secret
EOF

    chown genieacs:genieacs /opt/genieacs/genieacs.env
    chown -R genieacs:genieacs /opt/genieacs
    chmod 600 /opt/genieacs/genieacs.env

    mkdir -p /var/log/genieacs
    chown genieacs:genieacs /var/log/genieacs

    # Create service files
    cat << 'EOF' > /etc/systemd/system/genieacs-cwmp.service
[Unit]
Description=GenieACS CWMP
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-cwmp

[Install]
WantedBy=default.target
EOF

    cat << 'EOF' > /etc/systemd/system/genieacs-nbi.service
[Unit]
Description=GenieACS NBI
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-nbi

[Install]
WantedBy=default.target
EOF

    cat << 'EOF' > /etc/systemd/system/genieacs-fs.service
[Unit]
Description=GenieACS FS
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-fs

[Install]
WantedBy=default.target
EOF

    cat << 'EOF' > /etc/systemd/system/genieacs-ui.service
[Unit]
Description=GenieACS UI
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-ui

[Install]
WantedBy=default.target
EOF

    # Logrotate
    cat << 'EOF' > /etc/logrotate.d/genieacs
/var/log/genieacs/*.log /var/log/genieacs/*.yaml {
    daily
    rotate 30
    compress
    delaycompress
    dateext
}
EOF

    systemctl daemon-reload
    systemctl enable --now genieacs-{cwmp,fs,ui,nbi}

    echo -e "${GREEN}================== Sukses install GenieACS ==================${NC}"
else
    echo -e "${GREEN}GenieACS sudah terinstall dan berjalan.${NC}"
fi

echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}========== GenieACS UI akses port 3000. : http://$local_ip:3000 ============${NC}"
echo -e "${GREEN}============================================================================${NC}"

# CSS Custom
echo -e "${GREEN}Apakah Anda ingin menginstall tampilan CSS kustom untuk GenieACS? (y/n)${NC}"
read install_css

if [ "$install_css" == "y" ]; then
    echo -e "${GREEN}Install custom CSS genieACS...${NC}"
    
    if [ -f "app-LU66VFYW.css" ] && [ -f "logo-3976e73d.svg" ]; then
        sudo cp app-LU66VFYW.css /usr/lib/node_modules/genieacs/public/
        sudo cp logo-3976e73d.svg /usr/lib/node_modules/genieacs/public/
        echo -e "${GREEN}Custom CSS sudah terinstall.${NC}"
    else
        echo -e "${RED}❌ File CSS atau logo tidak ditemukan.${NC}"
    fi
else
    echo -e "${GREEN}Lewati install CSS kustom.${NC}"
fi

# Restore parameter MongoDB
echo -e "${GREEN}Sekarang install parameter GenieACS. Lanjutkan? (y/n)${NC}"
read confirmation

if [ "$confirmation" != "y" ]; then
    echo -e "${GREEN}Install dibatalkan..${NC}"
    exit 1
fi

for ((i = 5; i >= 1; i--)); do
    sleep 1
    echo "Lanjut Install Parameter $i. Tekan ctrl+c untuk membatalkan"
done

# Cek apakah mongorestore tersedia
if ! command -v mongorestore > /dev/null 2>&1; then
    echo -e "${GREEN}Installing mongodb-database-tools untuk mongorestore...${NC}"
    sudo apt install -y mongodb-database-tools
fi

cd ..
sudo mongorestore --db=genieacs --drop genie
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}========================= Semua sudah terinstall ===========================${NC}"
echo -e "${GREEN}============================== By Exo Net ==================================${NC}"
echo -e "${GREEN}============================================================================${NC}"
