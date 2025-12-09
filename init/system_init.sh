#!/bin/bash

# Linux 系统初始化脚本 v1.0
# 支持：换国内镜像源、基础工具安装、系统优化

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
    echo "       Linux 系统初始化脚本 v1.0"
    echo "=================================================="
    echo "功能: 镜像源切换 | 基础工具 | 系统优化"
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
    
    # 检测是否为国内环境
    print_info "检测网络环境..."
    if curl -s --connect-timeout 3 www.google.com > /dev/null 2>&1; then
        NETWORK_ENV="international"
        print_info "检测到国际网络环境"
    else
        NETWORK_ENV="china"
        print_info "检测到国内网络环境，建议使用国内镜像源"
    fi
}

# 备份原始源
backup_sources() {
    print_info "备份原始软件源..."
    
    case $OS in
        ubuntu|debian)
            if [[ ! -f /etc/apt/sources.list.bak ]]; then
                sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
                print_success "已备份到 /etc/apt/sources.list.bak"
            else
                print_warning "备份文件已存在，跳过备份"
            fi
            ;;
        centos|rhel|rocky|almalinux)
            if [[ ! -d /etc/yum.repos.d/backup ]]; then
                sudo mkdir -p /etc/yum.repos.d/backup
                sudo cp /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup/
                print_success "已备份到 /etc/yum.repos.d/backup/"
            else
                print_warning "备份目录已存在，跳过备份"
            fi
            ;;
    esac
}

# 配置 Ubuntu/Debian 镜像源
configure_ubuntu_mirrors() {
    print_info "配置 Ubuntu/Debian 镜像源..."
    
    # 检测 Ubuntu 版本代号
    UBUNTU_CODENAME=$(lsb_release -cs 2>/dev/null || echo "jammy")
    
    # 选择镜像源
    echo ""
    echo "请选择镜像源:"
    echo "1) 阿里云 (推荐)"
    echo "2) 清华大学"
    echo "3) 中国科技大学"
    echo "4) 华为云"
    echo "5) 网易"
    echo "6) 保持原有配置"
    echo ""
    
    read -p "请选择 [1-6, 默认: 1]: " mirror_choice
    mirror_choice=${mirror_choice:-1}
    
    case $mirror_choice in
        1)
            MIRROR_URL="http://mirrors.aliyun.com"
            MIRROR_NAME="阿里云"
            ;;
        2)
            MIRROR_URL="https://mirrors.tuna.tsinghua.edu.cn"
            MIRROR_NAME="清华大学"
            ;;
        3)
            MIRROR_URL="https://mirrors.ustc.edu.cn"
            MIRROR_NAME="中国科技大学"
            ;;
        4)
            MIRROR_URL="https://repo.huaweicloud.com"
            MIRROR_NAME="华为云"
            ;;
        5)
            MIRROR_URL="http://mirrors.163.com"
            MIRROR_NAME="网易"
            ;;
        6)
            print_info "保持原有配置"
            return
            ;;
        *)
            print_warning "无效选择，使用阿里云镜像"
            MIRROR_URL="http://mirrors.aliyun.com"
            MIRROR_NAME="阿里云"
            ;;
    esac
    
    print_info "正在配置 $MIRROR_NAME 镜像源..."
    
    # 生成新的 sources.list
    sudo tee /etc/apt/sources.list > /dev/null <<EOF
# $MIRROR_NAME 镜像源
deb $MIRROR_URL/ubuntu/ $UBUNTU_CODENAME main restricted universe multiverse
deb $MIRROR_URL/ubuntu/ $UBUNTU_CODENAME-updates main restricted universe multiverse
deb $MIRROR_URL/ubuntu/ $UBUNTU_CODENAME-backports main restricted universe multiverse
deb $MIRROR_URL/ubuntu/ $UBUNTU_CODENAME-security main restricted universe multiverse
EOF
    
    print_success "$MIRROR_NAME 镜像源配置完成"
    
    # 更新软件包索引
    print_info "更新软件包索引..."
    sudo apt-get update
    print_success "软件包索引更新完成"
}

# 配置 CentOS/RHEL 镜像源
configure_centos_mirrors() {
    print_info "配置 CentOS/RHEL 镜像源..."
    
    echo ""
    echo "请选择镜像源:"
    echo "1) 阿里云 (推荐)"
    echo "2) 清华大学"
    echo "3) 中国科技大学"
    echo "4) 华为云"
    echo "5) 保持原有配置"
    echo ""
    
    read -p "请选择 [1-5, 默认: 1]: " mirror_choice
    mirror_choice=${mirror_choice:-1}
    
    case $mirror_choice in
        1)
            MIRROR_URL="https://mirrors.aliyun.com"
            MIRROR_NAME="阿里云"
            ;;
        2)
            MIRROR_URL="https://mirrors.tuna.tsinghua.edu.cn"
            MIRROR_NAME="清华大学"
            ;;
        3)
            MIRROR_URL="https://mirrors.ustc.edu.cn"
            MIRROR_NAME="中国科技大学"
            ;;
        4)
            MIRROR_URL="https://repo.huaweicloud.com"
            MIRROR_NAME="华为云"
            ;;
        5)
            print_info "保持原有配置"
            return
            ;;
        *)
            print_warning "无效选择，使用阿里云镜像"
            MIRROR_URL="https://mirrors.aliyun.com"
            MIRROR_NAME="阿里云"
            ;;
    esac
    
    print_info "正在配置 $MIRROR_NAME 镜像源..."
    
    # 根据版本配置
    if [[ "$OS" == "centos" ]]; then
        if [[ "$OS_VERSION" == "7" ]]; then
            sudo sed -e "s|^mirrorlist=|#mirrorlist=|g" \
                     -e "s|^#baseurl=http://mirror.centos.org|baseurl=$MIRROR_URL|g" \
                     -i.bak /etc/yum.repos.d/CentOS-*.repo
        elif [[ "$OS_VERSION" == "8" ]]; then
            sudo sed -e "s|^mirrorlist=|#mirrorlist=|g" \
                     -e "s|^#baseurl=http://mirror.centos.org|baseurl=$MIRROR_URL|g" \
                     -i.bak /etc/yum.repos.d/CentOS-*.repo
        fi
    fi
    
    print_success "$MIRROR_NAME 镜像源配置完成"
    
    # 清理缓存并更新
    print_info "清理缓存并更新..."
    sudo yum clean all
    sudo yum makecache
    print_success "缓存更新完成"
}

# 安装基础工具
install_basic_tools() {
    print_info "安装基础工具..."
    
    echo ""
    echo "将安装以下基础工具:"
    echo "  - curl, wget: 文件下载工具"
    echo "  - git: 版本控制工具"
    echo "  - vim/nano: 文本编辑器"
    echo "  - htop: 系统监控工具"
    echo "  - net-tools: 网络工具"
    echo "  - unzip, tar: 压缩工具"
    echo ""
    
    read -p "是否安装基础工具? (Y/n): " install_tools
    install_tools=${install_tools:-Y}
    
    if [[ ! $install_tools =~ ^[Yy]$ ]]; then
        print_info "跳过基础工具安装"
        return
    fi
    
    case $OS in
        ubuntu|debian)
            sudo apt-get install -y \
                curl wget git vim nano \
                htop net-tools \
                unzip tar gzip \
                build-essential \
                software-properties-common
            ;;
        centos|rhel|rocky|almalinux)
            sudo yum install -y \
                curl wget git vim nano \
                htop net-tools \
                unzip tar gzip \
                gcc gcc-c++ make \
                epel-release
            ;;
    esac
    
    print_success "基础工具安装完成"
}

# 配置 SSH
configure_ssh() {
    print_info "配置 SSH 服务..."
    
    read -p "是否优化 SSH 配置? (y/N): " config_ssh
    if [[ ! $config_ssh =~ ^[Yy]$ ]]; then
        print_info "跳过 SSH 配置"
        return
    fi
    
    # 备份 SSH 配置
    if [[ ! -f /etc/ssh/sshd_config.bak ]]; then
        sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
        print_success "已备份 SSH 配置"
    fi
    
    # 优化配置
    print_info "应用 SSH 优化配置..."
    
    # 禁用 DNS 解析加速连接
    sudo sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
    sudo sed -i 's/UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
    
    # 关闭 GSSAPI 认证加速连接
    sudo sed -i 's/GSSAPIAuthentication yes/GSSAPIAuthentication no/' /etc/ssh/sshd_config
    
    # 增加连接保活
    if ! grep -q "ClientAliveInterval" /etc/ssh/sshd_config; then
        echo "ClientAliveInterval 60" | sudo tee -a /etc/ssh/sshd_config
        echo "ClientAliveCountMax 3" | sudo tee -a /etc/ssh/sshd_config
    fi
    
    # 重启 SSH 服务
    print_info "重启 SSH 服务..."
    if command -v systemctl &> /dev/null; then
        sudo systemctl restart sshd || sudo systemctl restart ssh
    else
        sudo service sshd restart || sudo service ssh restart
    fi
    
    print_success "SSH 配置优化完成"
}

# 配置时区
configure_timezone() {
    print_info "配置时区..."
    
    CURRENT_TZ=$(timedatectl 2>/dev/null | grep "Time zone" | awk '{print $3}')
    print_info "当前时区: $CURRENT_TZ"
    
    read -p "是否设置为中国时区 (Asia/Shanghai)? (Y/n): " set_tz
    set_tz=${set_tz:-Y}
    
    if [[ $set_tz =~ ^[Yy]$ ]]; then
        sudo timedatectl set-timezone Asia/Shanghai
        print_success "时区已设置为 Asia/Shanghai"
    fi
}

# 配置语言环境
configure_locale() {
    print_info "配置语言环境..."
    
    read -p "是否配置中文语言环境? (y/N): " set_locale
    if [[ ! $set_locale =~ ^[Yy]$ ]]; then
        print_info "跳过语言环境配置"
        return
    fi
    
    case $OS in
        ubuntu|debian)
            sudo apt-get install -y language-pack-zh-hans
            sudo locale-gen zh_CN.UTF-8
            ;;
        centos|rhel|rocky|almalinux)
            sudo yum install -y glibc-langpack-zh
            ;;
    esac
    
    print_success "中文语言环境配置完成"
}

# 系统优化
optimize_system() {
    print_info "系统优化配置..."
    
    read -p "是否应用系统优化配置? (y/N): " do_optimize
    if [[ ! $do_optimize =~ ^[Yy]$ ]]; then
        print_info "跳过系统优化"
        return
    fi
    
    # 优化文件描述符限制
    print_info "优化文件描述符限制..."
    if ! grep -q "^* soft nofile 65535" /etc/security/limits.conf; then
        echo "* soft nofile 65535" | sudo tee -a /etc/security/limits.conf
        echo "* hard nofile 65535" | sudo tee -a /etc/security/limits.conf
        print_success "文件描述符限制已优化"
    else
        print_info "文件描述符限制已经配置"
    fi
    
    # 优化内核参数
    print_info "优化内核参数..."
    sudo tee /etc/sysctl.d/99-custom.conf > /dev/null <<EOF
# 网络优化
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# 连接优化
net.ipv4.tcp_max_syn_backlog = 8192
net.core.somaxconn = 8192
net.ipv4.tcp_slow_start_after_idle = 0

# TIME_WAIT 优化
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_reuse = 1

# 文件系统优化
fs.file-max = 1000000
fs.inotify.max_user_watches = 524288
EOF
    
    sudo sysctl -p /etc/sysctl.d/99-custom.conf > /dev/null 2>&1
    print_success "内核参数优化完成"
}

# 清理系统
clean_system() {
    print_info "清理系统..."
    
    read -p "是否清理系统缓存和无用包? (y/N): " do_clean
    if [[ ! $do_clean =~ ^[Yy]$ ]]; then
        print_info "跳过系统清理"
        return
    fi
    
    case $OS in
        ubuntu|debian)
            sudo apt-get autoremove -y
            sudo apt-get autoclean -y
            ;;
        centos|rhel|rocky|almalinux)
            sudo yum autoremove -y
            sudo yum clean all
            ;;
    esac
    
    print_success "系统清理完成"
}

# 显示系统信息
show_system_info() {
    echo ""
    print_success "==================== 系统信息 ===================="
    echo ""
    echo "操作系统: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "内核版本: $(uname -r)"
    echo "系统架构: $(uname -m)"
    echo "CPU 核心: $(nproc)"
    echo "内存大小: $(free -h | awk '/^Mem:/ {print $2}')"
    echo "磁盘空间: $(df -h / | awk 'NR==2 {print $2}')"
    echo "当前用户: $(whoami)"
    echo "主机名称: $(hostname)"
    echo "时区设置: $(timedatectl 2>/dev/null | grep "Time zone" | awk '{print $3}' || echo 'N/A')"
    echo ""
    print_success "=================================================="
}

# 主菜单
show_menu() {
    echo ""
    echo "请选择要执行的操作:"
    echo ""
    echo "1) 完整初始化 (推荐)"
    echo "   - 更换镜像源"
    echo "   - 安装基础工具"
    echo "   - 系统优化"
    echo "   - SSH 配置"
    echo ""
    echo "2) 仅更换镜像源"
    echo "3) 仅安装基础工具"
    echo "4) 仅系统优化"
    echo "5) 显示系统信息"
    echo "6) 退出"
    echo ""
}

# 完整初始化
full_initialization() {
    print_info "开始完整系统初始化..."
    
    backup_sources
    
    case $OS in
        ubuntu|debian)
            configure_ubuntu_mirrors
            ;;
        centos|rhel|rocky|almalinux)
            configure_centos_mirrors
            ;;
        *)
            print_warning "暂不支持该系统的镜像源配置"
            ;;
    esac
    
    install_basic_tools
    configure_timezone
    configure_locale
    configure_ssh
    optimize_system
    clean_system
    
    print_success "系统初始化完成！"
    show_system_info
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
    
    # 如果提供了 --auto 参数，执行完整初始化
    if [[ "$1" == "--auto" ]]; then
        full_initialization
        exit 0
    fi
    
    # 交互式菜单
    while true; do
        show_menu
        read -p "请选择 [1-6]: " choice
        
        case $choice in
            1)
                full_initialization
                break
                ;;
            2)
                backup_sources
                case $OS in
                    ubuntu|debian)
                        configure_ubuntu_mirrors
                        ;;
                    centos|rhel|rocky|almalinux)
                        configure_centos_mirrors
                        ;;
                esac
                ;;
            3)
                install_basic_tools
                ;;
            4)
                optimize_system
                ;;
            5)
                show_system_info
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
