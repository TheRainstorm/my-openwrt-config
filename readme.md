### 说明

使用uci自动配置openwrt路由器。

- `router-basic`: 用于自动设置openwrt到一个可用状态
- `router-adv`: 将一些配置如ddns, wiregurad, zerotier, firewall导入，用于将一个路由器配置迁移到另一个路由器时。相比于官方的备份恢复功能，控制粒度更加细，避免备份一些无用配置。
- `mesh-dumb-ap`: 自动配置路由为一个802.11s mesh节点，设置成dumb AP等