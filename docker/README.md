# Docker 安装和配置脚本

## 概述

`install_docker.sh` 提供 Docker 的完整安装和配置解决方案，特别针对国内网络环境进行了优化。

## 功能特性

### 1. Docker 安装

- 自动检测操作系统
- 支持从国内镜像源下载
- 包含 Docker Compose 插件
- 自动配置用户组

### 2. 镜像加速

支持多个国内镜像加速器：

| 加速器 | 地址 | 说明 |
|--------|------|------|
| 阿里云 | 专属地址 | 需要登录获取 |
| 腾讯云 | `https://mirror.ccs.tencentyun.com` | 推荐 |
| 网易云 | `https://hub-mirror.c.163.com` | 稳定 |
| 中科大 | `https://docker.mirrors.ustc.edu.cn` | 教育网友好 |
| Docker 中国区 | `https://registry.docker-cn.com` | 官方 |

### 3. 代理配置

配置 Docker 守护进程使用代理拉取镜像：

- HTTP 代理
- HTTPS 代理
- NO_PROXY 配置

### 4. 用户组配置

将当前用户添加到 docker 组，免 sudo 使用 Docker。

## 使用方法

### 交互式安装

```bash
wget https://raw.githubusercontent.com/qfpqhyl/server-scripts/main/docker/install_docker.sh
chmod +x install_docker.sh
sudo ./install_docker.sh
```

### 自动安装

```bash
sudo ./install_docker.sh --auto
```

## 菜单选项

1. **完整安装（推荐）**: 安装 Docker + 配置镜像加速 + 用户组
2. **仅安装 Docker**: 只安装 Docker Engine
3. **仅配置镜像加速**: 只配置镜像加速器
4. **仅配置代理**: 只配置 Docker 代理
5. **测试 Docker**: 运行测试容器
6. **退出**

## 配置文件

### daemon.json

位置：`/etc/docker/daemon.json`

示例配置：

```json
{
  "registry-mirrors": ["https://mirror.ccs.tencentyun.com"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

### 代理配置

位置：`/etc/systemd/system/docker.service.d/http-proxy.conf`

示例配置：

```ini
[Service]
Environment="HTTP_PROXY=http://127.0.0.1:8080"
Environment="HTTPS_PROXY=http://127.0.0.1:8080"
Environment="NO_PROXY=localhost,127.0.0.1,*.local"
```

## 获取阿里云镜像加速地址

1. 登录阿里云控制台：https://cr.console.aliyun.com
2. 点击左侧「镜像加速器」
3. 选择您所在的地域
4. 复制加速器地址，格式类似：`https://xxxxx.mirror.aliyuncs.com`

## 常用命令

```bash
# 查看 Docker 版本
docker --version
docker compose version

# 查看运行中的容器
docker ps

# 查看所有容器
docker ps -a

# 查看镜像列表
docker images

# 拉取镜像
docker pull nginx

# 运行容器
docker run -d -p 80:80 nginx

# 查看容器日志
docker logs <container_id>

# 停止容器
docker stop <container_id>

# 删除容器
docker rm <container_id>

# 删除镜像
docker rmi <image_id>

# 查看 Docker 信息
docker info

# 清理未使用的资源
docker system prune -a
```

## Docker Compose 使用

创建 `docker-compose.yml`：

```yaml
version: '3'
services:
  web:
    image: nginx
    ports:
      - "80:80"
```

运行：

```bash
# 启动
docker compose up -d

# 停止
docker compose down

# 查看日志
docker compose logs -f

# 重启
docker compose restart
```

## 验证安装

```bash
# 测试 Docker
docker run --rm hello-world

# 查看系统信息
docker info | grep -E "Server Version|Storage Driver|Registry Mirrors"
```

## 故障排除

### Docker 无法启动

```bash
# 查看服务状态
sudo systemctl status docker

# 查看日志
sudo journalctl -u docker.service
```

### 权限问题

```bash
# 将用户添加到 docker 组
sudo usermod -aG docker $USER

# 立即生效
newgrp docker

# 或者重新登录
```

### 镜像拉取失败

1. 检查镜像加速器配置
2. 尝试配置代理
3. 检查网络连接

```bash
# 查看配置
sudo cat /etc/docker/daemon.json

# 重启 Docker
sudo systemctl restart docker
```

## 注意事项

1. **系统要求**: 
   - Linux 内核版本 ≥ 3.10
   - 支持的系统架构：x86_64, aarch64

2. **磁盘空间**: 
   - 建议至少 20GB 可用空间

3. **防火墙**: 
   - Docker 会修改 iptables 规则

4. **SELinux**: 
   - CentOS/RHEL 系统可能需要配置 SELinux

5. **存储驱动**: 
   - 推荐使用 overlay2

## 卸载 Docker

```bash
# Ubuntu/Debian
sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

# CentOS/RHEL
sudo yum remove docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```

## 参考资料

- [Docker 官方文档](https://docs.docker.com/)
- [Docker Hub](https://hub.docker.com/)
- [Docker Compose 文档](https://docs.docker.com/compose/)
