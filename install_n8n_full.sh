#!/bin/bash

# --- Configuración para la limpieza ---
N8N_USER="n8nuser" # El usuario que se intentó crear para n8n
N8N_DIR="/opt/n8n" # El directorio de instalación de n8n
NVM_DIR_USER="/home/$N8N_USER/.nvm" # Directorio de NVM si se creó para n8nuser
NVM_DIR_ROOT="/root/.nvm" # Directorio de NVM si se instaló para el usuario root
YOUR_DOMAIN="n8n.example.com" # <--- ¡CAMBIA ESTO al dominio que usaste en el script anterior!

# --- Colores para la salida del script ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}--- Iniciando script de limpieza profunda para n8n y componentes relacionados ---${NC}"
echo -e "${RED}¡ADVERTENCIA! Este script eliminará datos y configuraciones. ¡Úsalo con precaución!${NC}"
sleep 5 # Pausa de 5 segundos para que el usuario lea la advertencia

# --- 1. Detener y limpiar procesos PM2 ---
echo -e "${GREEN}Intentando detener y eliminar procesos PM2 de n8n...${NC}"
# Intentar detener y eliminar pm2 bajo el usuario n8nuser
if id -u "$N8N_USER" >/dev/null 2>&1; then
    echo -e "${YELLOW}Limpiando PM2 para el usuario '$N8N_USER'...${NC}"
    # Ejecuta pm2 directamente si es posible, ya que el PATH podría no estar configurado.
    PM2_BIN_PATH=$(sudo su - "$N8N_USER" -c "export NVM_DIR=\"$NVM_DIR_USER\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\" && nvm use --lts > /dev/null 2>&1 && npm bin -g 2>/dev/null")/pm2
    if [ -x "$PM2_BIN_PATH" ]; then
        sudo su - "$N8N_USER" -c "$PM2_BIN_PATH stop n8n || true"
        sudo su - "$N8N_USER" -c "$PM2_BIN_PATH delete n8n || true"
        sudo su - "$N8N_USER" -c "$PM2_BIN_PATH unstartup systemd || true"
        sudo su - "$N8N_USER" -c "pm2 kill || true" # PM2 master process
    else
        echo -e "${YELLOW}PM2 no encontrado o no ejecutable para '$N8N_USER'.${NC}"
    fi
fi

# Eliminar cualquier rastro de PM2 globalmente (si se instaló como root o con sudo)
echo -e "${YELLOW}Eliminando PM2 de instalaciones globales y temporales...${NC}"
sudo npm uninstall -g pm2 || true
sudo rm -rf /usr/local/lib/node_modules/pm2 || true
sudo rm -rf ~/.pm2 || true
sudo rm -rf /root/.pm2 || true
sudo rm -rf /tmp/pm2* || true

# --- 2. Eliminar n8n globalmente ---
echo -e "${GREEN}Eliminando n8n globalmente...${NC}"
sudo npm uninstall -g n8n || true
sudo rm -rf /usr/local/lib/node_modules/n8n || true

# --- 3. Desinstalar Nginx y limpiar configuraciones ---
echo -e "${GREEN}Desinstalando Nginx y limpiando sus configuraciones...${NC}"
sudo systemctl stop nginx || true
sudo systemctl disable nginx || true
sudo rm -f /etc/nginx/sites-enabled/"$YOUR_DOMAIN" || true
sudo rm -f /etc/nginx/sites-available/"$YOUR_DOMAIN" || true
sudo apt purge nginx -y || true
sudo apt autoremove -y || true
sudo rm -rf /etc/nginx/conf.d/* || true # Eliminar posibles configuraciones residuales
sudo rm -rf /etc/nginx/sites-enabled/* || true
sudo rm -rf /etc/nginx/sites-available/* || true

# --- 4. Eliminar certificados de Certbot ---
echo -e "${GREEN}Eliminando certificados SSL de Certbot para '$YOUR_DOMAIN'...${NC}"
sudo certbot delete --cert-name "$YOUR_DOMAIN" || true
sudo apt purge certbot -y || true
sudo snap remove certbot || true # Para instalaciones con snap

# --- 5. Eliminar usuario y directorios de n8n ---
echo -e "${GREEN}Eliminando usuario '$N8N_USER' y sus directorios...${NC}"
if id -u "$N8N_USER" >/dev/null 2>&1; then
    sudo deluser --remove-home "$N8N_USER" || true
    echo "Usuario '$N8N_USER' y su directorio home eliminados."
else
    echo "El usuario '$N8N_USER' no existe o ya ha sido eliminado."
fi
sudo rm -rf "$N8N_DIR" || true # Directorio de instalación principal de n8n

# --- 6. Limpiar NVM y Node.js ---
echo -e "${GREEN}Limpiando instalaciones de NVM y Node.js...${NC}"
# Eliminar NVM del usuario que ejecutó el script (usualmente root o tu usuario principal)
rm -rf "$NVM_DIR_ROOT" || true
# Y del n8nuser si se creó
rm -rf "$NVM_DIR_USER" || true

# Eliminar PATHs de NVM del .bashrc o .profile del usuario que ejecuta el script
sed -i '/NVM_DIR/d' ~/.bashrc || true
sed -i '/NVM_DIR/d' ~/.profile || true
# Puedes necesitar cerrar la sesión SSH y volver a conectarte para que esto tenga efecto.

# --- 7. Limpiar UFW (Firewall) ---
echo -e "${GREEN}Restableciendo UFW (Firewall)...${NC}"
sudo ufw --force reset || true # Restablece UFW a sus valores por defecto (todo bloqueado)
sudo ufw allow 22/tcp || true # Vuelve a permitir SSH
sudo ufw enable || true
echo "y" | sudo ufw enable || true

echo -e "${YELLOW}--- Proceso de limpieza completado ---${NC}"
echo -e "${YELLOW}Por favor, considera reiniciar tu VPS para asegurar que todos los servicios y configuraciones antiguas se limpien por completo:${NC}"
echo -e "${YELLOW}  sudo reboot${NC}"

