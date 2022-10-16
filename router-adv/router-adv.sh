# ==========================================
# 此脚本用于将一些已经配置好的配置导入进来，用于
# 备份恢复。比openwrt提供的备份还原功能的优点在于
# 控制粒度更细，可以只备份自己想要的部分。通常用于
# 将一个路由器的配置迁移到新路由器
# ==========================================
ZEROTIER_IP='192.168.196.10'        #修改为自己的zerotier地址
ZEROTIER_MASK='255.255.255.0'

# ================================ firewall ================================
# === firewall/zone ===
echo "[INFO] firewall zone"
uci -m import firewall < ./default/firewall-zone-guest  #创建 guest zone
# === firewall/rule ===
echo "[INFO] firewall rule"
uci -m import firewall < ./default/firewall-rule-basic

# ================================ wireguard ================================
# === wireguard/s2s ===
echo "[INFO] load wg_s2s network"
uci -m import network < ./network-wg_s2s
echo "[INFO] load wireguard wg_s2s"
uci -m import firewall < ./default/firewall-zone-wg_s2s
uci add_list firewall.wg_s2s.network='wg_s2s'       # 添加到 wg_s2s zone

# === wireguard/wg0 ===
echo "[INFO] load wg0 network"
uci -m import network < ./network-wg0
echo "[INFO] add wg0 to lan"
uci add_list firewall.@zone[0].network='wg0'        #添加到 lan zone

# === wireguard/wg1 ===
echo "[INFO] load wg1 network"
uci -m import network < ./network-wg1
echo "[INFO] load firewall guest"
uci add_list firewall.guest.network='wg1'           #添加到 guest zone

# ================================ else ================================
# === ddns ===
echo "[INFO] Import ddns config"
uci -m import ddns < ./ddns

# === zerotier ===
echo "[INFO] Import zerotier config"
mkdir /etc/zerotier
uci -m import zerotier < ./zerotier
echo "[INFO] start zerotier"
/etc/init.d/zerotier enable
/etc/init.d/zerotier start
echo "[INFO] add zerotier network"
uci set network.Zerotier=interface
uci set network.Zerotier.proto='static'
uci set network.Zerotier.device='ztyou4dlov'
uci set network.Zerotier.netmask=$ZEROTIER_MASK
uci set network.Zerotier.ipaddr=$ZEROTIER_IP
echo "[INFO] add zerotier to lan zone"
uci add_list firewall.@zone[0].network='Zerotier'   # add Zerotier to lan