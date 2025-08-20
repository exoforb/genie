#!/bin/bash
url_install='https://srv.ddns.my.id/genieacs/genieacs/'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'
local_ip=$(hostname -I | awk '{print $1}') 
echo -e "${GREEN}		                              _   			     ${NC}"
echo -e "${GREEN}		                             | |  		             ${NC}"
echo -e "${GREEN}		   _____  _____    _ __   ___| |_ 			     ${NC}"
echo -e "${GREEN}		  / _ \ \/ / _ \  | '_ \ / _ \ __|		     	     ${NC}"
echo -e "${GREEN}		 |  __/>  < (_) | | | | |  __/ |_ 			     ${NC}"
echo -e "${GREEN}		  \___/_/\_\___/  |_| |_|\___|\__|			     ${NC}"



      
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

#!/bin/bash

set -e

# Warna untuk output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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





echo -e "${GREEN}================= STEP 2: Install MongoDB (Auto-detect version) =================${NC}"

# Install dependencies untuk MongoDB
sudo apt update
sudo apt install -y gnupg curl

# Fungsi untuk cek CPU support AVX
check_avx_support() {
    if grep -q avx /proc/cpuinfo; then
        return 0  # CPU support AVX
    else
        return 1  # CPU tidak support AVX
    fi
}

# Fungsi untuk cek CPU support AVX2
check_avx2_support() {
    if grep -q avx2 /proc/cpuinfo; then
        return 0  # CPU support AVX2
    else
        return 1  # CPU tidak support AVX2
    fi
}

# Tentukan versi MongoDB berdasarkan CPU
echo -e "${YELLOW}Checking CPU compatibility...${NC}"
if check_avx2_support; then
    MONGODB_VERSION="7.0"
    echo -e "${GREEN}✅ CPU supports AVX2 - Installing MongoDB 7.0${NC}"
elif check_avx_support; then
    MONGODB_VERSION="6.0"
    echo -e "${GREEN}✅ CPU supports AVX - Installing MongoDB 6.0${NC}"
else
    MONGODB_VERSION="4.4"
    echo -e "${YELLOW}⚠️ CPU doesn't support AVX - Installing MongoDB 4.4${NC}"
fi

# Fungsi untuk cek versi MongoDB yang terinstall
check_mongo_version() {
    if sudo systemctl is-active --quiet mongod; then
        # Coba dengan mongosh dulu (MongoDB 5.0+)
        if command -v mongosh > /dev/null 2>&1; then
            MONGO_VERSION=$(mongosh --quiet --eval "db.version()" 2>/dev/null | head -1)
        # Fallback ke mongo (MongoDB 4.4 dan older)
        elif command -v mongo > /dev/null 2>&1; then
            MONGO_VERSION=$(mongo --quiet --eval "db.version()" 2>/dev/null | head -1)
        else
            return 1
        fi
        
        MONGO_MAJOR_VERSION=$(echo "$MONGO_VERSION" | cut -d '.' -f 1)
        EXPECTED_MAJOR=$(echo "$MONGODB_VERSION" | cut -d '.' -f 1)
        
        if [ "$MONGO_MAJOR_VERSION" -eq "$EXPECTED_MAJOR" ]; then
            return 0  # Versi cocok
        fi
    fi
    return 1  # Tidak cocok atau tidak terinstall
}

# Eksekusi pengecekan
if check_mongo_version; then
    echo -e "${GREEN}============================================================================${NC}"
    echo -e "${GREEN}=========== MongoDB versi ${MONGO_VERSION} sudah terinstall. ================${NC}"
    echo -e "${GREEN}=================== Lanjut Menginstal GenieACS =============================${NC}"
    echo -e "${GREEN}============================================================================${NC}"
else
    echo -e "${GREEN}MongoDB belum terinstall atau versinya tidak sesuai. Menginstal MongoDB v${MONGODB_VERSION}...${NC}"

    # Hapus repo MongoDB lama jika ada
    sudo rm -f /etc/apt/sources.list.d/mongodb*.list
    sudo rm -f /usr/share/keyrings/mongodb*.gpg
    sudo apt-key del $(apt-key list | grep -i mongodb | awk '{print $2}' | cut -d '/' -f 2) 2>/dev/null || true

    # Install MongoDB berdasarkan versi yang dipilih
    if [ "$MONGODB_VERSION" = "7.0" ]; then
        # MongoDB 7.0
        curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
        echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
        
    elif [ "$MONGODB_VERSION" = "6.0" ]; then
        # MongoDB 6.0
        curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-6.0.gpg
        echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
        
    else
        # MongoDB 4.4 (untuk CPU lama)
        wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
        # Gunakan focal repo untuk MongoDB 4.4 (karena tidak ada untuk jammy)
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
    fi

    # Update & install MongoDB
    sudo apt update
    sudo apt install -y mongodb-org

    # Enable & start MongoDB
    sudo systemctl enable --now mongod
    
    # Tunggu MongoDB siap
    echo -e "${GREEN}Menunggu MongoDB siap...${NC}"
    for i in {1..30}; do
        if sudo systemctl is-active --quiet mongod; then
            echo -e "${GREEN}MongoDB berhasil dijalankan!${NC}"
            break
        fi
        sleep 1
    done
fi

# Verifikasi ulang instalasi MongoDB
if ! check_mongo_version; then
    echo -e "${RED}Gagal menginstal MongoDB versi ${MONGODB_VERSION}.${NC}"
    echo -e "${RED}Cek log: sudo journalctl -xeu mongod${NC}"
    exit 1
fi





echo -e "${GREEN}================= STEP 3: Install GenieACS 1.2.13 ================${NC}"

if ! systemctl is-active --quiet genieacs-cwmp; then
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
    echo -e "${GREEN}============================================================================${NC}"
    echo -e "${GREEN}================ GenieACS 1.2.13 sudah terinstall.==========================${NC}"
    echo -e "${GREEN}=================== Lanjut Install Parameter ===============================${NC}"
    echo -e "${GREEN}============================================================================${NC}"
fi

echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}========== GenieACS UI akses port 3000. : http://$local_ip:3000 ============${NC}"
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}============================================================================${NC}"

# CSS Custom
echo -e "${GREEN}Apakah Anda ingin menginstall tampilan CSS kustom untuk GenieACS? (y/n)${NC}"
read install_css

if [ "$install_css" == "y" ]; then
    echo -e "${GREEN}Install custom CSS genieACS...${NC}"
    
    if [ -f "app-LU66VFYW.css" ] && [ -f "logo-3976e73d.svg" ]; then
        sudo cp app-LU66VFYW.css /usr/lib/node_modules/genieacs/public/
        sudo cp logo-3976e73d.svg /usr/lib/node_modules/genieacs/public/
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}======================= Custom CSS sudah terinstall. =======================${NC}"
echo -e "${GREEN}========================= Lanjut install Parameter ==========================${NC}"
echo -e "${GREEN}============================================================================${NC}"
    else
        echo -e "${RED}❌ File CSS atau logo tidak ditemukan di folder ./genie. Pastikan file tersebut ada.${NC}"
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
    # Untuk MongoDB 4.4, gunakan versi tools yang compatible
    if [ "$MONGODB_VERSION" = "4.4" ]; then
        wget https://fastdl.mongodb.org/tools/db/mongodb-database-tools-ubuntu2004-x86_64-100.9.0.deb
        sudo dpkg -i mongodb-database-tools-ubuntu2004-x86_64-100.9.0.deb
        rm mongodb-database-tools-ubuntu2004-x86_64-100.9.0.deb
    else
        sudo apt install -y mongodb-database-tools
    fi
fi

cd ..
sudo mongorestore --db=genieacs --drop genie
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}========================= Semua sudah terinstall ===========================${NC}"
echo -e "${GREEN}============================== By Exo Net ==================================${NC}"
echo -e "${GREEN}============================================================================${NC}"
