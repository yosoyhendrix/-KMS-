#!/bin/bash

# 1. Actualizar el sistema
sudo pacman -Syu

# 2. Instalar el servidor gráfico (Xorg) y Wayland
# Ubuntu usa Wayland por defecto, pero Xorg es necesario para compatibilidad.
sudo pacman -S --needed xorg xorg-server wayland

# 3. Instalar GNOME y aplicaciones extra
# 'gnome' es el escritorio base. 'gnome-extra' trae utilidades (discos, logs, etc.)
sudo pacman -S --needed gnome gnome-extra

# 4. Instalar el Gestor de Pantalla (GDM - GNOME Display Manager)
# Es la pantalla de inicio de sesión que ves en Ubuntu.
sudo pacman -S --needed gdm

# 5. Habilitar el servicio para que arranque al inicio
sudo systemctl enable gdm

# 6. Instalar herramientas de personalización
sudo pacman -S --needed gnome-tweaks

sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ..
rm -rf yay

# Instala el tema, iconos, sonidos y fuentes de Ubuntu
yay -S yaru-gtk-theme yaru-icon-theme yaru-sound-theme ttf-ubuntu-font-family
sudo pacman -S sbctl
