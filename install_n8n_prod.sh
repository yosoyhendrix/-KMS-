#!/bin/bash

# --- Configuración ---
N8N_DATA_DIR="/var/lib/n8n"
N8N_PORT=5678
YOUR_DOMAIN_OR_IP="ia.yosoyhendrix.com" # ¡IMPORTANTE! Reemplaza esto con tu dominio o IP real

# --- Colores para la salida ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Iniciando la instalación de n8n con Docker en Ubuntu 24.04...${NC}"

# 1. Actualizar el sistema
echo -e "${GREEN}1. Actualizando el sistema...${NC}"
sudo apt update && sudo apt upgrade -y
if [ $? -ne 0 ]; then
    echo -e "${RED}Error al actualizar el sistema. Saliendo.${NC}"
    exit 1
fi

# 2. Instalar Docker
echo -e "${GREEN}2. Instalando Docker...${NC}"
sudo apt install -y ca-certificates curl gnupg lsb-release
if [ $? -ne 0 ]; then
    echo -e "${RED}Error al instalar dependencias de Docker. Saliendo.${NC}"
    exit 1
fi

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
if [ $? -ne 0 ]; then
    echo -e "${RED}Error al descargar la clave GPG de Docker. Saliendo.${NC}"
    exit 1
fi

sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}Error al añadir el repositorio de Docker. Saliendo.${NC}"
    exit 1
fi

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
if [ $? -ne 0 ]; then
    echo -e "${RED}Error al instalar Docker. Saliendo.${NC}"
    exit 1
fi

# Añadir el usuario actual al grupo docker para ejecutar comandos sin sudo
sudo usermod -aG docker "$USER"
echo -e "${YELLOW}¡Importante! Necesitarás cerrar sesión y volver a iniciarla o reiniciar para que los cambios del grupo Docker surtan efecto.${NC}"

# 3. Crear directorio para los datos de n8n
echo -e "${GREEN}3. Creando el directorio para los datos de n8n: ${N8N_DATA_DIR}${NC}"
sudo mkdir -p "$N8N_DATA_DIR"
sudo chmod -R 777 "$N8N_DATA_DIR" # Asegurar permisos de escritura para el contenedor
if [ $? -ne 0 ]; then
    echo -e "${RED}Error al crear el directorio de datos de n8n. Saliendo.${NC}"
    exit 1
fi

# **CORRECCIÓN:** Crear el directorio /opt/n8n antes de intentar crear el archivo docker-compose.yml
echo -e "${GREEN}4. Creando el directorio /opt/n8n...${NC}"
sudo mkdir -p /opt/n8n
if [ $? -ne 0 ]; then
    echo -e "${RED}Error al crear el directorio /opt/n8n. Saliendo.${NC}"
    exit 1
fi

# 5. Crear el archivo docker-compose.yml
echo -e "${GREEN}5. Creando el archivo docker-compose.yml...${NC}"
cat <<EOF | sudo tee /opt/n8n/docker-compose.yml
version: '3.8'

services:
  n8n:
    image: n8nio/n8n
    restart: always
    ports:
      - "${N8N_PORT}:5678"
    environment:
      - N8N_HOST=${YOUR_DOMAIN_OR_IP}
      - WEBHOOK_URL=http://${YOUR_DOMAIN_OR_IP}:${N8N_PORT}/
      - N8N_PORT=5678
      - GENERIC_TIMEZONE=America/Santo_Domingo # Ajusta tu zona horaria si es diferente
      # - N8N_EDITOR_BASE_URL=http://${YOUR_DOMAIN_OR_IP}:${N8N_PORT}/ # Descomentar si usas un proxy inverso
      # - N8N_DEFAULT_EMAIL=tu_email@ejemplo.com # Opcional: para notificaciones
      # - N8N_DEFAULT_USER_EMAIL=tu_email@ejemplo.com # Opcional: para el primer usuario
      # - N8N_DEFAULT_USER_PASSWORD=tu_contraseña_segura # Opcional: para el primer usuario
    volumes:
      - ${N8N_DATA_DIR}:/home/node/.n8n
    networks:
      - n8n_network

networks:
  n8n_network:
    driver: bridge
EOF

if [ $? -ne 0 ]; then
    echo -e "${RED}Error al crear el archivo docker-compose.yml. Saliendo.${NC}"
    exit 1
fi

echo -e "${GREEN}Archivo docker-compose.yml creado en /opt/n8n/docker-compose.yml${NC}"

# 6. Iniciar n8n con Docker Compose
echo -e "${GREEN}6. Iniciando n8n con Docker Compose...${NC}"
sudo docker compose -f /opt/n8n/docker-compose.yml up -d
if [ $? -ne 0 ]; then
    echo -e "${RED}Error al iniciar n8n con Docker Compose. Saliendo.${NC}"
    exit 1
fi

# 7. Configurar Firewall (UFW)
echo -e "${GREEN}7. Configurando el firewall (UFW)...${NC}"
sudo apt install -y ufw
sudo ufw allow OpenSSH
sudo ufw allow "$N8N_PORT"/tcp comment "Allow n8n traffic"
sudo ufw enable
if [ $? -ne 0 ]; then
    echo -e "${RED}Error al configurar el firewall. Saliendo.${NC}"
    exit 1
fi
echo -e "${GREEN}Firewall configurado. Puerto ${N8N_PORT} abierto.${NC}"

echo -e "${GREEN}8. Verificando el estado de n8n...${NC}"
docker ps -f "name=n8n"
if [ $? -ne 0 ]; then
    echo -e "${RED}Parece que el contenedor de n8n no se está ejecutando. Revisa los logs.${NC}"
    exit 1
fi

echo -e "${GREEN}¡Instalación de n8n completada!${NC}"
echo -e "${YELLOW}Puedes acceder a n8n en: http://${YOUR_DOMAIN_OR_IP}:${N8N_PORT}/${NC}"
echo -e "${YELLOW}Recuerda reemplazar 'your_domain_or_IP' con tu dirección IP o dominio real.${NC}"
echo -e "${YELLOW}n8n se configurará para iniciarse automáticamente al reiniciar el servidor gracias a 'restart: always' en el docker-compose.${NC}"
echo -e "${YELLOW}Para la persistencia de datos, los datos de n8n se guardan en: ${N8N_DATA_DIR}${NC}"
echo -e "${YELLOW}Si vas a usar un dominio, considera configurar Nginx y Let's Encrypt para HTTPS.${NC}"
echo -e "${YELLOW}¡Para usar n8n con modelos de IA, explora los nodos de integración de n8n para servicios como OpenAI, Hugging Face, o construye tus propios nodos personalizados!${NC}"

exit 0
