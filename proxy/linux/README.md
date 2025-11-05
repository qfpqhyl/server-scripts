# V2Ray 代理安装模块

V2Ray 完整版安装脚本，无需 root 权限即可安装，支持 VMess、VLESS、Shadowsocks 协议，具备完整的服务器管理和订阅切换功能。

## 功能特性

- ✅ **多协议支持**: VMess、VLESS、Shadowsocks
- ✅ **智能订阅解析**: 自动解析多种格式订阅链接
- ✅ **服务器管理**: 节点切换、状态监控、自动重连
- ✅ **代理模式**: 本机代理 / 局域网共享
- ✅ **安全认证**: 支持用户名密码认证
- ✅ **DNS 优化**: 国内 DNS 优化配置
- ✅ **智能路由**: 分流规则，国内外流量智能处理

## 快速使用

### 步骤 1：准备工作

如果服务器网络受限无法直接访问外网，需要先建立临时代理隧道：

```bash
# 在本地机器上执行（确保本地有代理服务运行在10809端口，根据自己情况，设置别的端口也可以）
ssh -R 10809:127.0.0.1:10809 username@your-server-ip -p ssh-port
```

然后在服务器上设置临时代理：

```bash
export http_proxy=http://127.0.0.1:10809
export https_proxy=http://127.0.0.1:10809
```

### 步骤 2：下载并运行安装脚本

```bash
# 下载安装脚本
wget https://raw.githubusercontent.com/qfpqhyl/server-scripts/main/proxy/linux/install_v2ray.sh

# 给脚本执行权限
chmod +x install_v2ray.sh

# 运行安装脚本
./install_v2ray.sh
```

### 步骤 3：输入订阅链接

安装过程中会提示输入 V2Ray 订阅链接：

```
请输入订阅链接: https://your-subscription-url.com/link/xxxxx
```

### 步骤 4：选择服务器

脚本会自动解析订阅并显示所有可用服务器，选择一个进行连接：

```
=== 所有服务器 (25) ===
[1] 🔵 香港-VMess-01
    VMESS - hk1.example.com:443
[2] 🟢 美国-VLESS-02
    VLESS - us1.example.com:443
[3] 🟡 日本-SS-03
    SHADOWSOCKS - jp1.example.com:8080

请选择要使用的服务器 (1-25) [默认: 1]: 1
```

### 步骤 5：完成安装

安装完成后，运行以下命令加载别名配置：

```bash
source ~/.bashrc
```

现在可以取消临时代理设置：

```bash
unset http_proxy https_proxy
```

## 基本管理命令

安装完成后，可使用以下别名命令（需要 `source ~/.bashrc` 生效）：

```bash
# 服务管理
v2start          # 启动V2Ray
v2stop           # 停止V2Ray
v2restart        # 重启V2Ray
v2status         # 查看状态
v2log            # 查看日志

# 服务器管理
v2switch         # 切换服务器
v2list           # 列出所有服务器
v2vmess          # 列出VMess服务器
v2vless          # 列出VLESS服务器
v2ss             # 列出Shadowsocks服务器

# 订阅管理
v2update         # 更新订阅
v2scan           # 重新解析订阅

# 代理连接
v2connect        # 快速连接代理
proxy_on         # 开启代理
proxy_off        # 关闭代理
proxy_status     # 查看代理状态
```

## 配置说明

### 代理端口配置

| 代理类型 | 端口 | 用途          |
| -------- | ---- | ------------- |
| SOCKS5   | 1080 | 通用代理协议  |
| HTTP     | 8080 | HTTP 代理协议 |

### DNS 配置

- **国内 DNS**: 223.5.5.5 (阿里云)
- **备用 DNS**: 114.114.114.114
- **国外 DNS**: 8.8.8.8 (Google)
- **分流规则**: 国内外流量智能分流

### 路由规则

- **直连**: 私有 IP、国内 IP、国内域名
- **代理**: 国外 IP 和域名
- **策略**: IPOnDemand 智能选择

## 文件结构

安装完成后，V2Ray 的工作目录位于 `~/v2ray/`：

```
~/v2ray/
├── v2ray                    # V2Ray 主程序
├── config.json              # 当前配置文件
├── servers_all.json         # 所有服务器配置
├── subscription.txt         # 原始订阅内容
├── subscription_url.txt     # 订阅链接
├── v2ray.log                # 运行日志
├── v2ray.pid                # 进程PID文件
├── full_parser.py           # 订阅解析脚本
├── server_manager.py        # 服务器管理脚本
├── start.sh                 # 启动脚本
├── stop.sh                  # 停止脚本
├── restart.sh               # 重启脚本
├── status.sh                # 状态脚本
├── switch.sh                # 切换脚本
├── update.sh                # 更新脚本
└── connect.sh               # 连接脚本
```

## 常见问题

### Q: 如何更换订阅链接？

A: 运行 `v2update` 命令，选择输入新的订阅链接即可。

### Q: 如何切换到其他服务器？

A: 运行 `v2switch` 命令，选择要切换的服务器编号。

### Q: 局域网其他设备如何连接？

A: 确保选择局域网共享模式，使用以下地址：

- SOCKS5: `socks5://用户名:密码@服务器IP:1080`
- HTTP: `http://用户名:密码@服务器IP:8080`

### Q: 如何查看当前使用的服务器？

A: 运行 `v2status` 命令，会显示当前服务器信息。

### Q: 连接失败怎么办？

A:

1. 检查 `v2status` 确认服务运行状态
2. 查看 `v2log` 检查错误日志
3. 尝试 `v2switch` 切换其他服务器
4. 运行 `v2update` 更新订阅

## 更新日志

### v3.0

- 新增 VLESS 协议支持
- 优化订阅解析算法
- 改进服务器管理界面
- 增强错误处理机制
- 添加连接测试功能

### v2.0

- 重构配置生成逻辑
- 支持局域网共享模式
- 添加用户认证功能
- 优化 DNS 配置

### v1.0

- 基础 VMess 支持
- 简单订阅解析
- 基本服务器切换

## 技术支持

如遇到问题，请：

1. 查看本文档的常见问题部分
2. 检查日志文件 `~/v2ray/v2ray.log`
3. 提交 Issue 到项目仓库

---

**注意**: 本脚本仅用于学习和研究目的，请遵守当地法律法规。
