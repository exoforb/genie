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

# Warna untuk output
GREEN='\033[0;32m'
NC='\033[0m' # No Color
RED='\033[0;31m'

# Ambil IP lokal
local_ip=$(hostname -I | awk '{print $1}')

echo -e "${GREEN}================= STEP 1: Install Node.js v18 =================${NC}"
# Fungsi untuk cek versi Node.js
check_node_version() {
    if command -v node > /dev/null 2>&1; then
        NODE_VERSION=$(node -v | cut -d 'v' -f 2)
        NODE_MAJOR_VERSION=$(echo "$NODE_VERSION" | cut -d '.' -f 1)

        if [ "$NODE_MAJOR_VERSION" -eq 18 ]; then
            return 0  # Versi cocok
        else
            return 1  # Versi tidak cocok
        fi
    else
        return 1  # Node tidak ditemukan
    fi
}

# Eksekusi pengecekan
if check_node_version; then
    NODE_VERSION=$(node -v | cut -d 'v' -f 2)
    echo -e "${GREEN}============================================================================${NC}"
    echo -e "${GREEN}=========== Node.js versi ${NODE_VERSION} sudah terinstall. ================${NC}"
    echo -e "${GREEN}========================= Lanjut install Mongo DB ==========================${NC}"
    echo -e "${GREEN}============================================================================${NC}"
else
    echo -e "${GREEN}Node.js belum terinstall atau versinya tidak sesuai. Menginstal versi 18...${NC}"
    # Install Node.js v18
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
fi

# Cek ulang setelah install
if ! check_node_version; then
    echo -e "${RED}Gagal menginstal Node.js versi 18.${NC}"
    exit 1
fi

# Tampilkan versi Node.js
echo -e "${GREEN}Node.js version: $(node -v)${NC}"

echo -e "${GREEN}================= STEP 2: Install MongoDB v7.0 =================${NC}"
# Cek apakah MongoDB sudah aktif
if sudo systemctl is-active --quiet mongod; then
    echo -e "${GREEN}============================================================================${NC}"
    echo -e "${GREEN}=================== MongoDB sudah terinstall sebelumnya. ===================${NC}"
    echo -e "${GREEN}=================== Lanjut Menginstal GenieACS =============================${NC}"
    echo -e "${GREEN}============================================================================${NC}"
else
    # Tambahkan repository MongoDB v7.0 (update sesuai kebutuhan)
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

    # Tambahkan GPG key
    wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor | sudo tee /usr/share/keyrings/mongodb-server-7.0.gpg > /dev/null

    # Update dan install
    sudo apt update
    sudo apt install -y mongodb-org

    # Enable dan start MongoDB
    sudo systemctl enable --now mongod

    # Cek lagi apakah MongoDB berhasil aktif
    if ! sudo systemctl is-active --quiet mongod; then
        echo -e "${RED}MongoDB gagal diinstal atau tidak berjalan dengan benar.${NC}"
        exit 1
    fi
fi

# Tampilkan versi MongoDB
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

cd ..
sudo mongorestore --db=genieacs --drop genie
