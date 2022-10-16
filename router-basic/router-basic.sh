# 脚本会自动配置openwrt起到一个基本路由器的作用，
# 会配置局域网地址，开启无线，配置dhcp或pppoe上网
# 请结合自己的硬件进行修改
# ==========================================
# 将config.txt内容复制到此处                
# ==========================================


## === system ====
# password
echo "[INFO] Updating root password"
NEWPASSWD=$ROOT_PASSWD
passwd <<EOF
$NEWPASSWD
$NEWPASSWD
EOF
# timezone
TIMEZONE='CST-8'
ZONENAME='Asia/Shanghai'
echo "[INFO] set timezone to $ZONENAME"
uci set system.@system[0].timezone="$TIMEZONE"
uci set system.@system[0].zonename="$ZONENAME"
echo "[INFO] set hostname to $HOSTNAME"
uci set system.@system[0].hostname=$HOSTNAME
uci commit system

## === ssh/dropbear ===
echo "[INFO] change ssh port to $SSH_PORT"
uci set dropbear.@dropbear[0].Port=$SSH_PORT
uci commit dropbear
echo "[INFO] add ssh key"
echo $PUB_KEY >> /etc/dropbear/authorized_keys
chmod 644 /etc/dropbear/authorized_keys

## === lan network ===
echo "[INFO] set LAN ip to $LAN_IPADDR"
uci set network.lan.proto="static"
uci set network.lan.ipaddr=$LAN_IPADDR
uci commit network

## === wan network ===
echo "[INFO] set WAN to get network"
if [ $IS_PPPOE -eq 1 ]; then
    echo "[INFO] set pppoe"
    uci set network.wan.proto='pppoe'
    uci set network.wan.username="$PPPOE_USERNAME"
    uci set network.wan.password="$PPPOE_PASSWORD"
else
    echo "[INFO] default dhcp, nothing to do"
    uci delete network.wan      #delete wan(clean wan config)
    uci set network.wan=interface   #crate wan
    uci set network.wan.proto='dhcp'
    uci set network.wan.device='wan'
fi
uci commit network

# === wireless ===
echo "[INFO] set wireless $WIFI, $WIFI_5G, passwd: $WIFI_PASSWD"
uci set wireless.radio0.disabled="$DISABLE_RADIO0"
uci set wireless.radio0.channel='auto'
uci set wireless.default_radio0.disabled="$DISABLE_RADIO0"
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

# === ipv6 ===
if [ $IS_PPPOE -eq 0 ]; then
    # === ipv6/dhcp ===
    echo "[INFO] set ipv6/dhcp"
    uci set dhcp.lan.ra='relay'
    uci set dhcp.lan.dhcpv6='relay'
    uci set dhcp.lan.ndp='relay'
    uci set dhcp.lan.ra_flags='none'
    uci delete dhcp.wan6
    uci set dhcp.wan6=dhcp      #add named section, name=wan6
    uci set dhcp.wan6.interface='wan6'
    uci set dhcp.wan6.dhcpv6='relay'
    uci set dhcp.wan6.ra='relay'
    uci set dhcp.wan6.ndp='relay'
    uci set dhcp.wan6.master='1'
    uci commit dhcp
else
    # === ipv6/pppoe ===
    # 设置wan.ipv6='auto'就可以正常ipv6上网了
    # 另外设置lan.ip6class='wan_6'可以避免LAN获得ULA地址（私有ipv6地址）
    echo "[INFO] set ipv6/pppoe"
    uci delete network.wan6
    uci set network.wan.ipv6='auto'
    uci del_list network.lan.ip6class
    uci add_list network.lan.ip6class='wan_6'
    uci commit network

    uci set dhcp.lan.dhcpv6='server'
    uci set dhcp.lan.ra='server'
    uci commit dhcp
fi
