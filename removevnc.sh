# Desinstala los paquetes de TigerVNC y sus archivos de configuración
sudo apt remove --purge tigervnc-standalone-server tigervnc-common -y
echo "Paquetes TigerVNC desinstalados."

# Opcional: Si habías instalado TightVNC en algún momento
# sudo apt remove --purge tightvncserver -y
# echo "Paquetes TightVNC desinstalados (si estaban presentes)."

# Elimina cualquier dependencia que ya no sea necesaria
sudo apt autoremove -y
echo "Dependencias no usadas eliminadas."

# Limpia el caché de paquetes descargados
sudo apt autoclean -y
echo "Caché de paquetes limpiado."
sudo apt install tightvncserver -y
