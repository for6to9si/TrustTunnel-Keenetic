#!/bin/sh

set -e

REPO_URL="https://raw.githubusercontent.com/artemevsevev/TrustTunnel-Keenetic/main"

echo "=== TrustTunnel Keenetic Installer ==="
echo ""

if [ ! -d "/opt" ]; then
    echo "Error: /opt not found. Please install Entware first."
    echo "See: https://help.keenetic.com/hc/en-us/articles/360021214160"
    exit 1
fi

echo "Creating directories..."
mkdir -p /opt/etc/init.d
mkdir -p /opt/etc/ndm/wan.d
mkdir -p /opt/var/run
mkdir -p /opt/var/log

echo "Downloading S99trusttunnel..."
curl -fsSL "$REPO_URL/S99trusttunnel" -o /opt/etc/init.d/S99trusttunnel
chmod +x /opt/etc/init.d/S99trusttunnel

echo "Downloading 010-trusttunnel.sh..."
curl -fsSL "$REPO_URL/010-trusttunnel.sh" -o /opt/etc/ndm/wan.d/010-trusttunnel.sh
chmod +x /opt/etc/ndm/wan.d/010-trusttunnel.sh

ask_yes_no() {
    printf "%s (y/n) " "$1"
    read answer < /dev/tty
    [ "$answer" = "y" ] || [ "$answer" = "Y" ]
}

# === Policy + Interface ===
if ask_yes_no "Создать policy TrustTunnel и интерфейс TrustTunnel?"; then

    # --- Interface ---
    if ndmc -c 'show interface' | grep -q '^Proxy5'; then
        echo "Интерфейс Proxy5 уже существует — пропускаю."
    else
        echo "Создаю интерфейс Proxy5..."
        ndmc -c 'interface Proxy5'
        ndmc -c 'interface Proxy5 description TrustTunnel'
        ndmc -c 'interface Proxy5 dyndns nobind'
        ndmc -c 'interface Proxy5 proxy protocol socks5'
        ndmc -c 'interface Proxy5 proxy upstream 127.0.0.1 1080'
        ndmc -c 'interface Proxy5 proxy connect via ISP'
        ndmc -c 'interface Proxy5 ip global auto'
        ndmc -c 'interface Proxy5 security-level public'
        echo "Интерфейс Proxy5 создан."
    fi

    # --- Policy ---
    if ndmc -c 'show ip policy' | grep -q '^TrustTunnel'; then
        echo "Policy TrustTunnel уже существует — пропускаю."
    else
        echo "Создаю ip policy TrustTunnel..."
        ndmc -c 'ip policy TrustTunnel'
        ndmc -c 'ip policy TrustTunnel description TrustTunnel'
        ndmc -c 'ip policy TrustTunnel permit global Proxy5'
        echo "Policy TrustTunnel создана."
    fi

    ndmc -c 'system configuration save'
    echo "Конфигурация сохранена."
else
    echo "Настройка policy и интерфейса пропущена."
fi


# === TrustTunnel install ===
if ask_yes_no "Установить/Обновить TrustTunnel Client?"; then
    echo "Запускаю установку TrustTunnel..."
    curl -fsSL https://raw.githubusercontent.com/TrustTunnel/TrustTunnelClient/refs/heads/master/scripts/install.sh | sh -s -
    echo "Установка TrustTunnel завершена."
else
    echo "Установка TrustTunnel пропущена."
fi

echo ""
echo "=== Installation complete ==="
echo ""
echo "Next steps:"
echo "1. Create config file /opt/trusttunnel_client/trusttunnel_client.toml"
echo "2. Make binary executable: chmod +x /opt/trusttunnel_client/trusttunnel_client"
echo "3. Start service: /opt/etc/init.d/S99trusttunnel start"
echo ""
