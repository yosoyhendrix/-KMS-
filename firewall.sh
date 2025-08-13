#!/bin/bash

# Define las direcciones IP que tendrán acceso al puerto SSH (22)
IP_ACCESO_SSH_1="68.183.120.175"
IP_ACCESO_SSH_2="5.189.150.48"

# --- Parte 1: Borrar todas las reglas existentes ---
echo "Borrando todas las reglas existentes en iptables y ip6tables..."
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

ip6tables -F
ip6tables -X
ip6tables -t nat -F
ip6tables -t nat -X
ip6tables -t mangle -F
ip6tables -t mangle -X

# --- Parte 2: Configurar las políticas por defecto ---
# Denegar todo el tráfico entrante por defecto
iptables -P INPUT DROP
ip6tables -P INPUT DROP

# Permitir todo el tráfico saliente
iptables -P OUTPUT ACCEPT
ip6tables -P OUTPUT ACCEPT

# Permitir el tráfico ya establecido y relacionado
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Permitir tráfico en la interfaz de loopback (localhost)
iptables -A INPUT -i lo -j ACCEPT
ip6tables -A INPUT -i lo -j ACCEPT

# --- Parte 3: Permitir el acceso SSH solo desde las IPs específicas (IPv4) ---
echo "Permitiendo acceso SSH (puerto 22) solo desde las IPs: ${IP_ACCESO_SSH_1} y ${IP_ACCESO_SSH_2}"
iptables -A INPUT -p tcp --dport 22 -s ${IP_ACCESO_SSH_1} -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -s ${IP_ACCESO_SSH_2} -j ACCEPT

# --- Parte 4: Bloquear completamente el acceso SSH por IPv6 ---
echo "Bloqueando completamente el acceso al puerto 22 por IPv6..."
ip6tables -A INPUT -p tcp --dport 22 -j DROP

# --- Parte 5: Permitir el resto del tráfico entrante (cualquier otro puerto) ---
# Esta regla permite el tráfico a todos los demás puertos.
# El tráfico al puerto 22 será denegado a menos que venga de las IPs especificadas
# en el paso 3, debido a la política por defecto `DROP` y la ubicación de las reglas.
echo "Permitiendo el resto del tráfico entrante a todos los demás puertos..."
iptables -A INPUT -j ACCEPT
ip6tables -A INPUT -j ACCEPT

echo "Configuración del firewall completada."
echo "Para verificar las reglas, usa los comandos: iptables -L y ip6tables -L"
