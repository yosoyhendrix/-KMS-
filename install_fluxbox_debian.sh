#!/bin/bash

# Este script instala un escritorio ligero (Fluxbox) con Firefox ESR,
# ROX-Filer y herramientas de acceso remoto (TigerVNC, XRDP) en Debian 12.

# --- Configuración ---
USERNAME=$(whoami) # Obtiene el nombre de usuario actual
LOG_FILE="/var/log/desktop_install_fluxbox.log"
DATE=$(date +%Y%m%d_%H%M%S)

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
    if apt-get install -y "$PACKAGE" >> "$LOG_FILE" 2>&1; then
        log_message "$PACKAGE instalado correctamente."
    else
        log_message "Error al instalar $PACKAGE. Revisar $LOG_FILE para más detalles."
        exit 1
    fi
}

remove_package() {
    PACKAGE=$1
    log_message "Removiendo $PACKAGE..."
    if apt-get purge -y "$PACKAGE" >> "$LOG_FILE" 2>&1; then
        log_message "$PACKAGE removido correctamente."
    else
        log_message "Error al remover $PACKAGE. Revisar $LOG_FILE para más detalles."
    fi
}

# --- Inicio del Script ---
check_root
log_message "Iniciando la instalación de escritorio ligero con Fluxbox en Debian 12."
log_message "Los detalles de la instalación se guardarán en $LOG_FILE"

# 1. Actualizar el sistema
log_message "Actualizando la lista de paquetes."
apt-get update -y >> "$LOG_FILE" 2>&1 || log_message "Error al actualizar la lista de paquetes."
log_message "Actualizando paquetes instalados."
apt-get upgrade -y >> "$LOG_FILE" 2>&1 || log_message "Error al actualizar paquetes."

# 2. Manejo de FUSE (generalmente no es necesario hacerlo manualmente así)
# La instalación del paquete 'fuse' ya debería manejar /dev/fuse y sus permisos.
# Si estás en un contenedor LXC o un entorno virtualizado muy restringido, esto podría ser necesario.
# log_message "Verificando y configurando /dev/fuse (puede que no sea necesario)."
# mkdir -p /dev/fuse >> "$LOG_FILE" 2>&1
# chmod 777 /dev/fuse >> "$LOG_FILE" 2>&1
install_package "fuse"

# 3. Remover el escritorio MATE existente
log_message "Removiendo el escritorio MATE existente..."
remove_package "mate-desktop-environment-extra"
remove_package "mate-desktop-environment"
remove_package "task-mate-desktop" # Si se instaló con tasksel
log_message "Limpiando paquetes y dependencias no usadas."
apt-get autoremove -y >> "$LOG_FILE" 2>&1
apt-get clean >> "$LOG_FILE" 2>&1

# 4. Instalar el servidor X (Xorg) y Fluxbox
log_message "Instalando Xorg (servidor gráfico) y Fluxbox (gestor de ventanas)."
install_package "xserver-xorg"
install_package "fluxbox"

# 5. Instalar TigerVNC Server (recomendado sobre TightVNC en Debian 12)
log_message "Instalando TigerVNC Server."
install_package "tigervnc-standalone-server"
install_package "tigervnc-common"

# 6. Instalar Firefox ESR (navegador web)
log_message "Instalando Firefox ESR."
install_package "firefox-esr"

# 7. Instalar ROX-Filer (gestor de archivos)
log_message "Instalando ROX-Filer."
install_package "rox-filer"

# 8. Instalar herramientas de compresión/descompresión
log_message "Instalando herramientas de compresión/descompresión."
install_package "p7zip-full"
install_package "rar"
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

# 9. Instalar XRDP
log_message "Instalando XRDP."
install_package "xrdp"

# 10. Instalar herramientas adicionales útiles
log_message "Instalando herramientas adicionales (terminator, policykit-1-gnome, feh, network-manager-gnome)."
install_package "terminator"
install_package "policykit-1-gnome" # Necesario para autenticación gráfica
install_package "feh"                # Para fondos de pantalla
install_package "network-manager-gnome" # Para gestión de red en el escritorio

# 11. Configuración de Fluxbox para el usuario actual
log_message "Configurando Fluxbox para el usuario '$USERNAME'."

# Crear directorios de configuración si no existen
mkdir -p /home/$USERNAME/.fluxbox
mkdir -p /home/$USERNAME/.vnc
chown -R $USERNAME:$USERNAME /home/$USERNAME/.fluxbox
chown -R $USERNAME:$USERNAME /home/$USERNAME/.vnc

# Crear/modificar ~/.fluxbox/startup para Fluxbox (si se inicia localmente o desde LightDM)
# Aunque no usamos LightDM en este script, es una buena práctica tenerlo
FLUXBOX_STARTUP_FILE="/home/$USERNAME/.fluxbox/startup"
if [ -f "$FLUXBOX_STARTUP_FILE" ]; then
    log_message "Copia de seguridad de $FLUXBOX_STARTUP_FILE en $FLUXBOX_STARTUP_FILE.bak_$DATE"
    cp "$FLUXBOX_STARTUP_FILE" "$FLUXBOX_STARTUP_FILE.bak_$DATE"
fi

cat <<EOL > "$FLUXBOX_STARTUP_FILE"
#!/bin/bash

# Iniciar policykit para permitir la autenticación gráfica (ej. para wifi)
if which /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 > /dev/null; then
    /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 &
fi

# Iniciar ROX-Filer para el escritorio (pinboard)
rox -S &

# Establecer el fondo de pantalla (opcional, requiere 'feh')
xsetroot -solid "#2E3436" & # Un gris oscuro por defecto

# Iniciar el gestor de red (NetworkManager Applet)
nm-applet &

# Iniciar Fluxbox
exec fluxbox
EOL
chmod +x "$FLUXBOX_STARTUP_FILE"
chown $USERNAME:$USERNAME "$FLUXBOX_STARTUP_FILE"
log_message "Archivo ~/.fluxbox/startup configurado."


# 12. Configuración para VNC Server (xstartup)
log_message "Configurando el archivo ~/.vnc/xstartup para TigerVNC."
VNC_XSTARTUP_FILE="/home/$USERNAME/.vnc/xstartup"
if [ -f "$VNC_XSTARTUP_FILE" ]; then
    log_message "Copia de seguridad de $VNC_XSTARTUP_FILE en $VNC_XSTARTUP_FILE.bak_$DATE"
    cp "$VNC_XSTARTUP_FILE" "$VNC_XSTARTUP_FILE.bak_$DATE"
fi

cat <<EOL > "$VNC_XSTARTUP_FILE"
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

# Iniciar policykit para permitir la autenticación gráfica
if which /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 > /dev/null; then
    /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 &
fi

# Iniciar ROX-Filer para el escritorio (pinboard)
rox -S &

# Establecer el fondo de pantalla
xsetroot -solid "#2E3436" &

# Iniciar el gestor de red (NetworkManager Applet)
nm-applet &

# Iniciar Fluxbox
exec fluxbox
EOL
chmod +x "$VNC_XSTARTUP_FILE"
chown $USERNAME:$USERNAME "$VNC_XSTARTUP_FILE"
log_message "Archivo ~/.vnc/xstartup configurado."

# 13. Configuración para XRDP para iniciar Fluxbox
log_message "Configurando XRDP para iniciar Fluxbox."
XRDP_STARTWM_FILE="/etc/xrdp/startwm.sh"
if [ -f "$XRDP_STARTWM_FILE" ]; then
    log_message "Copia de seguridad de $XRDP_STARTWM_FILE en $XRDP_STARTWM_FILE.bak_$DATE"
    cp "$XRDP_STARTWM_FILE" "$XRDP_STARTWM_FILE.bak_$DATE"
fi

# Modificar startwm.sh para ejecutar Fluxbox
# Nota: Esto reemplazará el contenido del archivo.
cat <<EOL > "$XRDP_STARTWM_FILE"
#!/bin/bash
if [ -r /etc/default/locale ]; then
  . /etc/default/locale
  export LANG LANGUAGE LC_ALL LC_TYPE
fi
# Iniciar Xsession si está disponible
test -x /etc/X11/Xsession && exec /etc/X11/Xsession
# Fallback a Fluxbox si Xsession no se ejecuta (o puedes forzar Fluxbox directamente)
# Es más simple si solo quieres Fluxbox:
exec fluxbox
EOL
chmod +x "$XRDP_STARTWM_FILE"
log_message "Archivo /etc/xrdp/startwm.sh configurado para Fluxbox."

# 14. Reiniciar servicios
log_message "Reiniciando servicios de xrdp y vncserver."
service xrdp restart >> "$LOG_FILE" 2>&1 || log_message "Error al reiniciar xrdp."

# Para la primera ejecución de vncserver (establece la contraseña)
log_message "Iniciando vncserver por primera vez para establecer la contraseña VNC."
log_message "Por favor, introduce la contraseña para tu sesión VNC cuando se te pida."
sudo -u "$USERNAME" vncserver >> "$LOG_FILE" 2>&1

log_message "Deteniendo la primera sesión VNC para aplicar la configuración de xstartup."
sudo -u "$USERNAME" vncserver -kill :1 >> "$LOG_FILE" 2>&1

# 15. Recomendación de crear un servicio Systemd para VNC (más robusto)
log_message "Considera crear un servicio Systemd para TigerVNC para una gestión más robusta."
log_message "Puedes usar el script previo que te proporcioné para Debian 12 (sección 10 en adelante)."

# 16. Configuración de Firewall (UFW) si está activo
log_message "Configurando UFW (Firewall) si está activo..."
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        log_message "UFW está activo. Abriendo puertos para VNC (5901) y XRDP (3389)."
        ufw allow 5901/tcp comment "Allow VNC" >> "$LOG_FILE" 2>&1
        ufw allow 3389/tcp comment "Allow XRDP" >> "$LOG_FILE" 2>&1
        log_message "Reglas de UFW añadidas."
    else
        log_message "UFW no está activo. Si usas otro firewall, configura los puertos 5901 (VNC) y 3389 (XRDP) manualmente."
    fi
else
    log_message "UFW no está instalado. Si usas otro firewall, configura los puertos 5901 (VNC) y 3389 (XRDP) manualmente."
fi

log_message "Instalación y configuración completadas."
log_message "--------------------------------------------------------------------------------"
log_message "Puedes conectarte a tu VPS:"
log_message "  - Usando un cliente VNC (por ejemplo, RealVNC Viewer) a: tu_ip_de_vps:1 (puerto 5901)"
log_message "  - Usando un cliente RDP (por ejemplo, Conexión a Escritorio Remoto en Windows) a: tu_ip_de_vps"
log_message "Asegúrate de que no haya firewalls adicionales en tu proveedor de VPS bloqueando los puertos 5901 y 3389."
log_message "Para depurar, revisa el log: $LOG_FILE y los logs de VNC en /home/$USERNAME/.vnc/"
log_message "--------------------------------------------------------------------------------"

# 17. Eliminar el propio script (opcional)
log_message "Eliminando el script de instalación."
rm -- "$0" # Elimina el propio script

log_message "Reinicia el sistema para asegurarte de que todos los cambios surtan efecto."
reboot
