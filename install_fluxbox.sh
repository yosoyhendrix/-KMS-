#!/bin/bash

# Este script instala un escritorio ligero en Debian 12 con Fluxbox, ROX-Filer,
# Firefox ESR, herramientas de compresión y TigerVNC Server junto con XRDP.

# --- Configuración ---
USERNAME=$(whoami) # Obtiene el nombre de usuario actual
LOG_FILE="/var/log/fluxbox_rox_vnc_xrdp_install.log"
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

# --- Inicio del Script ---

check_root
log_message "Iniciando la instalación de escritorio ligero con Fluxbox, ROX-Filer, TigerVNC y XRDP en Debian 12."
log_message "Los detalles de la instalación se guardarán en $LOG_FILE"

# 1. Actualizar el sistema
log_message "Actualizando la lista de paquetes e instalando actualizaciones disponibles..."
if apt update -y >> "$LOG_FILE" 2>&1 && apt upgrade -y >> "$LOG_FILE" 2>&1; then
    log_message "Sistema actualizado correctamente."
else
    log_message "Error al actualizar el sistema. Revisar $LOG_FILE."
    exit 1
fi

# 2. Eliminar el escritorio MATE si estuviera presente y limpiar
log_message "Verificando y eliminando MATE Desktop si está instalado..."
if dpkg -l | grep -q "mate-desktop-environment"; then
    log_message "MATE Desktop detectado. Eliminando..."
    apt purge -y mate-desktop-environment-extra mate-desktop-environment >> "$LOG_FILE" 2>&1
    apt autoremove -y >> "$LOG_FILE" 2>&1
    log_message "MATE Desktop y sus dependencias eliminadas."
else
    log_message "MATE Desktop no detectado o ya eliminado."
fi

# 3. Preparar /dev/fuse (si es necesario, aunque apt install fuse ya lo suele manejar)
# log_message "Configurando /dev/fuse..."
# mkdir -p /dev/fuse # mkdir -p es más seguro
# chmod 777 /dev/fuse # Esto es muy permisivo, solo para pruebas. Mejor 666 o ajustar grupo fuse.
install_package "fuse" # La instalación del paquete fuse debería manejar /dev/fuse correctamente

# 4. Instalar software básico y Fluxbox
log_message "Instalando xorg, fluxbox y tigervnc-standalone-server..."
install_package "xorg"
install_package "fluxbox"
install_package "tigervnc-standalone-server" # Reemplaza tightvncserver
install_package "tigervnc-common"

# 5. Instalar Firefox ESR
log_message "Instalando Firefox ESR..."
install_package "firefox-esr"

# 6. Instalar ROX-Filer
log_message "Instalando ROX-Filer..."
install_package "rox-filer"

# 7. Instalar utilidades de compresión
log_message "Instalando utilidades de compresión..."
install_package "p7zip-full"
install_package "p7zip-rar"
install_package "rar" # El paquete 'rar' puede requerir non-free-contrib en sources.list
install_package "unrar"
install_package "zip"
install_package "unzip"
install_package "unace"
install_package "bzip2"
install_package "arj"
install_package "lzip"
install_package "lzma"
install_package "gzip"
install_package "unar"

# 8. Instalar herramientas adicionales útiles para el escritorio
log_message "Instalando herramientas adicionales (terminator, policykit-1-gnome, lxappearance, htop, feh, network-manager-gnome)..."
install_package "terminator"
install_package "policykit-1-gnome"
install_package "lxappearance"
install_package "htop"
install_package "feh"
install_package "network-manager-gnome"

# 9. Configuración inicial de Fluxbox para el usuario actual (para sesiones VNC)
log_message "Configurando Fluxbox para el usuario '$USERNAME' en sesiones VNC..."

# Crear el directorio de configuración de Fluxbox si no existe
mkdir -p /home/$USERNAME/.fluxbox
chown -R $USERNAME:$USERNAME /home/$USERNAME/.fluxbox

# Crear el directorio .vnc
mkdir -p /home/$USERNAME/.vnc
chown -R $USERNAME:$USERNAME /home/$USERNAME/.vnc

# Crear o modificar el archivo xstartup para VNC
VNC_XSTARTUP_FILE="/home/$USERNAME/.vnc/xstartup"
if [ -f "$VNC_XSTARTUP_FILE" ]; then
    log_message "Copia de seguridad de $VNC_XSTARTUP_FILE en $VNC_XSTARTUP_FILE.bak_$DATE"
    cp "$VNC_XSTARTUP_FILE" "$VNC_XSTARTUP_FILE.bak_$DATE"
fi

cat <<EOL > "$VNC_XSTARTUP_FILE"
#!/bin/bash

# Evita que el servidor VNC se cierre si Xvnc ya está corriendo
test -f \$HOME/.Xauthority || touch \$HOME/.Xauthority
test -f \$HOME/.Xauthority && export XAUTHORITY=\$HOME/.Xauthority

# Iniciar policykit para permitir la autenticación gráfica (ej. para wifi)
if which /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 > /dev/null; then
    /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 &
fi

# Iniciar ROX-Filer para el escritorio (pinboard)
rox -S &

# Establecer el fondo de pantalla (opcional)
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

# 10. Establecer la contraseña de VNC para el usuario
log_message "Estableciendo la contraseña para el servidor VNC del usuario '$USERNAME'."
log_message "Se te pedirá que introduzcas la contraseña VNC (y una opcional de solo lectura)."
sudo -u "$USERNAME" vncpasswd

# 11. Crear un servicio Systemd para el servidor VNC
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
log_message "Servicio Systemd para VNC creado. Habilitando e iniciando..."

systemctl enable vncserver@${VNC_DISPLAY//:/}.service >> "$LOG_FILE" 2>&1
systemctl start vncserver@${VNC_DISPLAY//:/}.service >> "$LOG_FILE" 2>&1
log_message "Servicio VNC iniciado. Verifica su estado con: systemctl status vncserver@${VNC_DISPLAY//:/}.service"

# 12. Instalar y configurar XRDP
log_message "Instalando XRDP..."
install_package "xrdp"

# Configurar XRDP para usar la sesión VNC existente o iniciar una nueva con Fluxbox
# Esto es un poco más complejo y puede requerir ajustes si ya existe un script de inicio
# XRDP típicamente usa ~/.xsession o /etc/xrdp/startwm.sh
# Creamos un script simple para asegurar que Fluxbox se inicie con XRDP
XRDP_STARTWM_SCRIPT="/etc/xrdp/startfluxbox.sh"

cat <<EOL > "$XRDP_STARTWM_SCRIPT"
#!/bin/bash
# Script para iniciar Fluxbox con XRDP

# Si ya tienes una sesión VNC en :1, XRDP podría intentar conectarse a ella
# para eso el puerto de VNC debe ser -localhost no
# Esto inicia una nueva sesión de VNC en la que XRDP se conectará
# o simplemente ejecuta fluxbox en el contexto de XRDP
# Exportamos las variables de sesión necesarias para XRDP
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
export XDG_MENU_PREFIX="/usr/share/debian/" # Opcional, para menús de Debian
export XDG_CONFIG_DIRS="/etc/xdg/xdg-fluxbox:/etc/xdg/xdg-debian:/etc/xdg" # Para configuración

# Iniciar el agente de autenticación de PolicyKit
if which /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 > /dev/null; then
    /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 &
fi

# Iniciar ROX-Filer para el escritorio de XRDP
rox -S &

# Iniciar el applet del gestor de red
nm-applet &

# Ejecutar Fluxbox
exec fluxbox
EOL

chmod +x "$XRDP_STARTWM_SCRIPT"
chown root:root "$XRDP_STARTWM_SCRIPT"

# Modificar el archivo /etc/xrdp/startwm.sh para que llame a nuestro script
# Hacemos una copia de seguridad del original
mv /etc/xrdp/startwm.sh /etc/xrdp/startwm.sh.bak_$DATE
echo "$XRDP_STARTWM_SCRIPT" > /etc/xrdp/startwm.sh
chmod +x /etc/xrdp/startwm.sh # Asegurarse de que el nuevo script sea ejecutable

# Reiniciar el servicio XRDP
log_message "Reiniciando el servicio XRDP..."
service xrdp restart >> "$LOG_FILE" 2>&1

# 13. Configurar Firewall (UFW) si está activo
log_message "Configurando UFW (Firewall) si está activo..."
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        log_message "UFW está activo. Abriendo puertos $VNC_PORT (VNC) y 3389 (XRDP)."
        ufw allow "$VNC_PORT"/tcp comment "Allow VNC" >> "$LOG_FILE" 2>&1
        ufw allow 3389/tcp comment "Allow RDP" >> "$LOG_FILE" 2>&1
        log_message "Reglas de UFW añadidas para VNC y RDP."
    else
        log_message "UFW no está activo. Si usas otro firewall, configura los puertos $VNC_PORT y 3389 manualmente."
    fi
else
    log_message "UFW no está instalado. Si usas otro firewall, configura los puertos $VNC_PORT y 3389 manualmente."
fi

# 14. Eliminar el propio script (opcional)
log_message "Eliminando el script de instalación: $(basename "$0")..."
rm -- "$0" # Elimina el propio script

log_message "Instalación completada. Reinicia tu sistema si lo deseas, o conéctate vía VNC/RDP."
log_message "--------------------------------------------------------------------------------"
log_message "Conexión VNC: IP_de_tu_VPS:$VNC_DISPLAY o IP_de_tu_VPS:$VNC_PORT"
log_message "Conexión RDP: IP_de_tu_VPS (Puerto 3389 por defecto)"
log_message "Asegúrate de que no haya otros firewalls en tu proveedor de VPS bloqueando los puertos."
log_message "--------------------------------------------------------------------------------"

reboot # Reinicia el sistema para que todos los cambios surtan efecto

exit 0
