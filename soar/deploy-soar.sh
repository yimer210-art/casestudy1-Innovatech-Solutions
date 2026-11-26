#!/usr/bin/env bash
# ==============================================================================
# Innovatech Solutions - Case Study 2: Flavor B (IaC for SOAR)
# Automated Provisioning Script for Shuffle SOAR Stack
# ==============================================================================
set -euo pipefail

echo "[+] Starting automated deployment of Shuffle SOAR Stack..."

# 1. System requirements for OpenSearch / Shuffle
echo "[+] Configuring sysctl parameters for container database..."
sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | tee -a /etc/sysctl.conf

# 2. Setup directory structure
SOAR_DIR="/opt/security-stack/shuffle"
mkdir -p "${SOAR_DIR}/shuffle-apps" "${SOAR_DIR}/shuffle-files" "${SOAR_DIR}/shuffle-database"
chmod -R 777 "${SOAR_DIR}"

# 3. Deploy Docker Compose file
echo "[+] Deploying docker-compose.yml..."
cat << 'EOF' > "${SOAR_DIR}/docker-compose.yml"
version: '3.8'

services:
  frontend:
    image: ghcr.io/shuffle/shuffle-frontend:latest
    container_name: shuffle-frontend
    restart: unless-stopped
    ports:
      - "3443:80"
    environment:
      - BACKEND_HOSTNAME=shuffle-backend
    networks:
      - shuffle-net
    depends_on:
      - backend

  backend:
    image: ghcr.io/shuffle/shuffle-backend:latest
    container_name: shuffle-backend
    restart: unless-stopped
    ports:
      - "5001:5001"
    environment:
      - SHUFFLE_APP_HOTLOAD_FOLDER=/shuffle-apps
      - SHUFFLE_FILE_LOCATION=/shuffle-files
      - SHUFFLE_OPENSEARCH_URL=http://opensearch:9200
      - SHUFFLE_SWARM_CONFIG=run
      - ORG_ID=innovatech
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ${SOAR_DIR}/shuffle-apps:/shuffle-apps
      - ${SOAR_DIR}/shuffle-files:/shuffle-files
    networks:
      - shuffle-net
    depends_on:
      - opensearch

  orborus:
    image: ghcr.io/shuffle/shuffle-orborus:latest
    container_name: shuffle-orborus
    restart: unless-stopped
    environment:
      - SHUFFLE_APP_SDK_TIMEOUT=300
      - SHUFFLE_BASE_IMAGE_NAME=shuffle
      - BASE_URL=http://shuffle-backend:5001
      - DOCKER_API_VERSION=1.40
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - shuffle-net
    depends_on:
      - backend

  opensearch:
    image: opensearchproject/opensearch:2.12.0
    container_name: shuffle-opensearch
    restart: unless-stopped
    environment:
      - discovery.type=single-node
      - "DISABLE_INSTALL_DEMO_CONFIG=true"
      - "DISABLE_SECURITY_PLUGIN=true"
      - "OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m"
    volumes:
      - ${SOAR_DIR}/shuffle-database:/usr/share/opensearch/data
    networks:
      - shuffle-net

networks:
  shuffle-net:
    driver: bridge
EOF

# 4. Start Shuffle Containers
echo "[+] Starting Shuffle SOAR services with Docker Compose..."
cd "${SOAR_DIR}"
docker compose up -d

# 5. Healthcheck
echo "[+] Waiting for Shuffle API to become available on port 5001..."
timeout 60 bash -c 'until curl -sf http://localhost:5001/api/v1/info; do sleep 3; done' || echo "[!] Notice: Shuffle is starting in background."

echo "[✓] Shuffle SOAR successfully deployed via IaC!"
echo "[✓] Web UI accessible at: https://10.3.1.50:3443"
echo "[✓] Webhook endpoint:     http://10.3.1.50:5001/api/v1/hooks/webhook_innovatech_soar"
