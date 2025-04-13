#!/bin/bash

WG_INTERFACE="wg0"
WG_DIR="/etc/wireguard"
CLIENTS_DIR="$WG_DIR/clients"
USED_IPS_FILE="$WG_DIR/used_ips.txt"
WG_CONFIG="$WG_DIR/$WG_INTERFACE.conf"
WG_PORT=51820
WG_SUBNET="10.10.0"
SERVER_IP="$WG_SUBNET.1"
CURRENT_DIR="$(pwd)"

function check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root (use sudo)"
        exit 1
    fi
}

function install_wireguard() {
    if ! command -v wg > /dev/null; then
        echo "[+] Installing WireGuard..."
        apt update && apt install -y wireguard
    fi
}

function init_server_config() {
    if [ ! -f "$WG_CONFIG" ]; then
        echo "[+] Initializing server config..."

        mkdir -p "$CLIENTS_DIR"
        touch "$USED_IPS_FILE"
        echo "$SERVER_IP" >> "$USED_IPS_FILE"

        umask 077
        wg genkey | tee "$WG_DIR/server_private.key" | wg pubkey > "$WG_DIR/server_public.key"

        SERVER_PUBLIC_IP=$(curl -s https://api.ipify.org)

        cat > "$WG_CONFIG" <<EOF
[Interface]
Address = $SERVER_IP/24
ListenPort = $WG_PORT
PrivateKey = $(cat "$WG_DIR/server_private.key")
MTU=1220
EOF

        systemctl enable "wg-quick@$WG_INTERFACE"
        systemctl start "wg-quick@$WG_INTERFACE"
    fi
}

function get_next_ip() {
    for i in {2..254}; do
        CANDIDATE="$WG_SUBNET.$i"
        grep -qx "$CANDIDATE" "$USED_IPS_FILE" || {
            echo "$CANDIDATE" >> "$USED_IPS_FILE"
            echo "$CANDIDATE"
            return
        }
    done
    echo "Error: No available IPs!" >&2
    exit 1
}

function add_client() {
    echo "Enter a name for the new client:"
    read -r CLIENT_NAME

    # Validate client name
    if [[ -z "$CLIENT_NAME" ]]; then
        echo "Error: Client name cannot be empty"
        return 1
    fi

    CLIENT_IP=$(get_next_ip)
    CLIENT_PRIV=$(wg genkey)
    CLIENT_PUB=$(echo "$CLIENT_PRIV" | wg pubkey)
    SERVER_PUB=$(cat "$WG_DIR/server_public.key")
    SERVER_PUBLIC_IP=$(curl -s https://api.ipify.org)

    if [[ -z "$SERVER_PUBLIC_IP" ]]; then
        echo "Error: Could not determine server public IP"
        return 1
    fi

    echo "[+] Generating client config for $CLIENT_NAME ($CLIENT_IP)"

    CLIENT_CONF="$CURRENT_DIR/${CLIENT_NAME}_wg.conf"
    cat > "$CLIENT_CONF" <<EOF
[Interface]
PrivateKey = $CLIENT_PRIV
Address = $CLIENT_IP/32
MTU=1220

[Peer]
PublicKey = $SERVER_PUB
Endpoint = $SERVER_PUBLIC_IP:$WG_PORT
# Only route traffic to the server IP
AllowedIPs = $SERVER_IP/32
PersistentKeepalive = 25
EOF

    echo "[+] Saving client config to $CLIENT_CONF"

    echo "
# $CLIENT_NAME
[Peer]
PublicKey = $CLIENT_PUB
# Only accept traffic from this client's IP
AllowedIPs = $CLIENT_IP/32
" >> "$WG_CONFIG"

    echo "$CLIENT_NAME,$CLIENT_IP" >> "$CLIENTS_DIR/client_list.csv"

    echo "[+] Restarting WireGuard to apply new client..."
    systemctl restart "wg-quick@$WG_INTERFACE"

    echo "[+] Configuration complete!"
    echo "[+] To connect, copy ${CLIENT_NAME}_wg.conf to your client machine"
    echo "[+] Note: This configuration will only route traffic between the server ($SERVER_IP) and client ($CLIENT_IP)"
}

function delete_client() {
    if [ ! -f "$CLIENTS_DIR/client_list.csv" ]; then
        echo "No clients to delete."
        return
    fi

    echo "Available clients:"
    nl -w2 -s'. ' "$CLIENTS_DIR/client_list.csv" | cut -d, -f1

    echo "Enter the number of the client to delete:"
    read -r CLIENT_NUM

    SELECTED_LINE=$(sed -n "${CLIENT_NUM}p" "$CLIENTS_DIR/client_list.csv")
    CLIENT_NAME=$(echo "$SELECTED_LINE" | cut -d, -f1)
    CLIENT_IP=$(echo "$SELECTED_LINE" | cut -d, -f2)

    if [ -z "$CLIENT_NAME" ] || [ -z "$CLIENT_IP" ]; then
        echo "Invalid selection."
        return
    fi

    echo "[+] Deleting $CLIENT_NAME ($CLIENT_IP)..."

    sed -i "/# $CLIENT_NAME/,+4d" "$WG_CONFIG"
    sed -i "\|$CLIENT_IP|d" "$USED_IPS_FILE"
    sed -i "\|^$CLIENT_NAME,|d" "$CLIENTS_DIR/client_list.csv"

    echo "[+] Restarting WireGuard after deletion..."
    systemctl restart "wg-quick@$WG_INTERFACE"
}

function uninstall_wireguard() {
    echo "Are you sure you want to completely remove WireGuard and all configs? [y/N]"
    read -r CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        systemctl stop "wg-quick@$WG_INTERFACE"
        systemctl disable "wg-quick@$WG_INTERFACE"
        apt remove --purge -y wireguard wireguard-tools
        rm -rf "$WG_DIR"
        echo "[+] WireGuard and all configuration files removed."
    else
        echo "Aborted."
    fi
}

function show_menu() {
    echo "Choose an action:"
    select opt in "Add New Client" "Delete Existing Client" "Uninstall WireGuard and Remove All Configs" "Exit"; do
        case $REPLY in
            1) add_client; break ;;
            2) delete_client; break ;;
            3) uninstall_wireguard; break ;;
            4) exit 0 ;;
            *) echo "Invalid option. Try again." ;;
        esac
    done
}

### MAIN
check_root
install_wireguard
init_server_config
show_menu
