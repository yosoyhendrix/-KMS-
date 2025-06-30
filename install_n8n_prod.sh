#!/bin/bash

# --- Configuración Inicial (¡AJUSTA ESTOS VALORES!) ---
N8N_VERSION="latest" # Puedes especificar una versión como "1.37.2"
N8N_USER="n8nuser" # Usuario de sistema para n8n
N8N_DIR="/opt/n8n" # Directorio de instalación de n8n
N8N_PORT="5678" # Puerto interno de n8n (Nginx se encargará del 80/443)
N8N_TIMEZONE="America/Santo_Domingo" # Ajusta tu zona horaria (ej. "America/New_York")
N8N_ENCRYPTION_KEY=$(openssl rand -base64 32) # ¡IMPORTANTE! Genera una clave segura. ¡Guárdala!

# Credenciales de acceso básicas para n8n UI (¡CAMBIA ESTAS VALORES O FALLARÁ LA INSTALACIÓN!)
N8N_BASIC_AUTH_USER="n8nuser"      # <--- ¡CAMBIA ESTO!
N8N_BASIC_AUTH_PASSWORD="ContrasenaMuySeguraParaN8n" # <--- ¡CAMBIA ESTO!

# --- Configuración de Dominio para Nginx y HTTPS (¡AJUSTA ESTOS VALORES O FALLARÁ LA INSTALACIÓN!) ---
YOUR_DOMAIN="n8n.example.com" # <--- ¡CAMBIA ESTO por tu dominio o subdominio REAL!
CERTBOT_EMAIL="tu_email@example.com" # <--- ¡CAMBIA ESTO por tu correo electrónico para Certbot!

# --- Colores para la salida del script ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}--- Iniciando script de instalación de n8n en PRODUCCIÓN con Node.js, PM2 y Nginx/HTTPS ---${NC}"
echo -e "${BLUE}Asegúrate de que el dominio '$YOUR_DOMAIN' apunta a la IP de tu VPS y que los puertos 80/443 están abiertos.${NC}"
echo -e "${BLUE}Este script creará un usuario de sistema '$N8N_USER'.${NC}"
echo -e "${BLUE}Tus credenciales de n8n serán '$N8N_BASIC_AUTH_USER' y '$N8N_BASIC_AUTH_PASSWORD'.${NC}"
sleep 10 # Pausa para que el usuario lea las advertencias

# --- Paso 1: Actualizar el sistema ---
echo -e "${GREEN}1. Actualizando el sistema...${NC}"
sudo apt update -y || { echo -e "${RED}Error: Falló 'apt update'.${NC}"; exit 1; }
sudo apt upgrade -y || { echo -e "${RED}Error: Falló 'apt upgrade'.${NC}"; exit 1; }
sudo apt autoremove -y || { echo -e "${RED}Error: Falló 'apt autoremove'.${NC}"; exit 1; }

# --- Paso 2: Instalar NVM (Node Version Manager) y Node.js ---
echo -e "${GREEN}2. Instalando NVM (Node Version Manager) para el usuario principal...${NC}"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash || { echo -e "${RED}Error: Falló la descarga de NVM installer.${NC}"; exit 1; }

# Cargar NVM para usarlo en el script
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" || { echo -e "${RED}Error: Falló la carga de nvm.sh.${NC}"; exit 1; }
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" || { echo -e "${RED}Error: Falló la carga de nvm bash_completion.${NC}"; exit 1; }

echo -e "${GREEN}Instalando la última versión LTS de Node.js...${NC}"
nvm install --lts || { echo -e "${RED}Error: Falló la instalación de Node.js LTS.${NC}"; exit 1; }
nvm use --lts || { echo -e "${RED}Error: Falló al usar Node.js LTS.${NC}"; exit 1; }
nvm alias default 'lts/*' || { echo -e "${RED}Error: Falló al establecer alias de Node.js.${NC}"; exit 1; }

echo -e "${BLUE}Versión de Node.js: $(node -v)${NC}"
echo -e "${BLUE}Versión de npm: $(npm -v)${NC}"

# --- Paso 3: Crear usuario de sistema para n8n ---
echo -e "${GREEN}3. Creando usuario de sistema '$N8N_USER' y su directorio home...${NC}"
if id -u "$N8N_USER" >/dev/null 2>&1; then
    echo -e "${YELLOW}El usuario '$N8N_USER' ya existe. Omitiendo la creación del usuario.${NC}"
else
    # Crear usuario de sistema con un home directory y shell válido para PM2
    sudo useradd -r -s /bin/bash -m -d "/home/$N8N_USER" "$N8N_USER" || { echo -e "${RED}Error: Falló la creación del usuario '$N8N_USER'.${NC}"; exit 1; }
    echo "Usuario '$N8N_USER' creado con éxito."
fi

sudo mkdir -p "$N8N_DIR" || { echo -e "${RED}Error: Falló la creación del directorio '$N8N_DIR'.${NC}"; exit 1; }
sudo chown -R "$N8N_USER":"$N8N_USER" "$N8N_DIR" || { echo -e "${RED}Error: Falló la asignación de permisos a '$N8N_DIR'.${NC}"; exit 1; }
sudo chown -R "$N8N_USER":"$N8N_USER" "/home/$N8N_USER" || { echo -e "${RED}Error: Falló la asignación de permisos al home de '$N8N_USER'.${NC}"; exit 1; }

# --- Paso 4: Instalar NVM, Node.js, n8n y PM2 globalmente para el usuario n8nuser ---
echo -e "${GREEN}4. Instalando NVM, Node.js LTS, n8n y PM2 globalmente para el usuario '$N8N_USER'...${NC}"

# Script para ejecutar bajo n8nuser para instalar NVM, Node.js, n8n y PM2
INSTALL_NVM_NODE_NPM_SCRIPT=$(cat <<EOF
export HOME="/home/$N8N_USER"
export NVM_DIR="$HOME/.nvm"
# Descargar e instalar NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash || exit 1
# Cargar NVM
[ -s "$NVM_DIR/nvm.sh" ] && \\. "$NVM_DIR/nvm.sh" || exit 1
[ -s "$NVM_DIR/bash_completion" ] && \\. "$NVM_DIR/bash_completion" || exit 1
# Instalar Node.js LTS
nvm install --lts || exit 1
nvm use --lts || exit 1
nvm alias default 'lts/*' || exit 1
# Instalar n8n y PM2
npm install -g n8n@"$N8N_VERSION" || exit 1
npm install -g pm2 || exit 1
echo "NVM, Node.js, n8n y PM2 instalados para $N8N_USER."
EOF
)

sudo su - "$N8N_USER" -c "$INSTALL_NVM_NODE_NPM_SCRIPT" || { echo -e "${RED}Error: Falló la instalación de NVM/Node.js/n8n/PM2 para '$N8N_USER'.${NC}"; exit 1; }

# --- Paso 5: Configurar n8n como un servicio PM2 ---
echo -e "${GREEN}5. Configurando n8n como un proceso PM2...${NC}"

# Obtener la ruta completa al binario de pm2 dentro del entorno de nvm del usuario
# Aseguramos que NVM se carga para obtener la ruta correcta
PM2_BIN_PATH=$(sudo su - "$N8N_USER" -c 'export HOME="/home/'"$N8N_USER"'" && export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm use --lts > /dev/null 2>&1 && npm bin -g 2>/dev/null')/pm2

if [ -z "$PM2_BIN_PATH" ] || [ ! -x "$PM2_BIN_PATH" ]; then
    echo -e "${RED}Error: No se pudo determinar o verificar la ruta ejecutable de PM2 para '$N8N_USER'.${NC}"
    echo -e "${RED}Asegúrate de que NVM, Node.js y PM2 se instalaron correctamente para este usuario.${NC}"
    echo -e "${RED}Ruta PM2 intentada: '$PM2_BIN_PATH'${NC}"
    exit 1
fi

# Crear un script de inicio para n8n
N8N_START_SCRIPT="$N8N_DIR/start_n8n.sh"
sudo bash -c "cat << EOF > $N8N_START_SCRIPT
#!/bin/bash
# Cargar NVM para asegurar que n8n se ejecuta con la versión correcta de Node.js
export HOME=\"/home/$N8N_USER\"
export NVM_DIR=\"\$HOME/.nvm\"
[ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\"
[ -s \"\$NVM_DIR/bash_completion\" ] && \\. \"\$NVM_DIR/bash_completion\"
nvm use --lts > /dev/null

export N8N_HOST=localhost
export N8N_PORT=$N8N_PORT
export N8N_PROTOCOL=http # Nginx manejará HTTPS externamente
export WEBHOOK_URL=https://$YOUR_DOMAIN/ # ¡URL pública de n8n para webhooks!
export GENERIC_TIMEZONE=$N8N_TIMEZONE
export TZ=$N8N_TIMEZONE
export N8N_ENCRYPTION_KEY='$N8N_ENCRYPTION_KEY'
export N8N_BASIC_AUTH_ACTIVE=true
export N8N_BASIC_AUTH_USER='$N8N_BASIC_AUTH_USER'
export N8N_BASIC_AUTH_PASSWORD='$N8N_BASIC_AUTH_PASSWORD'
export N8N_DATA_FOLDER=$N8N_DIR/.n8n # Persistir datos aquí
exec n8n start
EOF"

sudo chmod +x "$N8N_START_SCRIPT" || { echo -e "${RED}Error: Falló chmod en '$N8N_START_SCRIPT'.${NC}"; exit 1; }
sudo chown "$N8N_USER":"$N8N_USER" "$N8N_START_SCRIPT" || { echo -e "${RED}Error: Falló chown en '$N8N_START_SCRIPT'.${NC}"; exit 1; }

# Iniciar n8n con PM2 bajo el usuario n8nuser
echo -e "${GREEN}Iniciando n8n con PM2...${NC}"
sudo su - "$N8N_USER" -c "$PM2_BIN_PATH start '$N8N_START_SCRIPT' --name n8n --interpreter bash" || { echo -e "${RED}Error: Falló el inicio de n8n con PM2.${NC}"; exit 1; }

# Configurar PM2 para inicio automático al reiniciar el sistema
echo -e "${GREEN}Configurando PM2 para el inicio automático al reiniciar el sistema...${NC}"
sudo su - "$N8N_USER" -c "$PM2_BIN_PATH startup systemd" || { echo -e "${RED}Error: Falló 'pm2 startup systemd'.${NC}"; exit 1; }

# Guardar la lista de procesos PM2 para que persistan después de un reinicio
echo -e "${GREEN}Guardando la configuración de PM2...${NC}"
sudo su - "$N8N_USER" -c "$PM2_BIN_PATH save" || { echo -e "${RED}Error: Falló 'pm2 save'.${NC}"; exit 1; }


# --- Paso 6: Instalar y Configurar Nginx ---
echo -e "${GREEN}6. Instalando Nginx...${NC}"
sudo apt install nginx -y || { echo -e "${RED}Error: Falló la instalación de Nginx.${NC}"; exit 1; }

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

    # SSL certificados serán instalados por Certbot
    # ssl_certificate /etc/letsencrypt/live/$YOUR_DOMAIN/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/$YOUR_DOMAIN/privkey.pem;
    # include /etc/letsencrypt/options-ssl-nginx.conf;
    # ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    location / {
        proxy_pass http://localhost:$N8N_PORT; # n8n está escuchando internamente
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300s; # Aumentar timeout para operaciones largas

        # Habilitar soporte para WebSockets
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \"upgrade\";
    }

    # Añadir cabeceras de seguridad HTTP
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always; # HSTS
    
    # Configuración para evitar el acceso directo a los archivos de Certbot si no se usan
    location ~ /.well-known/acme-challenge {
        allow all;
        root /var/www/html; # Directorio por defecto de Certbot
    }
}
EOF"

# Habilitar el sitio de Nginx
sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/ || { echo -e "${RED}Error: Falló la creación del enlace simbólico de Nginx.${NC}"; exit 1; }
sudo nginx -t # Probar la configuración de Nginx
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: La sintaxis de Nginx es incorrecta. Revísala.${NC}"
    exit 1
fi
sudo systemctl restart nginx || { echo -e "${RED}Error: Falló el reinicio de Nginx.${NC}"; exit 1; }
sudo systemctl enable nginx || { echo -e "${RED}Error: Falló al habilitar Nginx al inicio.${NC}"; exit 1; }


# --- Paso 7: Configurar Firewall (UFW) ---
echo -e "${GREEN}7. Configurando UFW para permitir tráfico a SSH, HTTP y HTTPS...${NC}"
sudo apt install ufw -y || { echo -e "${RED}Error: Falló la instalación de UFW.${NC}"; exit 1; }
sudo ufw allow 22/tcp       # SSH
sudo ufw allow 80/tcp       # HTTP (para la redirección a HTTPS y Certbot)
sudo ufw allow 443/tcp      # HTTPS
sudo ufw enable
echo "y" | sudo ufw enable || { echo -e "${RED}Error: Falló la habilitación de UFW.${NC}"; exit 1; }
sudo ufw status verbose

# --- Paso 8: Instalar Certbot y Obtener Certificado SSL ---
echo -e "${GREEN}8. Instalando Certbot para obtener certificados SSL...${NC}"
sudo snap install core || { echo -e "${RED}Error: Falló la instalación de snap core.${NC}"; exit 1; }
sudo snap refresh core || { echo -e "${RED}Error: Falló la actualización de snap core.${NC}"; exit 1; }
sudo snap install --classic certbot || { echo -e "${RED}Error: Falló la instalación de Certbot snap.${NC}"; exit 1; }
sudo ln -sf /snap/bin/certbot /usr/bin/certbot || { echo -e "${RED}Error: Falló la creación del enlace simbólico de Certbot.${NC}"; exit 1; }

echo -e "${GREEN}Obteniendo certificado SSL para $YOUR_DOMAIN...${NC}"
# Usamos --nginx para integración automática con Nginx
# --non-interactive para evitar preguntas (asumiendo --agree-tos)
# --agree-tos para aceptar los términos de servicio
# --email para registrar el correo
sudo certbot --nginx -d "$YOUR_DOMAIN" --non-interactive --agree-tos --email "$CERTBOT_EMAIL" || { echo -e "${RED}Error: Falló la obtención del certificado SSL. Asegúrate de que tu dominio apunta a la IP de esta VPS y que los puertos 80/443 están abiertos.${NC}"; exit 1; }

echo -e "${GREEN}Verificando la renovación automática del certificado...${NC}"
sudo certbot renew --dry-run || { echo -e "${RED}Advertencia: Falló la prueba de renovación automática de Certbot. Revisa los logs.${NC}"; }


echo -e "${YELLOW}--- Instalación de n8n en Producción Completada ---${NC}"
echo -e "${BLUE}¡Felicidades! Tu instancia de n8n debería estar ahora segura y funcionando.${NC}"
echo -e "${YELLOW}*******************************************************************************${NC}"
echo -e "${YELLOW}¡IMPORTANTE! TU CLAVE DE ENCRIPTACIÓN PARA N8N ES: ${N8N_ENCRYPTION_KEY}${NC}"
echo -e "${YELLOW}   ¡GUARDA ESTA CLAVE EN UN LUGAR SEGURO! La necesitarás si alguna vez restauras${NC}"
echo -e "${YELLOW}   datos, migras o cambias de servidor. Sin ella, tus credenciales cifradas serán irrecuperables.${NC}"
echo -e "${YELLOW}*******************************************************************************${NC}"
echo -e "${YELLOW}Tus credenciales de acceso básicas para n8n UI son:${NC}"
echo -e "${YELLOW}  Usuario: ${N8N_BASIC_AUTH_USER}${NC}"
echo -e "${YELLOW}  Contraseña: ${N8N_BASIC_AUTH_PASSWORD}${NC}"
echo ""
echo -e "${GREEN}Puedes acceder a n8n en tu navegador en: ${NC}"
echo -e "${GREEN}  -> https://$YOUR_DOMAIN ${NC}"
echo -e "${BLUE}Verifica el estado de n8n con: sudo su - $N8N_USER -c 'pm2 status n8n'${NC}"
echo -e "${BLUE}Para ver logs de n8n: sudo su - $N8N_USER -c 'pm2 logs n8n'${NC}"
echo -e "${BLUE}Para ver logs de Nginx: sudo tail -f /var/log/nginx/access.log /var/log/nginx/error.log${NC}"
echo ""
echo -e "${YELLOW}Consideraciones Adicionales:${NC}"
echo -e "${YELLOW}  - Base de Datos: Para mayor robustez, considera configurar PostgreSQL para n8n en lugar de SQLite (por defecto).${NC}"
echo -e "${YELLOW}  - Backups: Implementa una estrategia de copias de seguridad para el directorio '$N8N_DIR/.n8n'.${NC}"
echo -e "${YELLOW}  - Actualizaciones: Mantén tu sistema Ubuntu, Node.js y n8n actualizados regularmente.${NC}"
echo -e "${YELLOW}--- Script de instalación finalizado ---${NC}"
