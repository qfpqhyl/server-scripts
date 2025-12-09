# V2Ray WSL 安装脚本

适用于 Windows Subsystem for Linux (WSL) 环境的 V2Ray 代理安装脚本。

## 特性

- 🎯 **WSL 专属优化**: 针对 WSL 环境定制
- 🌐 **多协议支持**: VMess、VLESS、Shadowsocks
- 🔄 **Windows 共享**: 支持 WSL 与 Windows 系统共享代理
- ⚡ **简单易用**: 一键安装，自动配置

## 使用方法

### 快速安装

```bash
cd ~/
wget https://raw.githubusercontent.com/qfpqhyl/server-scripts/main/proxy/wsl/install_v2ray.sh
chmod +x install_v2ray.sh
./install_v2ray.sh
```

### 代理模式

#### 1. 本机模式（仅 WSL 内使用）
- SOCKS5: `127.0.0.1:1080`
- HTTP: `127.0.0.1:8080`

#### 2. Windows 共享模式（推荐）
- WSL 内访问: `127.0.0.1:1080` / `127.0.0.1:8080`
- Windows 访问: `<WSL_IP>:1080` / `<WSL_IP>:8080`
  - WSL IP 可通过在 WSL 中运行 `hostname -I` 获取

## 常用命令

```bash
v2start      # 启动 V2Ray
v2stop       # 停止 V2Ray
v2status     # 查看状态
v2restart    # 重启 V2Ray
```

## Windows 系统代理设置

### 方法一：系统代理设置
1. 打开 Windows 设置 → 网络和 Internet → 代理
2. 手动设置代理：
   - 地址：WSL IP（例如：`172.x.x.x`）
   - 端口：`8080`（HTTP）或 `1080`（SOCKS5）

### 方法二：浏览器插件
推荐使用 SwitchyOmega 等代理插件，配置：
- 协议：HTTP 或 SOCKS5
- 服务器：WSL IP
- 端口：对应端口号

## 注意事项

1. **WSL IP 变化**: WSL 重启后 IP 可能会变化，需要重新获取
2. **防火墙**: 如果 Windows 无法连接，检查 WSL 防火墙设置
3. **订阅链接**: 需要准备好 V2Ray 订阅链接

## 故障排除

### WSL 无法启动 V2Ray
```bash
# 检查日志
tail -f ~/v2ray/v2ray.log

# 测试配置
cd ~/v2ray && ./v2ray test -config config.json
```

### Windows 无法连接
```bash
# 1. 获取 WSL IP
hostname -I

# 2. 检查 V2Ray 是否运行
v2status

# 3. 测试端口连接（在 Windows PowerShell 中）
Test-NetConnection -ComputerName <WSL_IP> -Port 8080
```
