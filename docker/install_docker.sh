#!/bin/bash

# Docker 安装和配置脚本 v1.0
# 支持：Docker 安装、镜像加速、代理配置

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_banner() {
    echo -e "${PURPLE}"
    echo "=================================================="
    echo "       Docker 安装和配置脚本 v1.0"
    echo "=================================================="
    echo "功能: Docker 安装 | 镜像加速 | 代理配置"
    echo "=================================================="
    echo -e "${NC}"
}

# 检测操作系统
detect_os() {
    print_info "检测操作系统..."
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
        print_success "检测到系统: $NAME $VERSION"
    else
        print_error "无法检测操作系统"
        exit 1
    fi
}

# 检查 Docker 是否已安装
check_docker_installed() {
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
        print_info "检测到已安装 Docker 版本: $DOCKER_VERSION"
        return 0
    else
        print_info "未检测到 Docker"
        return 1
    fi
}

# 卸载旧版本 Docker
remove_old_docker() {
    print_info "检查并卸载旧版本 Docker..."
    
    case $OS in
        ubuntu|debian)
            sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
            ;;
        centos|rhel|rocky|almalinux)
            sudo yum remove -y docker docker-client docker-client-latest docker-common \
                docker-latest docker-latest-logrotate docker-logrotate docker-engine 2>/dev/null || true
            ;;
    esac
    
    print_success "旧版本清理完成"
}

# 安装 Docker - Ubuntu/Debian
install_docker_ubuntu() {
    print_info "安装 Docker (Ubuntu/Debian)..."
    
    # 更新包索引
    print_info "更新包索引..."
    sudo apt-get update
    
    # 安装依赖
    print_info "安装依赖包..."
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # 添加 Docker GPG 密钥
    print_info "添加 Docker GPG 密钥..."
    sudo mkdir -p /etc/apt/keyrings
    
    # 选择镜像源
    echo ""
    echo "选择 Docker 下载源:"
    echo "1) 阿里云 (推荐)"
    echo "2) 清华大学"
    echo "3) 官方源"
    echo ""
    read -p "请选择 [1-3, 默认: 1]: " mirror_choice
    mirror_choice=${mirror_choice:-1}
    
    case $mirror_choice in
        1)
            DOCKER_MIRROR="https://mirrors.aliyun.com/docker-ce"
            print_info "使用阿里云镜像源"
            ;;
        2)
            DOCKER_MIRROR="https://mirrors.tuna.tsinghua.edu.cn/docker-ce"
            print_info "使用清华大学镜像源"
            ;;
        3)
            DOCKER_MIRROR="https://download.docker.com"
            print_info "使用官方镜像源"
            ;;
        *)
            DOCKER_MIRROR="https://mirrors.aliyun.com/docker-ce"
            print_info "使用阿里云镜像源"
            ;;
    esac
    
    curl -fsSL $DOCKER_MIRROR/linux/$OS/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # 设置仓库
    print_info "设置 Docker 仓库..."
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] $DOCKER_MIRROR/linux/$OS \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 更新包索引
    sudo apt-get update
    
    # 安装 Docker
    print_info "安装 Docker Engine..."
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    print_success "Docker 安装完成"
}

# 安装 Docker - CentOS/RHEL
install_docker_centos() {
    print_info "安装 Docker (CentOS/RHEL)..."
    
    # 安装依赖
    print_info "安装依赖包..."
    sudo yum install -y yum-utils device-mapper-persistent-data lvm2
    
    # 选择镜像源
    echo ""
    echo "选择 Docker 下载源:"
    echo "1) 阿里云 (推荐)"
    echo "2) 清华大学"
    echo "3) 官方源"
    echo ""
    read -p "请选择 [1-3, 默认: 1]: " mirror_choice
    mirror_choice=${mirror_choice:-1}
    
    case $mirror_choice in
        1)
            DOCKER_MIRROR="https://mirrors.aliyun.com/docker-ce"
            print_info "使用阿里云镜像源"
            ;;
        2)
            DOCKER_MIRROR="https://mirrors.tuna.tsinghua.edu.cn/docker-ce"
            print_info "使用清华大学镜像源"
            ;;
        3)
            DOCKER_MIRROR="https://download.docker.com"
            print_info "使用官方镜像源"
            ;;
        *)
            DOCKER_MIRROR="https://mirrors.aliyun.com/docker-ce"
            print_info "使用阿里云镜像源"
            ;;
    esac
    
    # 设置仓库
    print_info "设置 Docker 仓库..."
    sudo yum-config-manager --add-repo $DOCKER_MIRROR/linux/centos/docker-ce.repo
    
    # 安装 Docker
    print_info "安装 Docker Engine..."
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    print_success "Docker 安装完成"
}

# 启动 Docker 服务
start_docker() {
    print_info "启动 Docker 服务..."
    
    sudo systemctl start docker
    sudo systemctl enable docker
    
    print_success "Docker 服务已启动并设置为开机自启"
}

# 配置用户组
configure_docker_group() {
    print_info "配置 Docker 用户组..."
    
    read -p "是否将当前用户添加到 docker 组? (Y/n): " add_group
    add_group=${add_group:-Y}
    
    if [[ $add_group =~ ^[Yy]$ ]]; then
        sudo usermod -aG docker $USER
        print_success "用户 $USER 已添加到 docker 组"
        print_warning "需要重新登录或运行 'newgrp docker' 来应用组权限"
    fi
}

# 配置 Docker 镜像加速
configure_registry_mirrors() {
    print_info "配置 Docker 镜像加速..."
    
    echo ""
    echo "选择镜像加速器:"
    echo "1) 阿里云 (推荐，需要登录获取专属地址)"
    echo "2) 腾讯云"
    echo "3) 网易云"
    echo "4) 中国科技大学"
    echo "5) Docker 官方中国区"
    echo "6) 自定义"
    echo "7) 跳过配置"
    echo ""
    read -p "请选择 [1-7, 默认: 2]: " mirror_choice
    mirror_choice=${mirror_choice:-2}
    
    case $mirror_choice in
        1)
            echo ""
            print_info "阿里云镜像加速器配置:"
            print_info "1. 登录阿里云: https://cr.console.aliyun.com"
            print_info "2. 找到「镜像加速器」页面"
            print_info "3. 复制您的专属加速地址"
            echo ""
            read -p "请输入您的阿里云镜像加速地址: " REGISTRY_MIRROR
            if [[ -z "$REGISTRY_MIRROR" ]]; then
                print_warning "未输入地址，跳过配置"
                return
            fi
            ;;
        2)
            REGISTRY_MIRROR="https://mirror.ccs.tencentyun.com"
            ;;
        3)
            REGISTRY_MIRROR="https://hub-mirror.c.163.com"
            ;;
        4)
            REGISTRY_MIRROR="https://docker.mirrors.ustc.edu.cn"
            ;;
        5)
            REGISTRY_MIRROR="https://registry.docker-cn.com"
            ;;
        6)
            read -p "请输入自定义镜像加速地址: " REGISTRY_MIRROR
            if [[ -z "$REGISTRY_MIRROR" ]]; then
                print_warning "未输入地址，跳过配置"
                return
            fi
            ;;
        7)
            print_info "跳过镜像加速配置"
            return
            ;;
        *)
            print_warning "无效选择，跳过配置"
            return
            ;;
    esac
    
    # 创建配置目录
    sudo mkdir -p /etc/docker
    
    # 读取现有配置或创建新配置
    if [[ -f /etc/docker/daemon.json ]]; then
        print_warning "检测到已有配置文件，将备份到 /etc/docker/daemon.json.bak"
        sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.bak
    fi
    
    # 写入配置
    print_info "写入镜像加速配置..."
    sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "registry-mirrors": ["$REGISTRY_MIRROR"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
    
    print_success "镜像加速配置完成"
    
    # 重启 Docker
    print_info "重启 Docker 服务..."
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    
    print_success "Docker 服务已重启"
}

# 配置 Docker 代理
configure_docker_proxy() {
    print_info "配置 Docker 代理..."
    
    read -p "是否配置 Docker 代理? (y/N): " config_proxy
    if [[ ! $config_proxy =~ ^[Yy]$ ]]; then
        print_info "跳过代理配置"
        return
    fi
    
    echo ""
    print_info "代理配置用于 Docker 守护进程拉取镜像时使用"
    echo ""
    
    read -p "请输入 HTTP 代理地址 (如: http://127.0.0.1:8080): " HTTP_PROXY
    read -p "请输入 HTTPS 代理地址 (如: http://127.0.0.1:8080): " HTTPS_PROXY
    
    if [[ -z "$HTTP_PROXY" && -z "$HTTPS_PROXY" ]]; then
        print_warning "未输入代理地址，跳过配置"
        return
    fi
    
    # 创建 systemd 目录
    sudo mkdir -p /etc/systemd/system/docker.service.d
    
    # 写入代理配置
    sudo tee /etc/systemd/system/docker.service.d/http-proxy.conf > /dev/null <<EOF
[Service]
Environment="HTTP_PROXY=${HTTP_PROXY}"
Environment="HTTPS_PROXY=${HTTPS_PROXY}"
Environment="NO_PROXY=localhost,127.0.0.1,*.local"
EOF
    
    print_success "代理配置完成"
    
    # 重新加载配置
    print_info "重新加载配置..."
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    
    print_success "Docker 服务已重启"
}

# 测试 Docker 安装
test_docker() {
    print_info "测试 Docker 安装..."
    
    # 运行 hello-world
    print_info "运行 hello-world 容器..."
    if sudo docker run --rm hello-world > /dev/null 2>&1; then
        print_success "Docker 测试成功"
    else
        print_warning "Docker 测试失败，但安装可能已完成"
    fi
    
    # 显示 Docker 信息
    echo ""
    print_info "Docker 版本信息:"
    docker --version
    docker compose version
    
    echo ""
    print_info "Docker 系统信息:"
    sudo docker info | grep -E "Server Version|Storage Driver|Logging Driver|Cgroup Driver|Registry Mirrors"
}

# 安装 Docker Compose (独立版本，用于旧系统)
install_docker_compose_standalone() {
    print_info "检查 Docker Compose..."
    
    if docker compose version &> /dev/null; then
        print_success "Docker Compose 插件已安装"
        return
    fi
    
    read -p "是否安装独立版 Docker Compose? (y/N): " install_compose
    if [[ ! $install_compose =~ ^[Yy]$ ]]; then
        return
    fi
    
    print_info "安装独立版 Docker Compose..."
    
    # 获取最新版本
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    
    if [[ -z "$COMPOSE_VERSION" ]]; then
        COMPOSE_VERSION="v2.23.0"
        print_warning "无法获取最新版本，使用默认版本: $COMPOSE_VERSION"
    fi
    
    print_info "下载 Docker Compose $COMPOSE_VERSION..."
    sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose
    
    sudo chmod +x /usr/local/bin/docker-compose
    
    print_success "Docker Compose 安装完成"
    docker-compose --version
}

# 显示使用说明
show_usage() {
    echo ""
    print_success "==================== 安装完成 ===================="
    echo ""
    print_info "🎉 Docker 安装和配置完成！"
    echo ""
    print_info "📚 常用命令:"
    echo "  docker --version              # 查看版本"
    echo "  docker ps                     # 查看运行中的容器"
    echo "  docker images                 # 查看镜像列表"
    echo "  docker pull <image>           # 拉取镜像"
    echo "  docker run <image>            # 运行容器"
    echo "  docker compose up -d          # 启动 Compose 项目"
    echo ""
    print_info "📖 配置文件:"
    echo "  /etc/docker/daemon.json       # Docker 守护进程配置"
    echo "  /etc/systemd/system/docker.service.d/  # Systemd 服务配置"
    echo ""
    print_info "🔧 服务管理:"
    echo "  sudo systemctl start docker   # 启动 Docker"
    echo "  sudo systemctl stop docker    # 停止 Docker"
    echo "  sudo systemctl restart docker # 重启 Docker"
    echo "  sudo systemctl status docker  # 查看状态"
    echo ""
    
    if groups $USER | grep -q docker; then
        print_warning "⚠️  用户组已配置，但需要重新登录才能生效"
        print_info "运行以下命令立即生效: newgrp docker"
    fi
    
    echo ""
    print_success "=================================================="
}

# 主菜单
show_menu() {
    echo ""
    echo "请选择要执行的操作:"
    echo ""
    echo "1) 完整安装 (推荐)"
    echo "   - 安装 Docker"
    echo "   - 配置镜像加速"
    echo "   - 配置用户组"
    echo ""
    echo "2) 仅安装 Docker"
    echo "3) 仅配置镜像加速"
    echo "4) 仅配置代理"
    echo "5) 测试 Docker"
    echo "6) 退出"
    echo ""
}

# 完整安装
full_installation() {
    print_info "开始完整 Docker 安装..."
    
    remove_old_docker
    
    case $OS in
        ubuntu|debian)
            install_docker_ubuntu
            ;;
        centos|rhel|rocky|almalinux)
            install_docker_centos
            ;;
        *)
            print_error "不支持的操作系统: $OS"
            exit 1
            ;;
    esac
    
    start_docker
    configure_docker_group
    configure_registry_mirrors
    configure_docker_proxy
    install_docker_compose_standalone
    test_docker
    show_usage
}

# 主函数
main() {
    print_banner
    
    # 检查是否为 root 或有 sudo 权限
    if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
        print_error "此脚本需要 root 权限或 sudo 权限"
        print_info "请使用: sudo $0"
        exit 1
    fi
    
    detect_os
    
    # 如果提供了 --auto 参数，执行完整安装
    if [[ "$1" == "--auto" ]]; then
        if check_docker_installed; then
            print_warning "Docker 已安装"
            read -p "是否重新安装? (y/N): " reinstall
            if [[ ! $reinstall =~ ^[Yy]$ ]]; then
                print_info "退出脚本"
                exit 0
            fi
        fi
        full_installation
        exit 0
    fi
    
    # 检查 Docker 是否已安装
    check_docker_installed
    
    # 交互式菜单
    while true; do
        show_menu
        read -p "请选择 [1-6]: " choice
        
        case $choice in
            1)
                full_installation
                break
                ;;
            2)
                remove_old_docker
                case $OS in
                    ubuntu|debian)
                        install_docker_ubuntu
                        ;;
                    centos|rhel|rocky|almalinux)
                        install_docker_centos
                        ;;
                esac
                start_docker
                configure_docker_group
                ;;
            3)
                if ! check_docker_installed; then
                    print_error "请先安装 Docker"
                else
                    configure_registry_mirrors
                fi
                ;;
            4)
                if ! check_docker_installed; then
                    print_error "请先安装 Docker"
                else
                    configure_docker_proxy
                fi
                ;;
            5)
                if ! check_docker_installed; then
                    print_error "请先安装 Docker"
                else
                    test_docker
                fi
                ;;
            6)
                print_info "退出脚本"
                exit 0
                ;;
            *)
                print_warning "无效选择，请重新输入"
                ;;
        esac
    done
}

main "$@"
