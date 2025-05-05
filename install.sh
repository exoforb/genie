#!/bin/bash
url_install='https://srv.ddns.my.id/genieacs/genieacs/'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
local_ip=$(hostname -I | awk '{print $1}')
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}=========================  ________  __  ____  =============================${NC}"
echo -e "${GREEN}========================= |  ____\ \/ / / __ \ =============================${NC}"
echo -e "${GREEN}========================= | |__   \  / | |  | |=============================${NC}"
echo -e "${GREEN}========================= |  __|   / /  | |  | |=============================${NC}"
echo -e "${GREEN}========================= | |____ / /__ | |__| |=============================${NC}"
echo -e "${GREEN}========================= |______|____(_)____/ =============================${NC}"
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}============================ Install GenieACS. =============================${NC}"
echo -e "${GREEN}======================== NodeJS, MongoDB, GenieACS, ========================${NC}"
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}Sebelum melanjutkan, silahkan baca terlebih dahulu. Apakah anda ingin melanjutkan? (y/n)${NC}"
read confirmation

if [ "$confirmation" != "y" ]; then
    echo -e "${GREEN}Install dibatalkan..${NC}"
   
    exit 1
fi
for ((i = 5; i >= 1; i--)); do
	sleep 1
    echo "Lanjut Boskuh... $i. Tekan ctrl+c untuk membatalkan"
done

#!/bin/bash

set -e

GREEN='\033[0;32m'
NC='\033[0m'

# Ambil IP lokal
local_ip=$(hostname -I | awk '{print $1}')

echo -e "${GREEN}================= STEP 1: Install Node.js v18 =================${NC}"
# Tambahkan repositori NodeSource untuk Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# Install Node.js
sudo apt install -y nodejs

echo -e "${GREEN}Node.js version: $(node -v)${NC}"

echo -e "${GREEN}================= STEP 2: Install MongoDB v6.0 =================${NC}"
wget -qO - https://pgp.mongodb.com/server-6.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-6.0.gpg

echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list

apt update
apt install -y mongodb-org
systemctl enable --now mongod

echo -e "${GREEN}MongoDB version: $(mongod --version | grep "db version")${NC}"

echo -e "${GREEN}================= STEP 3: Install GenieACS 1.2.13 ================${NC}"

if ! systemctl is-active --quiet genieacs-cwmp; then
    npm install -g genieacs@1.2.13

    useradd --system --no-create-home --user-group genieacs || true

    mkdir -p /opt/genieacs/ext
    chown genieacs:genieacs /opt/genieacs/ext

    cat << EOF > /opt/genieacs/genieacs.env
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
    cat << EOF > /etc/systemd/system/genieacs-cwmp.service
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

    cat << EOF > /etc/systemd/system/genieacs-nbi.service
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

    cat << EOF > /etc/systemd/system/genieacs-fs.service
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

    cat << EOF > /etc/systemd/system/genieacs-ui.service
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
    cat << EOF > /etc/logrotate.d/genieacs
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
    echo -e "${GREEN}GenieACS sudah terinstall sebelumnya.${NC}"
fi

echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}========== GenieACS UI akses port 3000. : http://$local_ip:3000 ============${NC}"
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}============================================================================${NC}"

# Restore parameter MongoDB
echo -e "${GREEN}Sekarang install parameter default GenieACS. Lanjutkan? (y/n)${NC}"
read confirmation

if [ "$confirmation" != "y" ]; then
    echo -e "${GREEN}Install dibatalkan..${NC}"
    exit 1
fi

for ((i = 5; i >= 1; i--)); do
    sleep 1
    echo "Lanjut Install Parameter $i. Tekan ctrl+c untuk membatalkan"
done

cd -
sudo mongorestore --db=genieacs --drop new-genieacs
