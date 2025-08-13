#!/bin/bash

# Este script configura el firewall para tu VPS con Ubuntu usando iptables e ip6tables.
# Solo permite el acceso SSH desde IPs específicas y bloquea el resto.

# Definir las IPs permitidas para el acceso SSH
ALLOWED_SSH_IPS=("68.183.120.175" "5.189.150.48")

# Puerto SSH
SSH_PORT="22"

# 1. Borrar todas las reglas existentes de iptables e ip6tables
echo "Borrando todas las reglas existentes de iptables..."
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

echo "Borrando todas las reglas existentes de ip6tables..."
ip6tables -F
ip6tables -X
ip6tables -t nat -F
ip6tables -t nat -X
ip6tables -t mangle -F
ip6tables -t mangle -X

# Establecer la política por defecto a DROP para las cadenas INPUT, FORWARD y OUTPUT
# Esto es una medida de seguridad que bloqueará todo el tráfico que no esté explícitamente permitido
echo "Estableciendo la política por defecto a DROP..."
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT ACCEPT

# 2. Permitir el tráfico SSH desde las IPs específicas
echo "Configurando acceso SSH solo para las IPs permitidas..."
for ip in "${ALLOWED_SSH_IPS[@]}"; do
    echo "Permitiendo acceso SSH desde la IP: $ip"
    iptables -A INPUT -p tcp --dport "$SSH_PORT" -s "$ip" -j ACCEPT
done

# 3. Bloquear el acceso al puerto 22/TCP por IPv6
echo "Bloqueando todo el acceso al puerto 22 por IPv6..."
ip6tables -A INPUT -p tcp --dport "$SSH_PORT" -j DROP

# 4. Permitir el tráfico de red general
# Permitir tráfico ya establecido o relacionado (esencial para que las conexiones salientes funcionen)
echo "Permitiendo tráfico establecido y relacionado..."
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Permitir tráfico de loopback
echo "Permitiendo el tráfico de loopback..."
iptables -A INPUT -i lo -j ACCEPT
ip6tables -A INPUT -i lo -j ACCEPT

# Permitir tráfico ICMP (ping) para diagnóstico de red
echo "Permitiendo el tráfico ICMP..."
iptables -A INPUT -p icmp -j ACCEPT
ip6tables -A INPUT -p ipv6-icmp -j ACCEPT

# Opcional: Si tienes un servidor web, puedes permitir el tráfico HTTP/HTTPS
# Descomenta las siguientes líneas si las necesitas.
# echo "Permitiendo tráfico web (HTTP/HTTPS)..."
# iptables -A INPUT -p tcp --dport 80 -j ACCEPT
# iptables -A INPUT -p tcp --dport 443 -j ACCEPT

echo "Configuración del firewall completada."
