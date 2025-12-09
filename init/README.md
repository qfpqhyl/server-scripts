# 系统初始化脚本

## 概述

`system_init.sh` 是一个综合性的 Linux 系统初始化脚本，提供快速配置新服务器所需的各项功能。

## 功能特性

### 1. 镜像源切换

- **Ubuntu/Debian**: 支持阿里云、清华、中科大、华为云、网易镜像
- **CentOS/RHEL**: 支持阿里云、清华、中科大、华为云镜像
- 自动备份原始配置

### 2. 基础工具安装

安装常用开发和管理工具：
- `curl`, `wget`: 文件下载
- `git`: 版本控制
- `vim`, `nano`: 文本编辑器
- `htop`: 系统监控
- `net-tools`: 网络工具
- `unzip`, `tar`: 压缩工具
- `build-essential`: 编译工具

### 3. SSH 优化

- 禁用 DNS 解析，加速连接
- 关闭 GSSAPI 认证
- 配置连接保活
- 自动备份配置

### 4. 时区和语言

- 设置为中国时区（Asia/Shanghai）
- 配置中文语言环境

### 5. 系统优化

- 文件描述符限制优化
- 内核参数优化
- 网络参数优化
- 内存管理优化

## 使用方法

### 交互式模式

```bash
wget https://raw.githubusercontent.com/qfpqhyl/server-scripts/main/init/system_init.sh
chmod +x system_init.sh
sudo ./system_init.sh
```

按照提示选择需要的功能。

### 自动模式

```bash
sudo ./system_init.sh --auto
```

自动执行完整初始化（使用默认选项）。

## 菜单选项

1. **完整初始化（推荐）**: 执行所有初始化步骤
2. **仅更换镜像源**: 只更换软件包镜像源
3. **仅安装基础工具**: 只安装常用工具
4. **仅系统优化**: 只应用系统优化配置
5. **显示系统信息**: 查看当前系统信息
6. **退出**: 退出脚本

## 支持的系统

- Ubuntu 18.04+
- Debian 10+
- CentOS 7+
- Rocky Linux 8+
- AlmaLinux 8+

## 配置备份

脚本会自动备份以下配置：

- `/etc/apt/sources.list.bak` (Ubuntu/Debian)
- `/etc/yum.repos.d/backup/` (CentOS/RHEL)
- `/etc/ssh/sshd_config.bak`

## 优化后的参数

### 文件描述符

```
* soft nofile 65535
* hard nofile 65535
```

### 内核参数

```
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_reuse = 1
fs.file-max = 1000000
```

## 注意事项

1. 需要 root 或 sudo 权限
2. 更换镜像源后会自动更新包索引
3. SSH 配置修改后会自动重启 SSH 服务
4. 建议在新系统上首次运行

## 故障排除

### 镜像源无法访问

尝试更换其他镜像源：

```bash
sudo ./system_init.sh
# 选择选项 2，然后选择其他镜像源
```

### SSH 连接问题

恢复原始配置：

```bash
sudo cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
sudo systemctl restart sshd
```

### 内核参数未生效

手动应用：

```bash
sudo sysctl -p /etc/sysctl.d/99-custom.conf
```
