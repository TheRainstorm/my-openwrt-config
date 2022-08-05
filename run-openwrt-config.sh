#load user config
source ./CONFIG.sh

# ================== basic ==================
echo "[INFO] Updating root password"
NEWPASSWD=$ROOT_PASSWD
passwd <<EOF
$NEWPASSWD
$NEWPASSWD
EOF

## === ssh/dropbear ===
echo "[INFO] change ssh port to $SSH_PORT"
uci set dropbear.@dropbear[0].Port=$SSH_PORT
uci commit dropbear
echo "[INFO] add ssh key"
echo $PUB_KEY >> /etc/dropbear/authorized_keys
chmod 644 /etc/dropbear/authorized_keys

## === system ====
echo "[INFO] set timezone"
uci set system.@system[0].timezone="$TIMEZONE"
uci set system.@system[0].zonename="$ZONENAME"
echo "[INFO] set hostname to $HOSTNAME"
uci set system.@system[0].hostname=$HOSTNAME
uci commit system

# ================== network ==================
# === network ===
echo "[INFO] set LAN ip to $LAN_IPADDR"
uci set network.lan.proto="static"
uci set network.lan.ipaddr=$LAN_IPADDR
uci commit network

# === wireless ===
echo "[INFO] set wireless $WIFI_5G, passwd: $WIFI_PASSWD"
uci set wireless.radio0.disabled='1'
uci set wireless.radio0.channel='auto'
uci set wireless.default_radio0.disabled='1'
uci set wireless.default_radio0.ssid="$WIFI"
uci set wireless.default_radio0.encryption='psk2'
uci set wireless.default_radio0.key=$WIFI_PASSWD
uci set wireless.radio1.disabled='0'
uci set wireless.radio1.channel='auto'
uci set wireless.default_radio1.disabled='0'
uci set wireless.default_radio1.ssid="$WIFI_5G"
uci set wireless.default_radio1.encryption='psk2'
uci set wireless.default_radio1.key=$WIFI_PASSWD
uci commit wireless

# === ipv6/dhcp ===
echo "[INFO] set ipv6"
uci set dhcp.lan.ra='relay'
uci set dhcp.lan.dhcpv6='relay'
uci set dhcp.lan.ndp='relay'
uci set dhcp.lan.ra_flags='none'
uci delete dhcp.wan6
uci set dhcp.wan6=dhcp
uci set dhcp.wan6.interface='wan6'
uci set dhcp.wan6.dhcpv6='relay'
uci set dhcp.wan6.ra='relay'
uci set dhcp.wan6.ndp='relay'
uci set dhcp.wan6.master='1'
uci commit dhcp

# === ddns ===
echo "[INFO] Import ddns config"
uci -m import ddns < ./config/ddns
uci commit ddns

# ================== vpn ==================
# === zerotier ===
echo "[INFO] Import zerotier config"
mkdir /etc/zerotier
uci -m import zerotier < ./config/zerotier
uci commit zerotier
echo "[INFO] start zerotier"
/etc/init.d/zerotier enable
/etc/init.d/zerotier start

uci set network.Zerotier=interface
uci set network.Zerotier.proto='static'
uci set network.Zerotier.device='ztyou4dlov'
uci set network.Zerotier.netmask=$ZEROTIER_MASK
uci set network.Zerotier.ipaddr=$ZEROTIER_IP
uci commit network

echo "[INFO] add zerotier to lan zone"
uci add_list firewall.@zone[0].network='Zerotier'   #add firewire zone

# === wireguard ===
# === wireguard: site to site ===
echo "[INFO] write wireguard config directly"
uci -m import network < ./config/network-wireguard-s2s
uci -m import firewall < ./config/firewall-wireguard-s2s

# === wireguard: wg0 ===
uci -m import network < ./config/network-wireguard-wg0
uci add_list firewall.@zone[0].network=$WG_WG0      #add firewire zone

uci commit network
# === firewall ===
uci commit firewall