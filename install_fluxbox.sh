#!/bin/bash

# Este script instala un escritorio ligero con Fluxbox, Firefox y ROX-Filer en Ubuntu 20.04.

# --- Configuración ---
USERNAME=$(whoami) # Obtiene el nombre de usuario actual
LOG_FILE="/tmp/fluxbox_install.log"
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
    if sudo apt install -y "$PACKAGE" >> "$LOG_FILE" 2>&1; then
        log_message "$PACKAGE instalado correctamente."
    else
        log_message "Error al instalar $PACKAGE. Revisar $LOG_FILE para más detalles."
        exit 1
    fi
}

# --- Inicio del Script ---

check_root
log_message "Iniciando la instalación de escritorio ligero con Fluxbox, Firefox y ROX-Filer."
log_message "Los detalles de la instalación se guardarán en $LOG_FILE"

# 1. Actualizar el sistema
log_message "Actualizando la lista de paquetes e instalando actualizaciones disponibles..."
if sudo apt update -y >> "$LOG_FILE" 2>&1 && sudo apt upgrade -y >> "$LOG_FILE" 2>&1; then
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

# 4. Instalar un gestor de pantalla ligero (LightDM recomendado)
log_message "Instalando LightDM (gestor de pantalla)..."
# Cuando se te pregunte qué gestor de pantalla usar, selecciona lightdm.
install_package "lightdm"

# 5. Instalar Firefox (navegador web)
log_message "Instalando Firefox (navegador web)..."
install_package "firefox"

# 6. Instalar ROX-Filer (gestor de archivos)
log_message "Instalando ROX-Filer (gestor de archivos)..."
install_package "rox-filer"

# 7. Herramientas adicionales útiles
log_message "Instalando herramientas adicionales (terminator, policykit-1-gnome, lxappearance, htop, feh)..."
# terminator: Una terminal mejor que la predeterminada de Xorg.
# policykit-1-gnome: Necesario para que algunas aplicaciones gráficas se eleven privilegios (ej. gestor de red).
# lxappearance: Para cambiar temas de GTK si se desea.
# htop: Monitor de procesos mejorado.
# feh: Visor de imágenes ligero y para establecer el fondo de pantalla.
install_package "terminator"
install_package "policykit-1-gnome"
install_package "lxappearance"
install_package "htop"
install_package "feh"

# 8. Configuración inicial de Fluxbox para el usuario actual
log_message "Configurando Fluxbox para el usuario '$USERNAME'..."

# Crear el directorio de configuración de Fluxbox si no existe
mkdir -p /home/$USERNAME/.fluxbox
chown -R $USERNAME:$USERNAME /home/$USERNAME/.fluxbox

# Copiar el archivo de inicio por defecto de Fluxbox y modificarlo
# Asegúrate de que el archivo `startup` contenga la inicialización de ROX-Filer y policykit-1-gnome
# Si el usuario ya tiene un archivo startup, se recomienda hacer una copia de seguridad primero
if [ -f /home/$USERNAME/.fluxbox/startup ]; then
    log_message "Copia de seguridad de /home/$USERNAME/.fluxbox/startup en /home/$USERNAME/.fluxbox/startup.bak_$DATE"
    cp /home/$USERNAME/.fluxbox/startup /home/$USERNAME/.fluxbox/startup.bak_"$DATE"
fi

cat <<EOL > /home/$USERNAME/.fluxbox/startup
#!/bin/bash

# Iniciar policykit para permitir la autenticación gráfica (ej. para wifi)
if which /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 > /dev/null; then
    /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 &
fi

# Iniciar ROX-Filer para el escritorio (pinboard)
# Puedes usar 'rox-filer &' si solo quieres el gestor de archivos y no el pinboard.
# 'rox -S &' permite iconos en el escritorio.
rox -S &

# Establecer el fondo de pantalla (opcional, requiere 'feh')
# Puedes cambiar la ruta a tu imagen de fondo
# Ejemplo: feh --bg-scale /usr/share/backgrounds/warty-final-ubuntu.png &
# Para un fondo de color sólido: xsetroot -solid "#2E3436" &
xsetroot -solid "#2E3436" & # Un gris oscuro por defecto

# Si tienes un gestor de red (ej. network-manager-applet)
# nm-applet &

# Iniciar el gestor de ventanas Fluxbox
exec fluxbox
EOL

# Dar permisos de ejecución al script de inicio
chmod +x /home/$USERNAME/.fluxbox/startup
chown $USERNAME:$USERNAME /home/$USERNAME/.fluxbox/startup

log_message "Configuración de Fluxbox completada para el usuario '$USERNAME'."

# 9. Configurar LightDM para iniciar Fluxbox por defecto (opcional, pero útil)
# Esto asegura que LightDM sepa iniciar Fluxbox. LightDM detecta automáticamente los escritorios,
# pero a veces es bueno ser explícito o si no lo detecta.
# NOTA: En Ubuntu 20.04, LightDM suele detectar Fluxbox automáticamente.
# Si encuentras problemas, puedes editar /etc/lightdm/lightdm.conf y establecer 'user-session=fluxbox'
# bajo la sección [Seat:*]. Por simplicidad, no lo incluimos en el script a menos que sea necesario.

log_message "Instalación completada. Reinicia tu sistema para iniciar el nuevo escritorio."
log_message "Cuando el sistema se reinicie, deberías ver la pantalla de inicio de sesión de LightDM."
log_message "Selecciona 'Fluxbox' como sesión antes de iniciar sesión."
log_message "Para un entorno mínimo, es posible que necesites configurar tu red y sonido manualmente."

exit 0
