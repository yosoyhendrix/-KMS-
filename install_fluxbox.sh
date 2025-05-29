#!/bin/bash

# Este script instala un escritorio ligero con Fluxbox, Firefox, ROX-Filer y TigerVNC Server en Debian 12.

# --- Configuración ---
USERNAME=$(whoami) # Obtiene el nombre de usuario actual
LOG_FILE="/var/log/fluxbox_vnc_install.log"
DATE=$(date +%Y%m%d_%H%M%S)
VNC_DISPLAY=":1" # Puedes cambiar esto si quieres un display VNC diferente (ej. :2, :3)
VNC_PORT=$((5900 + ${VNC_DISPLAY//:/})) # Calcula el puerto VNC (ej. :1 -> 5901)
GEOMETRY="1280x800" # Resolución de la sesión VNC
DEPTH="24"           # Profundidad de color de la sesión VNC

# --- Funciones ---

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_message "Este script debe ejecutarse como root o con sudo."
        echo "Por favor, ejecuta: sudo ./install_fluxbox.sh.sh"
        exit 1
    fi
}

install_package() {
    PACKAGE=$1
    log_message "Instalando $PACKAGE..."
    if apt install -y "$PACKAGE" >> "$LOG_FILE" 2>&1; then
        log_message "$PACKAGE instalado correctamente."
    else
        log_message "Error al instalar $PACKAGE. Revisar $LOG_FILE para más detalles."
        exit 1
    fi
}

# --- Inicio del Script ---

check_root
log_message "Iniciando la instalación de escritorio ligero con Fluxbox, Firefox, ROX-Filer y TigerVNC Server en Debian 12."
log_message "Los detalles de la instalación se guardarán en $LOG_FILE"

# 1. Actualizar el sistema
log_message "Actualizando la lista de paquetes e instalando actualizaciones disponibles..."
if apt update -y >> "$LOG_FILE" 2>&1 && apt upgrade -y >> "$LOG_FILE" 2>&1; then
    log_message "Sistema actualizado correctamente."
else
    log_message "Error al actualizar el sistema. Revisar $LOG_FILE."
    exit 1
fi

# 2. Instalar el servidor X (Xorg)
log_message "Instalando Xorg (servidor gráfico)..."
install_package "xserver-xorg"

# 3. Instalar Fluxbox
log_message "Instalando Fluxbox..."
install_package "fluxbox"

# 4. Instalar Firefox (navegador web)
log_message "Instalando Firefox (navegador web)..."
install_package "firefox-esr" # Firefox ESR es la versión de soporte extendido, más estable en Debian.

# 5. Instalar ROX-Filer (gestor de archivos)
log_message "Instalando ROX-Filer (gestor de archivos)..."
install_package "rox-filer"

# 6. Instalar TigerVNC Server
log_message "Instalando TigerVNC Server..."
install_package "tigervnc-standalone-server"
install_package "tigervnc-common"

# 7. Herramientas adicionales útiles
log_message "Instalando herramientas adicionales (terminator, policykit-1-gnome, lxappearance, htop, feh, network-manager-gnome)..."
# terminator: Una terminal mejorada.
# policykit-1-gnome: Necesario para que algunas aplicaciones gráficas se eleven privilegios (ej. gestor de red).
# lxappearance: Para cambiar temas de GTK si se desea.
# htop: Monitor de procesos mejorado.
# feh: Visor de imágenes ligero y para establecer el fondo de pantalla.
# network-manager-gnome: Gestor de red gráfico para configurar Wi-Fi, etc. (importante en entornos de escritorio).
install_package "terminator"
install_package "policykit-1-gnome"
install_package "lxappearance"
install_package "htop"
install_package "feh"
install_package "network-manager-gnome" # Permite gestionar la red gráficamente

# 8. Configuración inicial de Fluxbox para el usuario actual
log_message "Configurando Fluxbox para el usuario '$USERNAME'..."

# Crear el directorio de configuración de Fluxbox si no existe
mkdir -p /home/$USERNAME/.fluxbox
chown -R $USERNAME:$USERNAME /home/$USERNAME/.fluxbox

# --- Configuración de Fluxbox para VNC ---
# El archivo .vnc/xstartup es clave para iniciar Fluxbox en la sesión VNC

log_message "Configurando el archivo ~/.vnc/xstartup para Fluxbox."

# Crear el directorio .vnc
mkdir -p /home/$USERNAME/.vnc
chown -R $USERNAME:$USERNAME /home/$USERNAME/.vnc

# Crear o modificar el archivo xstartup
VNC_XSTARTUP_FILE="/home/$USERNAME/.vnc/xstartup"
if [ -f "$VNC_XSTARTUP_FILE" ]; then
    log_message "Copia de seguridad de $VNC_XSTARTUP_FILE en $VNC_XSTARTUP_FILE.bak_$DATE"
    cp "$VNC_XSTARTUP_FILE" "$VNC_XSTARTUP_FILE.bak_$DATE"
fi

cat <<EOL > "$VNC_XSTARTUP_FILE"
#!/bin/bash

# Iniciar policykit para permitir la autenticación gráfica (ej. para wifi)
# Es importante que se inicie antes del gestor de ventanas
if which /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 > /dev/null; then
    /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 &
fi

# Iniciar ROX-Filer para el escritorio (pinboard)
# Puedes usar 'rox-filer &' si solo quieres el gestor de archivos y no el pinboard.
# 'rox -S &' permite iconos en el escritorio.
rox -S &

# Establecer el fondo de pantalla (opcional, requiere 'feh')
# Puedes cambiar la ruta a tu imagen de fondo o usar un color sólido
# Ejemplo: feh --bg-scale /usr/share/backgrounds/debian-blue.png &
xsetroot -solid "#2E3436" & # Un gris oscuro por defecto

# Iniciar el gestor de red (NetworkManager Applet)
nm-applet &

# Iniciar Fluxbox
exec fluxbox
EOL

# Dar permisos de ejecución al script de inicio de VNC
chmod +x "$VNC_XSTARTUP_FILE"
chown $USERNAME:$USERNAME "$VNC_XSTARTUP_FILE"

log_message "Archivo ~/.vnc/xstartup configurado correctamente."

# 9. Establecer la contraseña de VNC para el usuario
log_message "Estableciendo la contraseña para el servidor VNC del usuario '$USERNAME'."
log_message "Se te pedirá que introduzcas la contraseña VNC (y una opcional de solo lectura)."
sudo -u "$USERNAME" vncpasswd

# 10. Crear un servicio Systemd para el servidor VNC (opcional, para iniciar automáticamente)
log_message "Creando un servicio Systemd para el VNC Server para el usuario '$USERNAME'."

# Ubicación del archivo de servicio
VNC_SERVICE_FILE="/etc/systemd/system/vncserver@.service"

cat <<EOL > "$VNC_SERVICE_FILE"
[Unit]
Description=Remote desktop service (VNC)
After=syslog.target network.target

[Service]
Type=forking
User=$USERNAME
PAMName=login
PIDFile=/home/$USERNAME/.vnc/%H:%i.pid
ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
ExecStart=/usr/bin/vncserver %i -depth $DEPTH -geometry $GEOMETRY -localhost no
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target
EOL

# Recargar systemd para reconocer el nuevo servicio
systemctl daemon-reload
log_message "Servicio Systemd para VNC creado. Ahora puedes habilitarlo para que inicie automáticamente."

# Habilitar el servicio VNC para que inicie al arrancar
log_message "Habilitando el servicio VNC para que inicie automáticamente en el display $VNC_DISPLAY..."
systemctl enable vncserver@${VNC_DISPLAY//:/}.service >> "$LOG_FILE" 2>&1
log_message "Servicio VNC habilitado."

# Iniciar el servicio VNC ahora
log_message "Iniciando el servicio VNC ahora en el display $VNC_DISPLAY..."
systemctl start vncserver@${VNC_DISPLAY//:/}.service >> "$LOG_FILE" 2>&1
log_message "Servicio VNC iniciado. Verifica su estado con: systemctl status vncserver@${VNC_DISPLAY//:/}.service"

# 11. Configurar Firewall (UFW) si está activo
log_message "Configurando UFW (Firewall) si está activo..."
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        log_message "UFW está activo. Abriendo puerto $VNC_PORT para VNC."
        ufw allow "$VNC_PORT"/tcp comment "Allow VNC" >> "$LOG_FILE" 2>&1
        log_message "Regla de UFW añadida para VNC."
    else
        log_message "UFW no está activo. Si usas otro firewall, configura el puerto $VNC_PORT manualmente."
    fi
else
    log_message "UFW no está instalado. Si usas otro firewall, configura el puerto $VNC_PORT manualmente."
fi


log_message "Instalación completada."
log_message "--------------------------------------------------------------------------------"
log_message "Puedes conectarte a tu VPS usando un cliente VNC en la IP de tu VPS y puerto $VNC_PORT."
log_message "Ejemplo: tu_ip_de_vps:$VNC_DISPLAY o tu_ip_de_vps:$VNC_PORT"
log_message "Asegúrate de que no haya otros firewalls en tu proveedor de VPS bloqueando el puerto."
log_message "Si la conexión falla, revisa el log: $LOG_FILE"
log_message "Para depurar la sesión VNC, puedes revisar el log de VNC en /home/$USERNAME/.vnc/tu_vps_hostname:$VNC_DISPLAY.log"
log_message "--------------------------------------------------------------------------------"

exit 0
