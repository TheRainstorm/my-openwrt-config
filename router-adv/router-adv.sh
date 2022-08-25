# ==========================================
# 此脚本用于将一些已经配置好的配置导入进来，用于
# 备份恢复。比openwrt提供的备份还原功能的优点在于
# 控制粒度更细，可以只备份自己想要的部分。通常用于
# 将一个路由器的配置迁移到新路由器
# 
# 默认包含
#   ddns
#   zerotier
#   wireguard
# ==========================================
ZEROTIER_IP='192.168.196.10'        #修改为自己的zerotier地址
ZEROTIER_MASK='255.255.255.0'


# ============direct import ==================
# === ddns ===
echo "[INFO] Import ddns config"
uci -m import ddns < ./config/ddns
uci commit ddns

# === zerotier ===
echo "[INFO] Import zerotier config"
mkdir /etc/zerotier
uci -m import zerotier < ./config/zerotier
uci commit zerotier

echo "[INFO] start zerotier"
/etc/init.d/zerotier enable
/etc/init.d/zerotier start

echo "[INFO] add zerotier network"
uci set network.Zerotier=interface
uci set network.Zerotier.proto='static'
uci set network.Zerotier.device='ztyou4dlov'
uci set network.Zerotier.netmask=$ZEROTIER_MASK
uci set network.Zerotier.ipaddr=$ZEROTIER_IP
uci commit network

echo "[INFO] add zerotier to lan zone"
uci add_list firewall.@zone[0].network='Zerotier'   #add firewire zone
uci commit firewall

# ============ self config ==================
# wireguard
echo "[INFO] load wireguard network"
uci -m import network < ./config/network-wg_s2s
uci -m import network < ./config/network-wg0
uci commit network
echo "[INFO] load wireguard firewall"
uci -m import firewall < ./config/firewall-wg_s2s
uci add_list firewall.@zone[0].network='wg0'   #add wg0 to lan
uci commit firewall

# === firewall ===
# https://openwrt.org/docs/guide-user/firewall/firewall_configuration
# 默认可能有一个include /etc/firewall.user的规则，为了防止冲突，使用自定义名字
echo "[INFO] set basic firewall"
uci -m import firewall < ./config/firewall-basic
uci commit firewall