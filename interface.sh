#!/bin/bash

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

OS="$(uname -s)"

# --- Détection des interfaces réseau (type) ---

detect_interface_type() {
    case "$OS" in
        Linux)
            # Même logique que ton script d'origine
            for interface in $(ls /sys/class/net); do
                if [[ "$interface" == "lo" ]]; then
                    continue
                fi
                if [[ "$interface" == wl* ]]; then
                    echo -e "${RED}$interface:${GREEN} Wi-Fi${NC}"
                elif [[ "$interface" == en* ]]; then
                    echo -e "${RED}$interface:${GREEN} Ethernet${NC}"
                else
                    type=$(cat /sys/class/net/$interface/type 2>/dev/null)
                    case $type in
                        1)
                            echo -e "${RED}$interface:${GREEN} Ethernet${NC}"
                            ;;
                        801)
                            echo -e "${RED}$interface:${GREEN} Wi-Fi${NC}"
                            ;;
                        *)
                            echo -e "${RED}$interface:${YELLOW} Autre type (code: $type)${NC}"
                            ;;
                    esac
                fi
            done
            ;;
        Darwin)
            # macOS : on utilise networksetup pour récupérer les ports matériels
            # et en déduire le type (Wi-Fi / Ethernet / autre)
            while IFS= read -r line; do
                case "$line" in
                    "Hardware Port:"*)
                        port="${line#Hardware Port: }"
                        ;;
                    "Device:"*)
                        dev="${line#Device: }"
                        # Détection du type à partir du nom du port
                        if [[ "$port" == "Wi-Fi" ]]; then
                            type="Wi-Fi"
                        elif [[ "$port" == Ethernet* ]]; then
                            type="Ethernet"
                        else
                            type="Autre ($port)"
                        fi
                        echo -e "${RED}${dev}:${GREEN} ${type}${NC}"
                        ;;
                esac
            done < <(networksetup -listallhardwareports)
            ;;
        *)
            echo -e "${RED}OS non supporté pour la détection du type d'interface ($OS).${NC}"
            ;;
    esac
}

# --- Adresses IP locales ---

detect_local_ip() {
    case "$OS" in
        Linux)
            for interface in $(ls /sys/class/net); do
                if [[ "$interface" == "lo" ]]; then
                    continue
                fi
                ip_address=$(ip -4 addr show "$interface" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
                if [[ -n "$ip_address" ]]; then
                    echo -e "${RED}$interface:${GREEN} $ip_address${NC}"
                fi
            done
            ;;
        Darwin)
            # macOS : on récupère la liste des devices (en0, en1, etc.)
            for interface in $(networksetup -listallhardwareports | awk '/Device/ {print $2}'); do
                # ipconfig getifaddr renvoie l'IPv4 si l'interface est up
                ip_address=$(ipconfig getifaddr "$interface" 2>/dev/null)
                if [[ -n "$ip_address" ]]; then
                    echo -e "${RED}$interface:${GREEN} $ip_address${NC}"
                fi
            done
            ;;
        *)
            echo -e "${RED}OS non supporté pour la détection des IP locales ($OS).${NC}"
            ;;
    esac
}

# --- IP publiques ---

get_public_ipv6() {
    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}curl n'est pas installé, impossible de récupérer l'IPV6 publique.${NC}"
        return
    fi
    public_ipv6=$(curl -s https://api64.ipify.org)
    if [[ -n "$public_ipv6" ]]; then
        echo -e "${RED}IPV6 Internet:${GREEN} $public_ipv6${NC}"
    else
        echo -e "${RED}Impossible de récupérer l'IPV6 publique. Vérifiez votre connexion Internet.${NC}"
    fi
}

get_public_ipv4() {
    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}curl n'est pas installé, impossible de récupérer l'IPV4 publique.${NC}"
        return
    fi
    public_ipv4=$(curl -s https://api.ipify.org)
    if [[ -n "$public_ipv4" ]]; then
        echo -e "${RED}IPV4 Internet:${GREEN} $public_ipv4${NC}"
    else
        echo -e "${RED}Impossible de récupérer l'IPV4 publique. Vérifiez votre connexion Internet.${NC}"
    fi
}

# --- Run ---

clear
echo -e "${BLUE}OS détecté :${NC} $OS"
echo -e "${BLUE}--- Détection des interfaces réseau ---${NC}"
detect_interface_type
echo -e "\n${BLUE}--- Adresses IP locales ---${NC}"
detect_local_ip
echo -e "\n${BLUE}--- Adresse IP Internet ---${NC}"
get_public_ipv6
get_public_ipv4
