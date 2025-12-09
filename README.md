# 🚀 一站式 Linux 服务器配置与环境部署

![Linux Server](https://img.shields.io/badge/Linux-Server-informational?style=flat-square&logo=linux&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-5.0+-blue?style=flat-square&logo=gnu-bash&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)
![Development Status](https://img.shields.io/badge/Status-Active%20Development-yellow?style=flat-square)

**面向国内开发者与科研人员的快速部署工具**

支持系统初始化 · 代理安装 · Docker · Python 环境 · 性能优化

解决「部署慢、网络差、环境乱」等痛点

## ✨ 特色功能

- 🎯 **一键部署**: 从裸机到生产就绪，一条命令搞定
- 🌐 **网络优化**: 针对国内网络环境优化，支持多种代理协议
- 🐳 **容器化**: Docker & Docker Compose 一键安装
- 🐍 **Python 环境**: 多版本 Python 管理，包安装加速
- ⚡ **性能优化**: 系统参数调优，资源使用优化
- 🛡️ **安全加固**: 基础安全配置，防火墙设置

## 📋 目录结构

```
server-scripts/
├── init/              # 系统初始化脚本
│   └── system_init.sh     # 系统初始化（换源、基础工具等）
├── proxy/             # 代理安装脚本
│   ├── linux/            # Linux 版本
│   │   └── install_v2ray.sh
│   └── wsl/              # WSL 版本
│       └── install_v2ray.sh
├── docker/            # Docker 相关脚本
│   └── install_docker.sh  # Docker 安装和配置
├── python/            # Python 环境脚本
│   └── setup_python.sh    # Miniconda 安装和配置
└── performance/       # 性能优化脚本
    └── optimize.sh        # 系统性能优化
```

## 🚀 快速开始

### 1. 系统初始化

完整的系统初始化，包括更换国内镜像源、安装基础工具、系统优化等：

```bash
# 下载并运行系统初始化脚本
wget https://raw.githubusercontent.com/qfpqhyl/server-scripts/main/init/system_init.sh
chmod +x system_init.sh
sudo ./system_init.sh

# 或者直接自动运行
sudo ./system_init.sh --auto
```

**功能包括：**
- 🔄 更换国内镜像源（阿里云、清华、中科大等）
- 🛠️ 安装基础工具（curl、wget、git、vim等）
- ⚙️ SSH 优化配置
- 🌍 时区和语言环境配置
- ⚡ 系统参数优化

---

### 2. 代理安装

#### Linux 版本

支持 VMess、VLESS、Shadowsocks 协议的完整版 V2Ray 安装：

```bash
cd ~/
wget https://raw.githubusercontent.com/qfpqhyl/server-scripts/main/proxy/linux/install_v2ray.sh
chmod +x install_v2ray.sh
./install_v2ray.sh
```

**特性：**
- 🌐 多协议支持（VMess、VLESS、SS）
- 🔄 订阅链接自动解析
- 🎯 多服务器切换
- 🔒 支持本机代理和局域网共享
- 📡 自定义端口配置

**常用命令：**
```bash
v2start      # 启动 V2Ray
v2stop       # 停止 V2Ray
v2status     # 查看状态
v2switch     # 切换服务器
v2update     # 更新订阅
proxy_on     # 启用代理环境变量
proxy_off    # 禁用代理环境变量
```

#### WSL 版本

专为 WSL (Windows Subsystem for Linux) 优化的版本：

```bash
cd ~/
wget https://raw.githubusercontent.com/qfpqhyl/server-scripts/main/proxy/wsl/install_v2ray.sh
chmod +x install_v2ray.sh
./install_v2ray.sh
```

**WSL 特性：**
- 🔄 支持 WSL 与 Windows 系统共享代理
- 📡 自动获取 WSL IP 地址
- 🌐 Windows 可通过 WSL IP 访问代理

详见：[WSL 安装说明](proxy/wsl/README.md)

---

### 3. Docker 安装

一键安装 Docker，配置镜像加速和代理：

```bash
wget https://raw.githubusercontent.com/qfpqhyl/server-scripts/main/docker/install_docker.sh
chmod +x install_docker.sh
sudo ./install_docker.sh

# 或者自动安装
sudo ./install_docker.sh --auto
```

**功能包括：**
- 🐳 Docker Engine 安装
- 🚀 Docker Compose 插件安装
- 🌐 镜像加速配置（阿里云、腾讯云等）
- 🔧 代理配置（用于拉取国外镜像）
- 👥 用户组配置

**镜像加速源：**
- 阿里云（需要专属地址）
- 腾讯云
- 网易云
- 中科大
- Docker 中国区

---

### 4. Python 环境

使用 Miniconda 管理 Python 环境：

```bash
wget https://raw.githubusercontent.com/qfpqhyl/server-scripts/main/python/setup_python.sh
chmod +x setup_python.sh
./setup_python.sh

# 或者自动安装
./setup_python.sh --auto
```

**功能包括：**
- 🐍 Miniconda 安装（支持 Python 3.9-3.11）
- 🌐 conda 镜像源配置
- 📦 pip 镜像源配置
- 🔧 常用工具安装（ipython、jupyterlab等）
- 📊 预配置环境（数据科学、深度学习）

**常用命令：**
```bash
conda env list               # 列出所有环境
conda create -n myenv python=3.11  # 创建新环境
conda activate myenv         # 激活环境
conda deactivate            # 退出环境
pip install package         # 安装包
```

**镜像源选项：**
- conda: 清华、阿里云、中科大
- pip: 清华、阿里云、中科大、豆瓣、腾讯云

---

### 5. 性能优化

全面的系统性能优化：

```bash
wget https://raw.githubusercontent.com/qfpqhyl/server-scripts/main/performance/optimize.sh
chmod +x optimize.sh
sudo ./optimize.sh

# 或者自动优化
sudo ./optimize.sh --auto
```

**优化内容：**

#### 网络优化
- TCP 缓冲区优化
- 连接队列优化
- TIME_WAIT 状态优化
- TCP Fast Open
- BBR 拥塞控制算法

#### 文件系统优化
- 文件描述符限制提升
- inotify 监控优化
- 磁盘 I/O 调度器优化

#### 内存优化
- Swap 使用优化
- 脏页写回优化
- 内存分配策略

#### CPU 优化
- CPU 频率调节器配置
- 进程和线程数限制优化

#### 安全优化
- SYN Cookies 防护
- SYN Flood 攻击防护

---

## 📖 详细文档

### 系统要求

- **操作系统**: Ubuntu 18.04+, Debian 10+, CentOS 7+, Rocky Linux 8+
- **权限**: root 或 sudo 权限
- **网络**: 互联网连接

### 支持的发行版

| 发行版 | 版本 | 状态 |
|--------|------|------|
| Ubuntu | 18.04, 20.04, 22.04 | ✅ 完全支持 |
| Debian | 10, 11, 12 | ✅ 完全支持 |
| CentOS | 7, 8 | ✅ 完全支持 |
| Rocky Linux | 8, 9 | ✅ 完全支持 |
| AlmaLinux | 8, 9 | ✅ 完全支持 |

---

## 🎯 使用场景

### 场景 1: 新服务器快速部署

```bash
# 1. 系统初始化
sudo ./init/system_init.sh --auto

# 2. 安装代理
./proxy/linux/install_v2ray.sh

# 3. 安装 Docker
sudo ./docker/install_docker.sh --auto

# 4. 安装 Python
./python/setup_python.sh --auto

# 5. 性能优化
sudo ./performance/optimize.sh --auto
```

### 场景 2: 科研服务器配置

```bash
# 1. 系统初始化和优化
sudo ./init/system_init.sh --auto
sudo ./performance/optimize.sh --auto

# 2. 安装 Python 环境
./python/setup_python.sh --auto

# 3. 安装 Docker（用于容器化应用）
sudo ./docker/install_docker.sh --auto
```

### 场景 3: WSL 开发环境

```bash
# 1. 安装 WSL 版代理
./proxy/wsl/install_v2ray.sh

# 2. 安装 Python 环境
./python/setup_python.sh --auto

# 3. 安装 Docker（如果需要）
sudo ./docker/install_docker.sh --auto
```

---

## 🔧 配置文件位置

| 功能 | 配置文件位置 | 说明 |
|------|------------|------|
| V2Ray | `~/v2ray/config.json` | V2Ray 配置文件 |
| Docker | `/etc/docker/daemon.json` | Docker 守护进程配置 |
| Conda | `~/.condarc` | conda 配置文件 |
| pip | `~/.pip/pip.conf` | pip 配置文件 |
| 内核参数 | `/etc/sysctl.d/99-performance.conf` | 性能优化参数 |
| 资源限制 | `/etc/security/limits.conf` | 文件描述符等限制 |

---

## 💡 常见问题

### 1. 如何恢复原始配置？

所有脚本在修改配置前都会创建备份：

```bash
# 查看备份
ls -la /etc/apt/sources.list.bak      # Ubuntu/Debian 源备份
ls -la /etc/yum.repos.d/backup/       # CentOS/RHEL 源备份
ls -la /etc/sysctl.conf.bak           # 内核参数备份
ls -la /etc/security/limits.conf.bak  # 资源限制备份
```

### 2. Docker 需要 sudo 权限怎么办？

运行以下命令将用户添加到 docker 组：

```bash
sudo usermod -aG docker $USER
newgrp docker  # 立即生效
```

### 3. 代理连接失败怎么办？

```bash
# 1. 检查 V2Ray 状态
v2status

# 2. 查看日志
tail -f ~/v2ray/v2ray.log

# 3. 测试配置
cd ~/v2ray && ./v2ray test -config config.json

# 4. 重启服务
v2restart
```

### 4. Python 环境冲突怎么办？

使用 conda 环境隔离：

```bash
# 创建独立环境
conda create -n myproject python=3.11

# 激活环境
conda activate myproject

# 安装依赖
pip install -r requirements.txt
```

### 5. 性能优化后系统不稳定？

恢复备份配置：

```bash
# 查找备份目录
ls -la /root/performance_backup_*

# 恢复配置
sudo cp /root/performance_backup_*/sysctl.conf.bak /etc/sysctl.conf
sudo sysctl -p

# 重启系统
sudo reboot
```

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

---

## 📝 更新日志

### v1.0.0 (2025-01-XX)

- ✨ 新增系统初始化脚本
- ✨ 新增 WSL 版本代理安装
- ✨ 新增 Docker 安装和配置脚本
- ✨ 新增 Python 环境配置脚本（Miniconda）
- ✨ 新增性能优化脚本
- 📝 更新完整文档

---

## ⭐ Star History

如果这个项目对你有帮助，请给个 Star 支持一下！

[![Star History Chart](https://api.star-history.com/svg?repos=qfpqhyl/server-scripts&type=Date)](https://star-history.com/#qfpqhyl/server-scripts&Date)

---

## 📄 License

MIT License &copy; 2025 秋风飘起黄叶落

---

## 🙏 致谢

感谢所有为本项目做出贡献的开发者！

特别感谢以下镜像源提供商：
- 阿里云
- 清华大学 TUNA 协会
- 中国科学技术大学
- 腾讯云
- 网易
- 华为云

---

<p align="center">
  <b>⭐ 如果觉得有用，请给个 Star 支持一下！⭐</b>
</p>
