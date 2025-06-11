#!/bin/bash

# Este script instala un escritorio ligero con Fluxbox, Firefox-ESR, ROX-Filer
# y TigerVNC Server en Debian 12.
# Permite a cualquier usuario (incluido root) iniciar su propia sesión VNC bajo demanda.

# --- Configuración General ---
LOG_FILE="/var/log/custom_desktop_install_debian.log"
DATE=$(date +%Y%m%d_%H%M%S)
VNC_DISPLAY=":1" # Display VNC predeterminado para comandos manuales (ej. vncserver :1)
GEOMETRY="1280x800" # Resolución para la sesión VNC
DEPTH="24"           # Profundidad de color para la sesión VNC

# --- Funciones de Ayuda ---

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_message "Este script debe ejecutarse como root o con sudo."
        echo "Por favor, ejecuta: sudo ./$(basename "$0")"
        exit 1
    fi
}

install_package() {
    PACKAGE=$1
    log_message "Instalando $PACKAGE..."
    if apt install -y "$PACKAGE" >> "$LOG_FILE" 2>&1; then
        log_message "$PACKAGE instalado correctamente."
    else
        log_message "Error al instalar $PACKAGE. Revisa $LOG_FILE para más detalles."
        exit 1
    fi
}

remove_package() {
    PACKAGE=$1
    log_message "Removiendo $PACKAGE..."
    if apt remove --purge -y "$PACKAGE" >> "$LOG_FILE" 2>&1; then
        log_message "$PACKAGE removido correctamente."
    else
        log_message "Advertencia: Error al remover $PACKAGE. Podría no estar instalado o hubo un problema. Revisa $LOG_FILE."
    fi
}

configure_user_vnc_fluxbox() {
    local user_home="$1"
    local username="$2"

    log_message "Configurando Fluxbox y TigerVNC para el usuario '$username' en '$user_home'..."

    # 1. Crear directorios de configuración si no existen
    mkdir -p "$user_home/.fluxbox"
    mkdir -p "$user_home/.vnc"
    chown -R "$username":"$username" "$user_home/.fluxbox" "$user_home/.vnc"

    # 2. Configuración de Fluxbox: Archivo 'startup'
    FLUXBOX_STARTUP_FILE="$user_home/.fluxbox/startup"
    log_message "Generando el archivo Fluxbox startup: '$FLUXBOX_STARTUP_FILE'"
    cat <<EOL > "$FLUXBOX_STARTUP_FILE"
#!/bin/bash

# Este script se ejecuta al iniciar una sesión de Fluxbox.
# Asegúrate de que las aplicaciones necesarias estén instaladas en el sistema.

# Evitar que se inicie un escritorio ya existente
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

# Iniciar policykit para permitir la autenticación gráfica (ej. para network-manager-gnome)
if which /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 > /dev/null; then
    /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 &
fi

# Iniciar ROX-Filer para el escritorio (pinboard) y como gestor de archivos
rox -S &

# Establecer el fondo de pantalla (opcional, requiere 'feh')
xsetroot -solid "#2E3436" & # Un gris oscuro por defecto

# Iniciar el gestor de red (NetworkManager Applet)
nm-applet &

# Iniciar Fluxbox
exec fluxbox
EOL
    chmod +x "$FLUXBOX_STARTUP_FILE"
    chown "$username":"$username" "$FLUXBOX_STARTUP_FILE"

    # 3. Configuración de TigerVNC: Archivo 'xstartup'
    VNC_XSTARTUP_FILE="$user_home/.vnc/xstartup"
    log_message "Generando el archivo VNC xstartup: '$VNC_XSTARTUP_FILE'"
    cat <<EOL > "$VNC_XSTARTUP_FILE"
#!/bin/bash

# Este script se ejecuta al iniciar una sesión VNC.
# Asegúrate de que las aplicaciones necesarias estén instaladas en el sistema.

# Evitar que se inicie un escritorio ya existente
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

# Iniciar policykit para permitir la autenticación gráfica (ej. para network-manager-gnome)
if which /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 > /dev/null; then
    /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 &
fi

# Iniciar ROX-Filer para el escritorio (pinboard) y como gestor de archivos
rox -S &

# Establecer el fondo de pantalla (opcional, requiere 'feh')
xsetroot -solid "#2E3436" & # Un gris oscuro por defecto

# Iniciar el gestor de red (NetworkManager Applet)
nm-applet &

# Iniciar Fluxbox
exec fluxbox
EOL
    chmod +x "$VNC_XSTARTUP_FILE"
    chown "$username":"$username" "$VNC_XSTARTUP_FILE"

    log_message "Configuración de Fluxbox y TigerVNC completada para el usuario '$username'."
}

# --- Inicio del Script Principal ---

check_root
log_message "Iniciando la instalación y configuración de escritorio Fluxbox/ROX-Filer/Firefox con VNC bajo demanda en Debian 12."
log_message "Los detalles se guardarán en $LOG_FILE"

# Removiendo configuraciones antiguas (MATE, TightVNC, XRDP)
log_message "Limpiando configuraciones y paquetes de escritorios previos (MATE, TightVNC, XRDP)..."
remove_package "mate-desktop-environment-extra"
remove_package "mate-desktop-environment"
remove_package "tightvncserver"
remove_package "xrdp" # Si xrdp estaba ligado a MATE, lo removemos.
sudo rm -f /etc/systemd/system/xrdp.service # Asegura que el servicio xrdp no quede
sudo rm -f /etc/systemd/system/vncserver@.service # Elimina el servicio VNC global si existía

# Limpiar las dependencias sobrantes
log_message "Limpiando dependencias no usadas y caché de paquetes..."
apt autoremove -y >> "$LOG_FILE" 2>&1
apt autoclean -y >> "$LOG_FILE" 2>&1

# Asegurando FUSE (tu línea original)
log_message "Asegurando el funcionamiento de FUSE..."
install_package "fuse"
# Las líneas mkdir /dev/fuse y chmod 777 /dev/fuse no son necesarias ni recomendables
# ya que /dev/fuse es un dispositivo gestionado por el kernel y el paquete fuse.
# Si estás viendo errores de fuse, podría ser un problema del entorno de virtualización.

# Instalación de Componentes del Escritorio
log_message "Instalando Xorg (servidor gráfico)..."
install_package "xserver-xorg"

log_message "Instalando Fluxbox..."
install_package "fluxbox"

log_message "Instalando ROX-Filer (gestor de archivos)..."
install_package "rox-filer"

log_message "Instalando Firefox ESR (navegador web recomendado para Debian)..."
install_package "firefox-esr"

log_message "Instalando TigerVNC Server (para VNC bajo demanda por usuario)..."
install_package "tigervnc-standalone-server"
install_package "tigervnc-common"

# Herramientas adicionales útiles
log_message "Instalando herramientas adicionales (terminator, policykit-1-gnome, lxappearance, htop, feh, network-manager-gnome, herramientas de compresión)..."
install_package "terminator"
install_package "policykit-1-gnome"
install_package "lxappearance"
install_package "htop"
install_package "feh"
install_package "network-manager-gnome" # Gestor de red gráfico para VNC

# Herramientas de compresión/descompresión (según tu script original)
install_package "p7zip-full"
install_package "zip"
install_package "unzip"
install_package "bzip2"
install_package "arj"
install_package "lzip"
install_package "lzma" # Puede que no exista como paquete separado, xz-utils lo proporciona.
install_package "gzip"
install_package "unar"

# --- Configurar Fluxbox y VNC para usuarios existentes y futuros ---

# Configurar para el usuario 'root'
log_message "Configurando Fluxbox y VNC para el usuario 'root'..."
configure_user_vnc_fluxbox "/root" "root"

# Configurar para usuarios existentes en /home/ (excluyendo 'root')
log_message "Configurando Fluxbox y VNC para usuarios existentes en /home/..."
for user_dir in /home/*; do
    if [ -d "$user_dir" ]; then # Asegurarse de que sea un directorio
        user=$(basename "$user_dir")
        if [ "$user" != "root" ]; then # Evitar configurar root dos veces
             configure_user_vnc_fluxbox "$user_dir" "$user"
        fi
    fi
done

# Configurar un esqueleto de configuración para nuevos usuarios
log_message "Creando un esqueleto de configuración Fluxbox/VNC para nuevos usuarios..."
# Asegúrate de que el esqueleto tenga los permisos correctos al ser copiado
mkdir -p /etc/skel/.fluxbox
mkdir -p /etc/skel/.vnc
cp /home/$(logname)/.fluxbox/startup /etc/skel/.fluxbox/startup # Copia desde un usuario si ya se configuro
cp /home/$(logname)/.vnc/xstartup /etc/skel/.vnc/xstartup       # Copia desde un usuario si ya se configuro
chmod +x /etc/skel/.fluxbox/startup /etc/skel/.vnc/xstartup
log_message "Esqueleto de configuración creado en /etc/skel/. Esto aplicará la configuración por defecto a los nuevos usuarios."


# --- Configuración de Firewall (UFW) ---
log_message "Configurando UFW (Firewall)..."
# Asegúrate de que UFW esté instalado
install_package "ufw"
if ufw status | grep -q "Status: active"; then
    log_message "UFW está activo. Abriendo rango de puertos para VNC (5901-5910/TCP)."
    # Abrimos un rango de puertos para que cada usuario pueda iniciar su propio display VNC
    # VNC Display :1 = Puerto 5901, :2 = Puerto 5902, etc.
    ufw allow 5901:5910/tcp comment "Allow VNC sessions for multiple users" >> "$LOG_FILE" 2>&1
    log_message "Regla de UFW añadida para VNC (puertos 5901-5910/TCP)."
else
    log_message "UFW no está activo. Activándolo y configurando regla para VNC."
    ufw enable >> "$LOG_FILE" 2>&1 # Habilita UFW. Esto puede interrumpir SSH si no está permitido explícitamente.
    ufw allow ssh comment "Allow SSH" >> "$LOG_FILE" 2>&1 # Asegura que SSH siga funcionando
    ufw allow 5901:5910/tcp comment "Allow VNC sessions for multiple users" >> "$LOG_FILE" 2>&1
    ufw default deny incoming >> "$LOG_FILE" 2>&1 # Bloquea todo lo demás por defecto
    log_message "UFW habilitado y configurado con reglas para SSH y VNC."
fi

log_message "Instalación y configuración de escritorio completada."
log_message "--------------------------------------------------------------------------------"
log_message "¡Importante! Acciones de Usuario Requeridas:"
log_message "1. Por cada usuario (incluido root) que quiera usar VNC por primera vez, DEBERÁ:"
log_message "   - Iniciar sesión como ese usuario."
log_message "   - Ejecutar el comando: vncpasswd"
log_message "     Esto establecerá la contraseña para su sesión VNC. Haz esto también para 'root'."
log_message "2. Para iniciar una sesión VNC para un usuario, inicia sesión como ese usuario y ejecuta:"
log_message "   vncserver $VNC_DISPLAY"
log_message "   (Puedes usar otro número de display si el :1 ya está en uso, ej. vncserver :2)"
log_message "   Para detenerla: vncserver -kill $VNC_DISPLAY"
log_message "3. Conéctate a tu VPS usando un cliente VNC en la IP de tu VPS y el puerto VNC."
log_message "   Por ejemplo, para display :1, el puerto es 5901. Dirección: tu_ip_de_vps:5901 o tu_ip_de_vps:1"
log_message "4. Asegúrate de que no haya firewalls de tu proveedor de VPS bloqueando los puertos 5901-5910/TCP."
log_message "--------------------------------------------------------------------------------"

# No se recomienda eliminar el script automáticamente.
# rm "$(basename "$0")"

# Reinicio recomendado para aplicar todos los cambios de kernel y servicios
log_message "El sistema se reiniciará en 10 segundos para aplicar todos los cambios."
sleep 10
reboot
