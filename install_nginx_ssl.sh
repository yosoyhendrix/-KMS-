#!/bin/bash

# --- Configuración ---
YOUR_DOMAIN="ia.yosoyhendrix.com" # ¡IMPORTANTE! Reemplaza esto con tu dominio real
N8N_LOCAL_PORT=5678 # Puerto en localhost donde n8n está escuchando

# --- Colores para la salida ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Iniciando la configuración de Nginx y Certificado SSL para n8n...${NC}"

# 1. Instalar Nginx
echo -e "${GREEN}1. Instalando Nginx...${NC}"
sudo apt update
sudo apt install nginx -y
if [ $? -ne 0 ]; then
    echo -e "${RED}Error al instalar Nginx. Saliendo.${NC}"
    exit 1
fi
echo -e "${GREEN}Nginx instalado correctamente.${NC}"

# 2. Generar el archivo dhparam.pem (puede tardar unos minutos)
echo -e "${GREEN}2. Generando el archivo dhparam.pem (esto puede tomar varios minutos)...${NC}"
sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
if [ $? -ne 0 ]; then
    echo -e "${RED}Error al generar dhparam.pem. Saliendo.${NC}"
    exit 1
fi
echo -e "${GREEN}Archivo dhparam.pem generado.${NC}"

# 3. Crear el archivo de configuración de parámetros SSL
echo -e "${GREEN}3. Creando el archivo de configuración de parámetros SSL...${NC}"
sudo mkdir -p /etc/nginx/snippets
cat <<EOF | sudo tee /etc/nginx/snippets/ssl-params.conf
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
ssl_ecdh_curve secp384r1;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off;
ssl_stapling on;
ssl_stapling_verify on;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;
add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;
add_header X-XSS-Protection "1; mode=block";
EOF
if [ $? -ne 0 ]; then
    echo -e "${RED}Error al crear ssl-params.conf. Saliendo.${NC}"
    exit 1
fi
echo -e "${GREEN}Archivo ssl-params.conf creado.${NC}"

# 4. Crear la configuración de Nginx para n8n
echo -e "${GREEN}4. Creando la configuración de Nginx para n8n en ${YOUR_DOMAIN}...${NC}"
cat <<EOF | sudo tee /etc/nginx/sites-available/${YOUR_DOMAIN}
server {
    listen 80;
    listen [::]:80;
    server_name ${YOUR_DOMAIN};

    # Certbot challenge (para la renovación del certificado)
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    # Redirige todo el tráfico HTTP a HTTPS
    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ${YOUR_DOMAIN};

    # Configuración SSL (estos serán generados por Certbot)
    ssl_certificate /etc/letsencrypt/live/${YOUR_DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${YOUR_DOMAIN}/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/${YOUR_DOMAIN}/chain.pem;

    # Opcional: Configuración SSL hardening (recomendado para producción)
    include /etc/nginx/snippets/ssl-params.conf;
    ssl_dhparam /etc/ssl/certs/dhparam.pem;

    # Proxy a n8n
    location / {
        proxy_pass http://127.0.0.1:${N8N_LOCAL_PORT}; # n8n corre en localhost:5678
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # Mejoras para WebSockets (n8n los usa)
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 86400s; # Un día, para flujos largos
    }
}
EOF
if [ $? -ne 0 ]; then
    echo -e "${RED}Error al crear el archivo de configuración de Nginx para ${YOUR_DOMAIN}. Saliendo.${NC}"
    exit 1
fi
echo -e "${GREEN}Configuración de Nginx para ${YOUR_DOMAIN} creada.${NC}"

# 5. Habilitar la configuración del sitio
echo -e "${GREEN}5. Habilitando la configuración de Nginx para ${YOUR_DOMAIN}...${NC}"
sudo ln -s /etc/nginx/sites-available/${YOUR_DOMAIN} /etc/nginx/sites-enabled/
if [ $? -ne 0 ]; then
    echo -e "${RED}Error al habilitar la configuración de Nginx. Saliendo.${NC}"
    exit 1
fi
echo -e "${GREEN}Configuración de Nginx habilitada.${NC}"

# 6. Probar la configuración de Nginx y reiniciar
echo -e "${GREEN}6. Probando la configuración de Nginx y reiniciando el servicio...${NC}"
sudo nginx -t
if [ $? -ne 0 ]; then
    echo -e "${RED}Error en la sintaxis de la configuración de Nginx. Revisa los mensajes de error. Saliendo.${NC}"
    exit 1
fi
sudo systemctl restart nginx
if [ $? -ne 0 ]; then
    echo -e "${RED}Error al reiniciar Nginx. Saliendo.${NC}"
    exit 1
fi
echo -e "${GREEN}Nginx reiniciado correctamente.${NC}"

# 7. Instalar Certbot
echo -e "${GREEN}7. Instalando Certbot...${NC}"
sudo apt install certbot python3-certbot-nginx -y
if [ $? -ne 0 ]; then
    echo -e "${RED}Error al instalar Certbot. Saliendo.${NC}"
    exit 1
fi
echo -e "${GREEN}Certbot instalado correctamente.${NC}"

# 8. Obtener el certificado SSL con Certbot
echo -e "${GREEN}8. Obteniendo el certificado SSL con Certbot para ${YOUR_DOMAIN}...${NC}"
echo -e "${YELLOW}Certbot te hará algunas preguntas. Sigue las instrucciones en pantalla.${NC}"
echo -e "${YELLOW}Se te pedirá un email y se te preguntará si quieres redirigir HTTP a HTTPS (elige la opción de redirección).${NC}"
sudo certbot --nginx -d ${YOUR_DOMAIN}
if [ $? -ne 0 ]; then
    echo -e "${RED}Error al obtener el certificado SSL con Certbot. Asegúrate de que tu dominio apunta a la IP de la VPS y que los puertos 80/443 están abiertos. Saliendo.${NC}"
    exit 1
fi
echo -e "${GREEN}Certificado SSL obtenido y configurado para ${YOUR_DOMAIN}.${NC}"

echo -e "${YELLOW}Verificando la renovación automática de Certbot...${NC}"
sudo certbot renew --dry-run
echo -e "${GREEN}Simulación de renovación de Certbot completada. Si no hubo errores, la renovación automática funcionará.${NC}"

echo -e "${GREEN}¡Configuración de Nginx y SSL completada!${NC}"
echo -e "${YELLOW}Ahora puedes acceder a n8n de forma segura a través de HTTPS en: https://${YOUR_DOMAIN}/${NC}"

exit 0
