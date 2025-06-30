#!/bin/bash

# --- Configuración Inicial ---
N8N_VERSION="latest" # Puedes especificar una versión como "1.37.2"
N8N_USER="n8nuser" # Usuario bajo el cual correrá n8n (se creará si no existe)
N8N_DIR="/opt/n8n" # Directorio donde se instalará n8n
N8N_PORT="5678" # Puerto interno de n8n (Nginx se encargará del 80/443)
N8N_TIMEZONE="America/Santo_Domingo" # Ajusta tu zona horaria
N8N_ENCRYPTION_KEY=$(openssl rand -base64 32) # ¡IMPORTANTE! Genera una clave segura. ¡Guárdala!

# Credenciales de acceso básicas para n8n (¡CAMBIA ESTAS VALORES!)
N8N_BASIC_AUTH_USER="tu_usuario_admin"      # <--- CAMBIA ESTO
N8N_BASIC_AUTH_PASSWORD="tu_contrasena_segura" # <--- CAMBIA ESTO

# --- Configuración de Dominio para Nginx y HTTPS ---
# ¡CAMBIA ESTAS VALORES A TU DOMINIO REAL!
YOUR_DOMAIN="n8n.example.com" # <--- ¡CAMBIA ESTO por tu dominio o subdominio!
CERTBOT_EMAIL="your_email@example.com" # <--- ¡CAMBIA ESTO por tu correo electrónico para Certbot!

# --- Colores para la salida del script ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}--- Inicio del script de instalación de n8n con Node.js, PM2 y Nginx/HTTPS ---${NC}"

# --- Paso 1: Actualizar el sistema ---
echo -e "${GREEN}Actualizando el sistema...${NC}"
sudo apt update -y
sudo apt upgrade -y
sudo apt autoremove -y

# --- Paso 2: Instalar NVM (Node Version Manager) y Node.js ---
echo -e "${GREEN}Instalando NVM (Node Version Manager)...${NC}"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Cargar NVM para usarlo en el script
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

echo -e "${GREEN}Instalando la última versión LTS de Node.js...${NC}"
nvm install --lts
nvm use --lts
nvm alias default 'lts/*'

echo -e "${GREEN}Verificando la versión de Node.js y npm...${NC}"
node -v
npm -v

# --- Paso 3: Crear usuario y directorio para n8n ---
echo -e "${GREEN}Creando usuario '$N8N_USER' y directorio '$N8N_DIR' para n8n...${NC}"
if id -u "$N8N_USER" >/dev/null 2>&1; then
    echo "El usuario '$N8N_USER' ya existe. Omitiendo la creación del usuario."
else
    # Crear usuario de sistema con un home directory y shell válido
    # Usamos bash como shell para que pm2 startup funcione correctamente.
    sudo useradd -r -s /bin/bash -m -d "/home/$N8N_USER" "$N8N_USER"
    if [ $? -eq 0 ]; then
        echo "Usuario '$N8N_USER' creado con éxito y directorio home."
    else
        echo -e "${RED}Error: Falló la creación del usuario '$N8N_USER'.${NC}"
        exit 1
    fi
fi

sudo mkdir -p "$N8N_DIR"
sudo chown -R "$N8N_USER":"$N8N_USER" "$N8N_DIR"
sudo chown -R "$N8N_USER":"$N8N_USER" "/home/$N8N_USER" # Asegurar permisos del home dir

# --- Paso 4: Instalar n8n globalmente ---
echo -e "${GREEN}Instalando n8n globalmente...${NC}"
npm install -g n8n@$N8N_VERSION || { echo -e "${RED}Error: Falló la instalación de n8n.${NC}"; exit 1; }

# --- Paso 5: Instalar PM2 globalmente ---
echo -e "${GREEN}Instalando PM2 globalmente...${NC}"
npm install -g pm2 || { echo -e "${RED}Error: Falló la instalación de PM2.${NC}"; exit 1; }

# --- Paso 6: Configurar n8n como un servicio PM2 ---
echo -e "${GREEN}Configurando n8n como un proceso PM2...${NC}"

# Ruta al ejecutable de pm2 dentro del entorno de nvm del usuario
# Obtenemos la ruta completa al binario de pm2 una vez instalado
PM2_BIN_PATH=$(sudo su - "$N8N_USER" -c "nvm use --lts > /dev/null && npm bin -g")/pm2

# Validar si se encontró la ruta de pm2
if [ -z "$PM2_BIN_PATH" ]; then
    echo -e "${RED}Error: No se pudo determinar la ruta de PM2. Asegúrate de que NVM y PM2 se instalaron correctamente para el usuario '$N8N_USER'.${NC}"
    exit 1
fi

# Crear un script de inicio para n8n
N8N_START_SCRIPT="$N8N_DIR/start_n8n.sh"
sudo bash -c "cat << EOF > $N8N_START_SCRIPT
#!/bin/bash
# Cargar NVM para asegurar que n8n se ejecuta con la versión correcta de Node.js
export NVM_DIR=\"/home/$N8N_USER/.nvm\"
[ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\"
[ -s \"\$NVM_DIR/bash_completion\" ] && \\. \"\$NVM_DIR/bash_completion\"
nvm use --lts > /dev/null

export N8N_HOST=localhost
export N8N_PORT=$N8N_PORT
export N8N_PROTOCOL=http
export WEBHOOK_URL=https://$YOUR_DOMAIN/
export GENERIC_TIMEZONE=$N8N_TIMEZONE
export TZ=$N8N_TIMEZONE
export N8N_ENCRYPTION_KEY='$N8N_ENCRYPTION_KEY'
export N8N_BASIC_AUTH_ACTIVE=true
export N8N_BASIC_AUTH_USER='$N8N_BASIC_AUTH_USER'
export N8N_BASIC_AUTH_PASSWORD='$N8N_BASIC_AUTH_PASSWORD'
export N8N_DATA_FOLDER=$N8N_DIR/.n8n
exec n8n start
EOF"

sudo chmod +x "$N8N_START_SCRIPT"
sudo chown "$N8N_USER":"$N8N_USER" "$N8N_START_SCRIPT"

# Iniciar n8n con PM2 bajo el usuario n8nuser
echo -e "${GREEN}Iniciando n8n con PM2...${NC}"
# Usamos la ruta completa a pm2
sudo su - "$N8N_USER" -c "$PM2_BIN_PATH start '$N8N_START_SCRIPT' --name n8n --interpreter bash" || { echo -e "${RED}Error: Falló el inicio de n8n con PM2.${NC}"; exit 1; }

# Configurar PM2 para iniciar n8n al reiniciar el sistema
echo -e "${GREEN}Configurando PM2 para el inicio automático al reiniciar el sistema...${NC}"
# Genera el script de inicio de PM2 para el usuario n8nuser
# Usamos la ruta completa a pm2
sudo su - "$N8N_USER" -c "$PM2_BIN_PATH startup systemd"

# Guardar la lista de procesos PM2 para que persistan después de un reinicio
echo -e "${GREEN}Guardando la configuración de PM2...${NC}"
# Usamos la ruta completa a pm2
sudo su - "$N8N_USER" -c "$PM2_BIN_PATH save"


# --- Paso 7: Instalar y Configurar Nginx ---
echo -e "${GREEN}Instalando Nginx...${NC}"
sudo apt install nginx -y

echo -e "${GREEN}Configurando Nginx para n8n en $YOUR_DOMAIN...${NC}"
NGINX_CONF="/etc/nginx/sites-available/$YOUR_DOMAIN"
sudo bash -c "cat << EOF > $NGINX_CONF
server {
    listen 80;
    server_name $YOUR_DOMAIN;

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name $YOUR_DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$YOUR_DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$YOUR_DOMAIN/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    location / {
        proxy_pass http://localhost:$N8N_PORT; # n8n está escuchando internamente
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # Habilitar soporte para WebSockets
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \"upgrade\";
    }
}
EOF"

# Habilitar el sitio de Nginx
sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/
sudo nginx -t # Probar la configuración de Nginx
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: La sintaxis de Nginx es incorrecta. Revísala.${NC}"
    exit 1
fi
sudo systemctl restart nginx
sudo systemctl enable nginx

# --- Paso 8: Configurar Firewall (UFW) ---
echo -e "${GREEN}Configurando UFW para permitir tráfico a SSH, HTTP y HTTPS...${NC}"
sudo apt install ufw -y
sudo ufw allow 22/tcp       # SSH
sudo ufw allow 80/tcp       # HTTP (para la redirección a HTTPS y Certbot)
sudo ufw allow 443/tcp      # HTTPS
sudo ufw enable
echo "y" | sudo ufw enable # Confirmar si pregunta
sudo ufw status verbose

# --- Paso 9: Instalar Certbot y Obtener Certificado SSL ---
echo -e "${GREEN}Instalando Certbot para obtener certificados SSL...${NC}"
sudo snap install core
sudo snap refresh core
sudo snap install --classic certbot
sudo ln -sf /snap/bin/certbot /usr/bin/certbot

echo -e "${GREEN}Obteniendo certificado SSL para $YOUR_DOMAIN...${NC}"
sudo certbot --nginx -d "$YOUR_DOMAIN" --non-interactive --agree-tos --email "$CERTBOT_EMAIL" || { echo -e "${RED}Error: Falló la obtención del certificado SSL. Asegúrate de que tu dominio apunta a la IP de esta VPS y que los puertos 80/443 están abiertos.${NC}"; exit 1; }

echo -e "${GREEN}Verificando la renovación automática del certificado...${NC}"
sudo certbot renew --dry-run

echo -e "${GREEN}--- Instalación completada ---${NC}"
echo -e "${YELLOW}¡IMPORTANTE! Tu clave de encriptación para n8n es: ${N8N_ENCRYPTION_KEY}${NC}"
echo -e "${YELLOW}¡Guárdala en un lugar seguro! La necesitarás si alguna vez restauras datos o cambias de servidor.${NC}"
echo -e "${YELLOW}Tus credenciales de acceso básicas para n8n son:${NC}"
echo -e "${YELLOW}  Usuario: ${N8N_BASIC_AUTH_USER}${NC}"
echo -e "${YELLOW}  Contraseña: ${N8N_BASIC_AUTH_PASSWORD}${NC}"
echo ""
echo -e "${GREEN}n8n debería estar corriendo y accesible en: ${NC}"
echo -e "${GREEN}  -> https://$YOUR_DOMAIN ${NC}"
echo -e "${GREEN}Verifica el estado de n8n con: sudo su - $N8N_USER -c 'pm2 status n8n'${NC}"
echo -e "${GREEN}Para ver logs: sudo su - $N8N_USER -c 'pm2 logs n8n'${NC}"
echo -e "${YELLOW}Recuerda que los registros DNS de '$YOUR_DOMAIN' deben apuntar a la IP de tu VPS antes de ejecutar el script para que Certbot funcione.${NC}"
