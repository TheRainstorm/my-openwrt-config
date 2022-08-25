# ==========================================
# 将config.txt内容复制到此处                
# ==========================================


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
TIMEZONE='CST-8'
ZONENAME='Asia/Shanghai'
echo "[INFO] set timezone to $ZONENAME"
uci set system.@system[0].timezone="$TIMEZONE"
uci set system.@system[0].zonename="$ZONENAME"
echo "[INFO] set hostname to $HOSTNAME"
uci set system.@system[0].hostname=$HOSTNAME
uci commit system


# ================== wireless(mesh + fast roaming) ==================
uci delete wireless.default_radio0
uci delete wireless.default_radio1

echo "[INFO] set mesh radio"
uci set wireless.mesh=wifi-iface
uci set wireless.mesh.device=$MESH_RADIO
uci set wireless.mesh.mode='mesh'
uci set wireless.mesh.encryption='sae'
uci set wireless.mesh.mesh_id=$MESH_NAME
uci set wireless.mesh.mesh_fwding='1'
uci set wireless.mesh.mesh_rssi_threshold='0'
uci set wireless.mesh.key=$MESH_PWD
uci set wireless.mesh.network='lan'
uci set "wireless.$MESH_RADIO.channel"=$MESH_CHANNEL
uci delete "wireless.$MESH_RADIO.disabled"

echo "[INFO] set AP radio"
uci set wireless.default_radio1=wifi-iface
uci set wireless.default_radio1.device=$WIFI_RADIO
uci set wireless.default_radio1.mode='ap'
uci set wireless.default_radio1.ssid=$WIFI_NAME
uci set wireless.default_radio1.encryption='psk2'
uci set wireless.default_radio1.key=$WIFI_PWD
uci set wireless.default_radio1.ieee80211r='1'
uci set wireless.default_radio1.mobility_domain=$WIFI_MOBDOMAIN
uci set wireless.default_radio1.ft_over_ds='0' #0 over air, 1 over DS
uci set wireless.default_radio1.ft_psk_generate_local='1'
uci set wireless.default_radio1.network='lan'
uci set "wireless.$WIFI_RADIO.channel"=$WIFI_CHANNEL
uci delete "wireless.$WIFI_RADIO.disabled"

uci set wireless.default_radio0=wifi-iface
uci set wireless.default_radio0.disabled='1'  #关闭
uci set wireless.default_radio0.device=$MESH_RADIO
uci set wireless.default_radio0.mode='ap'
uci set wireless.default_radio0.ssid=$MESH_WIFI_NAME
uci set wireless.default_radio0.encryption='psk2'
uci set wireless.default_radio0.key=$WIFI_PWD
uci set wireless.default_radio0.ieee80211r='1'
uci set wireless.default_radio0.mobility_domain=$WIFI_MOBDOMAIN
uci set wireless.default_radio0.ft_over_ds='0' #0 over air, 1 over DS
uci set wireless.default_radio0.ft_psk_generate_local='1'
uci set wireless.default_radio0.network='lan'
uci set "wireless.$MESH_RADIO.channel"=$MESH_WIFI_CHANNEL


# ================== set dumb ap ==================
echo "[INFO] close services"
# these services do not run on dumb APs
for i in firewall dnsmasq odhcpd; do
  if /etc/init.d/"$i" enabled; then
    /etc/init.d/"$i" disable
    /etc/init.d/"$i" stop
  fi
done

echo "[INFO] set lan dhcp"
uci del dhcp.wan
uci del network.wan
uci del network.wan6

uci set network.lan.proto='dhcp'
uci del network.lan.ipaddr
uci del network.lan.netmask

echo "[INFO] close dhcp"
# ipv4 dhcp
uci set dhcp.lan.ignore='1'
uci del dhcp.lan.ra_flags
uci add_list dhcp.lan.ra_flags='none'

# ipv6 dhcp
uci del dhcp.lan.ra
uci del dhcp.lan.ra_slaac
uci del dhcp.lan.dhcpv6

uci commit

echo "[INFO] remove firewall config"
mv /etc/config/firewall /etc/config/firewall.unused