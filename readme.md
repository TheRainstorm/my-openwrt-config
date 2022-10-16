### 说明

使用uci自动配置openwrt路由器。

- `router-basic`: 用于自动设置openwrt到一个可用状态
    - system: hostname, timezone
    - ssh/dropbear: key, port
    - wan network: dhcp, pppoe
    - lan network: static address
    - wifi: SSID, password
    - ipv6: 配置SLAAC
- `router-adv`: 将一些配置如ddns, wiregurad, zerotier, firewall导入，用于将一个路由器配置迁移到另一个路由器时。相比于官方的备份恢复功能，控制粒度更加细，避免备份一些无用配置。
    - firewall/zone: 设置基本的防火墙zone规则
    - firewall/rule: 设置基本的防火墙rule规则
    - wireguard/s2s: 用于路由器间组网
    - wireguard/wg0: 用于个人vpn
    - wireguard/wg1: 用于guest vpn
    - ddns
    - zerotier
- `mesh-dumb-ap`: 自动配置路由为一个802.11s mesh节点，设置成dumb AP等