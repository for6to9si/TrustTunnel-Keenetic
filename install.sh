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

echo ""
echo "=== Installation complete ==="
echo ""
echo "Next steps:"
echo "1. Place trusttunnel_client binary to /opt/trusttunnel_client/"
echo "2. Create config file /opt/trusttunnel_client/trusttunnel_client.toml"
echo "3. Make binary executable: chmod +x /opt/trusttunnel_client/trusttunnel_client"
echo "4. Start service: /opt/etc/init.d/S99trusttunnel start"
echo ""
