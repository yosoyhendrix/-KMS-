#!/bin/bash

# Este script instala un escritorio ligero con Fluxbox, Firefox, ROX-Filer
# y TigerVNC Server en Debian 12 (Bookworm).
# Reemplaza una instalación existente de MATE/TightVNC (si aplica) con Fluxbox/TigerVNC.

# --- Configuración ---
USERNAME=$(logname) # Obtiene el nombre de usuario que invocó sudo
LOG_FILE="/var/log/fluxbox_vnc_install_debian.log"
DATE=$(date +%Y%m%d_%H%M%S)
VNC_DISPLAY=":1" # Puedes cambiar esto si quieres un display VNC diferente (ej. :2, :3)
GEOMETRY="1280x800" # Resolución de la sesión VNC
DEPTH="24"           # Profundidad de color de la sesión VNC

# --- Funciones ---

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_message "Este script debe ejecutarse como root o con sudo."
        echo "Por favor, ejecuta: sudo ./nombre_del_script.sh"
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

remove_package() {
    PACKAGE=$1
    log_message "Removiendo $PACKAGE..."
    if apt remove --purge -y "$PACKAGE" >> "$LOG_FILE" 2>&1; then
        log_message "$PACKAGE removido correctamente."
    else
        log_message "Advertencia: Error al remover $PACKAGE. Podría no estar instalado o hubo un problema. Revisar $LOG_FILE."
    fi
}

# --- Inicio del Script ---

check_root
log_message "Iniciando la instalación de escritorio ligero con Fluxbox, Firefox, ROX-Filer y TigerVNC Server en Debian 12."
log_message "Los detalles de la instalación se guardarán en $LOG_FILE"
log_message "Usuario para configuración VNC y Fluxbox: $USERNAME"

# 1. Actualizar el sistema y asegurarse de tener las herramientas básicas
log_message "Actualizando la lista de paquetes e instalando actualizaciones disponibles..."
if apt update -y >> "$LOG_FILE" 2>&1 && apt upgrade -y >> "$LOG_FILE" 2>&1; then
    log_message "Sistema actualizado correctamente."
else
    log_message "Error al actualizar el sistema. Revisar $LOG_FILE."
    exit 1
fi

# El directorio /dev/fuse no se crea con mkdir, es un pseudo-sistema de archivos.
# Si estás viendo un error relacionado con esto, puede ser por un entorno de virtualización específico.
# Es mejor no manipular /dev directamente a menos que sea estrictamente necesario y se sepa por qué.
# Normalmente, apt-get install fuse ya asegura que el módulo y los permisos estén bien.
log_message "Verificando y asegurando el funcionamiento de FUSE..."
install_package "fuse"

# 2. Remover el escritorio MATE y TightVNC (si están instalados)
log_message "Removiendo escritorios y software VNC preexistente (MATE, TightVNC, XRDP)..."
remove_package "mate-desktop-environment-extra"
remove_package "mate-desktop-environment" # También remueve el paquete base de MATE
remove_package "tightvncserver"
remove_package "xrdp" # Si xrdp estaba ligado a MATE, lo removemos.

# Limpiar las dependencias sobrantes
log_message "Limpiando dependencias no usadas..."
apt autoremove -y >> "$LOG_FILE" 2>&1
apt autoclean -y >> "$LOG_FILE" 2>&1

# 3. Instalar el servidor X (Xorg)
log_message "Instalando Xorg (servidor gráfico)..."
install_package "xserver-xorg"

# 4. Instalar Fluxbox
log_message "Instalando Fluxbox..."
install_package "fluxbox"

# 5. Instalar Firefox (navegador web)
log_message "Instalando Firefox ESR (versión de soporte extendido, más estable en Debian)..."
install_package "firefox-esr"

# 6. Instalar ROX-Filer (gestor de archivos)
log_message "Instalando ROX-Filer (gestor de archivos)..."
install_package "rox-filer"

# 7. Instalar TigerVNC Server (más moderno que TightVNC)
log_message "Instalando TigerVNC Server..."
install_package "tigervnc-standalone-server"
install_package "tigervnc-common"

# 8. Herramientas de compresión/descompresión (manteniendo tu solicitud original)
log_message "Instalando herramientas de compresión/descompresión..."
install_package "p7zip-full"
install_package "zip"
install_package "unzip"
install_package "bzip2"
install_package "arj"
install_package "lzip"
install_package "lzma" # Este puede no existir como paquete separado en Debian 12, podría ser parte de xz-utils
install_package "gzip"
install_package "unar"

# 9. Herramientas adicionales útiles
log_message "Instalando herramientas adicionales (terminator, policykit-1-gnome, lxappearance, htop, feh, network-manager-gnome)..."
install_package "terminator"
install_package "policykit-1-gnome" # Necesario para la autenticación gráfica
install_package "lxappearance"       # Para gestionar temas GTK
install_package "htop"               # Monitor de procesos mejorado
install_package "feh"                # Visor de imágenes y para fondo de pantalla
install_package "network-manager-gnome" # Applet para gestionar la red (muy útil en un entorno gráfico)

# 10. Configuración de Fluxbox y TigerVNC para el usuario
log_message "Configurando Fluxbox y TigerVNC para el usuario '$USERNAME'..."

# Crear el directorio de configuración de Fluxbox si no existe
mkdir -p /home/$USERNAME/.fluxbox
chown -R $USERNAME:$USERNAME /home/$USERNAME/.fluxbox

# Crear el directorio .vnc
mkdir -p /home/$USERNAME/.vnc
chown -R $USERNAME:$USERNAME /home/$USERNAME/.vnc

# Crear o modificar el archivo xstartup para TigerVNC
VNC_XSTARTUP_FILE="/home/$USERNAME/.vnc/xstartup"
if [ -f "$VNC_XSTARTUP_FILE" ]; then
    log_message "Copia de seguridad de $VNC_XSTARTUP_FILE en $VNC_XSTARTUP_FILE.bak_$DATE"
    cp "$VNC_XSTARTUP_FILE" "$VNC_XSTARTUP_FILE.bak_$DATE"
fi

cat <<EOL > "$VNC_XSTARTUP_FILE"
#!/bin/bash

# Evitar que se inicie un escritorio ya existente
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

# Iniciar policykit para permitir la autenticación gráfica (ej. para network-manager-gnome)
if which /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 > /dev/null; then
    /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 &
fi

# Iniciar ROX-Filer para el escritorio (pinboard) y como gestor de archivos
# 'rox -S &' permite iconos en el escritorio.
rox -S &

# Establecer el fondo de pantalla (opcional, requiere 'feh')
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

# 11. Establecer la contraseña de VNC para el usuario
log_message "Estableciendo la contraseña para el servidor VNC del usuario '$USERNAME'."
log_message "Se te pedirá que introduzcas la contraseña VNC (y una opcional de solo lectura)."
sudo -u "$USERNAME" vncpasswd

# 12. Crear y habilitar un servicio Systemd para el servidor VNC
log_message "Creando un servicio Systemd para el VNC Server para el usuario '$USERNAME'."

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

systemctl daemon-reload
log_message "Servicio Systemd para VNC creado."

log_message "Habilitando el servicio VNC para que inicie automáticamente en el display $VNC_DISPLAY..."
systemctl enable vncserver@${VNC_DISPLAY//:/}.service >> "$LOG_FILE" 2>&1
log_message "Servicio VNC habilitado."

log_message "Iniciando el servicio VNC ahora en el display $VNC_DISPLAY..."
systemctl start vncserver@${VNC_DISPLAY//:/}.service >> "$LOG_FILE" 2>&1
log_message "Servicio VNC iniciado. Verifica su estado con: systemctl status vncserver@${VNC_DISPLAY//:/}.service"

# 13. Configurar Firewall (UFW) si está activo
VNC_PORT=$((5900 + ${VNC_DISPLAY//:/}))
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

log_message "Instalación y configuración completada."
log_message "--------------------------------------------------------------------------------"
log_message "Puedes conectarte a tu VPS usando un cliente VNC en la IP de tu VPS y puerto $VNC_PORT."
log_message "Ejemplo: tu_ip_de_vps:$VNC_DISPLAY o tu_ip_de_vps:$VNC_PORT"
log_message "Asegúrate de que no haya otros firewalls en tu proveedor de VPS bloqueando el puerto."
log_message "Para depurar la sesión VNC, puedes revisar el log en /home/$USERNAME/.vnc/$(hostname)$VNC_DISPLAY.log"
log_message "--------------------------------------------------------------------------------"

# No se recomienda eliminar el script automáticamente.
# rm escritoriodebian.sh

# Se recomienda un reinicio después de una instalación de escritorio para que todos los servicios arranquen correctamente.
log_message "El sistema se reiniciará en 10 segundos para aplicar todos los cambios."
sleep 10
reboot
