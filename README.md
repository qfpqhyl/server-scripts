# 🚀 一站式 Linux 服务器配置与环境部署

![Linux Server](https://img.shields.io/badge/Linux-Server-informational?style=flat-square&logo=linux&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-5.0+-blue?style=flat-square&logo=gnu-bash&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)
![Development Status](https://img.shields.io/badge/Status-Active%20Development-yellow?style=flat-square)
![V2Ray](https://img.shields.io/badge/V2Ray-✅%20Completed-brightgreen?style=flat-square)

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

## 📋 功能模块开发状态

### ✅ 已完成

#### 🌐 代理工具 (`proxy/`) - **V2Ray模块已完成**

- ✅ **V2Ray**: 完整版 VMess/VLESS/Shadowsocks 支持
  - 多协议支持 (VMess, VLESS, Shadowsocks)
  - 智能订阅解析和管理
  - 服务器切换和状态监控
  - 本机代理/局域网共享模式
  - DNS优化和智能路由
  - 完整的管理命令集

### 🚧 开发中 (TODO)

#### 🔧 系统初始化 (`system/`) - **计划开发**

- [ ] 系统更新和基础软件包安装
- [ ] 时区同步和 NTP 配置
- [ ] 用户和权限管理
- [ ] SSH 安全配置
- [ ] 基础防火墙设置

#### 🌐 代理工具扩展 (`proxy/`) - **计划开发**

- [ ] **sing-box**: 新一代通用代理工具
- [ ] **Hysteria2**: 高性能代理协议
- [ ] 统一代理管理界面
- [ ] 多代理协议切换

#### 🐳 Docker 环境 (`docker/`) - **计划开发**

- [ ] Docker CE/EE 安装
- [ ] Docker Compose 配置
- [ ] 镜像加速器配置
- [ ] 常用应用容器模板
- [ ] 数据持久化配置

#### 🐍 Python 环境 (`python/`) - **计划开发**

- [ ] 多版本 Python 安装管理
- [ ] pip 国内源配置
- [ ] 虚拟环境管理
- [ ] 常用科学计算包预装
- [ ] Jupyter Notebook 配置

#### ⚡ 性能优化 (`performance/`) - **计划开发**

- [ ] 系统内核参数优化
- [ ] 文件描述符限制调整
- [ ] 内存和 CPU 优化
- [ ] 网络参数调优
- [ ] 磁盘 I/O 优化

## 🚀 快速开始

### 方法一：一键安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/qfpqhyl/server-scripts/main/quick_install.sh | bash
```

### 方法二：分模块安装

```bash
# 克隆仓库
git clone https://github.com/qfpqhyl/server-scripts.git
cd server-scripts

# 运行主安装脚本
./install.sh
```

## 📁 项目结构

```
server-scripts/
├── README.md                   # 主文档
├── proxy/                      # 代理工具模块 ✅ 已完成
│   ├── README.md              # V2Ray模块详细说明
│   └── install_v2ray.sh       # V2Ray完整安装脚本
└── [计划开发的模块]            # 🚧 TODO
    ├── system/                # 系统初始化模块 (计划中)
    ├── docker/                # Docker环境模块 (计划中)
    ├── python/                # Python环境模块 (计划中)
    ├── performance/           # 性能优化模块 (计划中)
    ├── utils/                 # 工具脚本库 (计划中)
    └── config/                # 配置文件目录 (计划中)
```

## 🔧 配置选项

在运行安装脚本前，你可以通过修改配置文件来自定义安装选项：

```bash
# 编辑配置文件
vim config/common.conf

# 主要配置项：
INSTALL_MODULES="system,proxy,docker,python,performance"
PROXY_TYPE="v2ray"              # 可选: v2ray, singbox, hysteria2
PYTHON_VERSIONS="3.9,3.10,3.11"
DOCKER_COMPOSE_VERSION="2.20.0"
```

## 📖 使用指南

### 系统要求

- **操作系统**: Ubuntu 18.04+, CentOS 7+, Debian 9+
- **内存**: 最低 1GB，推荐 2GB+
- **磁盘**: 最低 10GB 可用空间
- **网络**: 稳定的互联网连接

### 安装后使用

#### ✅ V2Ray代理管理 (已可用)

```bash
# 进入proxy目录并安装
cd proxy
./install_v2ray.sh

# V2Ray管理命令 (安装后可用)
v2start          # 启动V2Ray
v2stop           # 停止V2Ray
v2restart        # 重启V2Ray
v2status         # 查看状态
v2switch         # 切换服务器
v2update         # 更新订阅
proxy_on         # 开启代理
proxy_off        # 关闭代理
```

#### 🚧 其他模块 (开发中)

以下功能正在开发中，暂时不可用：

- [ ] Docker 环境管理
- [ ] Python 环境配置
- [ ] 系统性能优化
- [ ] 系统初始化工具

## 🛡️ 安全说明

- 所有脚本仅使用用户权限执行，无需 root 权限
- 代理工具默认仅监听本地回环地址
- SSH 密钥登录推荐禁用密码认证
- 防火墙默认只开放必要端口

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支: `git checkout -b feature/AmazingFeature`
3. 提交更改: `git commit -m 'Add some AmazingFeature'`
4. 推送分支: `git push origin feature/AmazingFeature`
5. 提交 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## ⭐ Star History

如果这个项目对你有帮助，请给个 Star 支持一下！

## 🙏 致谢

感谢以下开源项目：

- [V2Ray](https://github.com/v2fly/v2ray-core)
- [sing-box](https://github.com/SagerNet/sing-box)
- [Hysteria2](https://github.com/apernet/hysteria)
- [Docker](https://github.com/docker/docker-ce)

---

<div align="center">

**[⬆ 回到顶部](#-一站式-linux-服务器配置与环境部署)**

Made with ❤️ for Chinese developers & researchers

</div>
