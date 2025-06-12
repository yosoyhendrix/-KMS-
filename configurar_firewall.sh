#!/bin/bash

# Script para configurar IPTables en Debian 12 (IPv4 e IPv6)

# Asegurarse de que el script se ejecuta como root
if [[ $EUID -ne 0 ]]; then
   echo "Este script debe ejecutarse como root" 
   exit 1
fi

echo "Limpiando todas las reglas existentes de IPTables (IPv4 e IPv6)..."

# Flush (borrar) todas las reglas de IPTables (IPv4)
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -F
iptables -X
iptables -Z

# Flush (borrar) todas las reglas de IP6Tables (IPv6)
ip6tables -P INPUT ACCEPT
ip6tables -P FORWARD ACCEPT
ip6tables -P OUTPUT ACCEPT
ip6tables -F
ip6tables -X
ip6tables -Z

echo "Reglas de IPTables borradas. Estableciendo nuevas reglas..."

# 1. Políticas por defecto: Denegar todo el tráfico entrante y de reenvío
# Permitir todo el tráfico saliente (OUTPUT)
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT ACCEPT

# 2. Permitir tráfico de loopback (localhost) para IPv4 e IPv6
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

ip6tables -A INPUT -i lo -j ACCEPT
ip6tables -A OUTPUT -o lo -j ACCEPT

# 3. Permitir conexiones ya establecidas y relacionadas para IPv4 e IPv6
# Esto es crucial para que las respuestas a tus conexiones salientes sean permitidas
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# 4. Reglas específicas para la IP 68.183.120.175 (solo IPv4)
# Puerto 22 (SSH) TCP
iptables -A INPUT -p tcp --dport 22 -s 68.183.120.175 -j ACCEPT

# Puerto 5901 (VNC, etc.) TCP
iptables -A INPUT -p tcp --dport 5901 -s 68.183.120.175 -j ACCEPT

# 5. Puertos abiertos para todo público (IPv4 e IPv6)
# Puerto 21 (FTP) TCP
iptables -A INPUT -p tcp --dport 21 -j ACCEPT
ip6tables -A INPUT -p tcp --dport 21 -j ACCEPT

# Puerto 80 (HTTP) TCP
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
ip6tables -A INPUT -p tcp --dport 80 -j ACCEPT

# Puerto 443 (HTTPS) TCP
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
ip6tables -A INPUT -p tcp --dport 443 -j ACCEPT

# 6. Permitir todo el tráfico UDP (IPv4 e IPv6)
iptables -A INPUT -p udp -j ACCEPT
ip6tables -A INPUT -p udp -j ACCEPT

# 7. Guardar las reglas para que persistan después de un reinicio
# Necesitarás tener instalado el paquete `iptables-persistent`
# Si no lo tienes, puedes instalarlo con:
# apt update && apt install iptables-persistent -y
echo "Guardando las reglas de IPTables e IP6Tables..."
netfilter-persistent save

echo "Configuración de IPTables completada."
echo "Puedes verificar las reglas con: iptables -L -n -v"
echo "Y para IPv6: ip6tables -L -n -v"

