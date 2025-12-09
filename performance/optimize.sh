#!/bin/bash

# Linux 性能优化脚本 v1.0
# 包含：内核参数优化、网络优化、磁盘优化等

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
    echo "       Linux 性能优化脚本 v1.0"
    echo "=================================================="
    echo "功能: 内核优化 | 网络优化 | 磁盘优化"
    echo "=================================================="
    echo -e "${NC}"
}

# 检测系统信息
detect_system() {
    print_info "检测系统信息..."
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
        print_success "操作系统: $NAME $VERSION"
    fi
    
    # CPU 信息
    CPU_CORES=$(nproc)
    CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
    print_info "CPU: $CPU_MODEL"
    print_info "CPU 核心数: $CPU_CORES"
    
    # 内存信息
    TOTAL_MEM=$(free -h | awk '/^Mem:/ {print $2}')
    print_info "总内存: $TOTAL_MEM"
    
    # 磁盘信息
    ROOT_DISK=$(df -h / | awk 'NR==2 {print $2}')
    print_info "根分区大小: $ROOT_DISK"
}

# 备份当前配置
backup_configs() {
    print_info "备份当前配置..."
    
    BACKUP_DIR="/root/performance_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # 备份 sysctl 配置
    if [[ -f /etc/sysctl.conf ]]; then
        cp /etc/sysctl.conf "$BACKUP_DIR/sysctl.conf.bak"
    fi
    
    # 备份 limits 配置
    if [[ -f /etc/security/limits.conf ]]; then
        cp /etc/security/limits.conf "$BACKUP_DIR/limits.conf.bak"
    fi
    
    print_success "配置已备份到: $BACKUP_DIR"
}

# 优化内核参数
optimize_kernel() {
    print_info "优化内核参数..."
    
    CURRENT_DATE=$(date)
    cat > /tmp/99-performance.conf <<EOF
# ===============================================
# Linux 性能优化配置
# 生成时间: $CURRENT_DATE
# ===============================================

# ===============================================
# 网络性能优化
# ===============================================

# TCP 缓冲区大小优化
# 增加 TCP 接收和发送缓冲区大小，提升网络吞吐量
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_default = 262144
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# 连接队列优化
# 增加连接队列大小，提升并发连接处理能力
net.core.somaxconn = 8192
net.ipv4.tcp_max_syn_backlog = 8192
net.core.netdev_max_backlog = 16384

# TCP 连接优化
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15

# TIME_WAIT 优化
# 允许重用 TIME_WAIT 状态的连接，减少端口占用
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_tw_buckets = 5000

# TCP Fast Open
# 启用 TCP Fast Open，减少连接建立时间
net.ipv4.tcp_fastopen = 3

# TCP 拥塞控制算法
# 使用 BBR 算法（如果内核支持）
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# ===============================================
# 文件系统优化
# ===============================================

# 文件描述符限制
fs.file-max = 2097152
fs.nr_open = 2097152

# inotify 限制（用于文件监控）
fs.inotify.max_user_instances = 8192
fs.inotify.max_user_watches = 524288

# 管道优化
fs.pipe-max-size = 1048576

# ===============================================
# 内存管理优化
# ===============================================

# 虚拟内存优化
# 减少 swap 使用，提升性能
vm.swappiness = 10

# 脏页写回优化
# 控制脏页写回磁盘的时机
vm.dirty_ratio = 20
vm.dirty_background_ratio = 10
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 500

# 内存分配优化
vm.overcommit_memory = 1
vm.min_free_kbytes = 65536

# ===============================================
# 进程优化
# ===============================================

# 最大进程数
kernel.pid_max = 4194304

# 线程数限制
kernel.threads-max = 2097152

# ===============================================
# 安全优化
# ===============================================

# SYN Cookies 防护
net.ipv4.tcp_syncookies = 1

# IP 转发（根据需要启用）
# net.ipv4.ip_forward = 1

# 防止 SYN Flood 攻击
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2

# ===============================================
# 其他优化
# ===============================================

# 本地端口范围
net.ipv4.ip_local_port_range = 10000 65535

# ARP 缓存
net.ipv4.neigh.default.gc_thresh1 = 1024
net.ipv4.neigh.default.gc_thresh2 = 4096
net.ipv4.neigh.default.gc_thresh3 = 8192
EOF
    
    # 应用配置
    sudo cp /tmp/99-performance.conf /etc/sysctl.d/99-performance.conf
    
    print_success "内核参数配置已写入"
    
    # 应用配置
    print_info "应用内核参数..."
    if sudo sysctl -p /etc/sysctl.d/99-performance.conf > /dev/null 2>&1; then
        print_success "内核参数已应用"
    else
        print_warning "部分参数应用失败（可能是内核版本不支持）"
    fi
}

# 优化文件描述符限制
optimize_limits() {
    print_info "优化文件描述符限制..."
    
    # 备份原文件
    if [[ ! -f /etc/security/limits.conf.bak ]]; then
        sudo cp /etc/security/limits.conf /etc/security/limits.conf.bak
    fi
    
    # 添加配置
    if ! grep -q "# Performance Optimization" /etc/security/limits.conf; then
        cat >> /tmp/limits_append.conf <<'EOF'

# Performance Optimization - Added by optimize.sh
* soft nofile 1048576
* hard nofile 1048576
* soft nproc 65535
* hard nproc 65535
* soft memlock unlimited
* hard memlock unlimited
EOF
        sudo tee -a /etc/security/limits.conf < /tmp/limits_append.conf > /dev/null
        print_success "文件描述符限制已优化"
    else
        print_info "文件描述符限制已经配置"
    fi
}

# 优化磁盘 I/O
optimize_disk_io() {
    print_info "优化磁盘 I/O..."
    
    read -p "是否优化磁盘 I/O? (y/N): " optimize_io
    if [[ ! $optimize_io =~ ^[Yy]$ ]]; then
        print_info "跳过磁盘 I/O 优化"
        return
    fi
    
    # 检查磁盘调度器
    print_info "当前磁盘调度器:"
    for disk in /sys/block/sd*/queue/scheduler; do
        if [[ -f "$disk" ]]; then
            device=$(echo "$disk" | cut -d'/' -f4)
            scheduler=$(cat "$disk" | grep -oP '\[\K[^\]]+')
            echo "  $device: $scheduler"
        fi
    done
    
    echo ""
    print_info "推荐的磁盘调度器:"
    echo "  - SSD: none 或 mq-deadline"
    echo "  - HDD: mq-deadline 或 bfq"
    echo ""
    
    read -p "是否设置 SSD 调度器为 none? (y/N): " set_ssd
    if [[ $set_ssd =~ ^[Yy]$ ]]; then
        for disk in /sys/block/sd*/queue/scheduler; do
            if [[ -f "$disk" ]]; then
                echo "none" | sudo tee "$disk" > /dev/null 2>&1 || true
            fi
        done
        print_success "SSD 调度器已设置为 none"
    fi
}

# 优化系统服务
optimize_services() {
    print_info "优化系统服务..."
    
    read -p "是否禁用不必要的系统服务? (y/N): " disable_services
    if [[ ! $disable_services =~ ^[Yy]$ ]]; then
        print_info "跳过服务优化"
        return
    fi
    
    # 列出可以禁用的服务（谨慎操作）
    OPTIONAL_SERVICES=(
        "bluetooth.service"
        "cups.service"
        "avahi-daemon.service"
    )
    
    print_info "可选禁用的服务:"
    for service in "${OPTIONAL_SERVICES[@]}"; do
        if systemctl is-enabled "$service" &> /dev/null; then
            echo "  - $service (已启用)"
        fi
    done
    
    echo ""
    print_warning "禁用服务可能影响系统功能，请谨慎操作"
    read -p "是否继续? (y/N): " continue_disable
    
    if [[ $continue_disable =~ ^[Yy]$ ]]; then
        for service in "${OPTIONAL_SERVICES[@]}"; do
            if systemctl is-enabled "$service" &> /dev/null; then
                sudo systemctl stop "$service" 2>/dev/null || true
                sudo systemctl disable "$service" 2>/dev/null || true
                print_success "已禁用: $service"
            fi
        done
    fi
}

# 配置 CPU 调度器
optimize_cpu() {
    print_info "配置 CPU 调度器..."
    
    read -p "是否配置 CPU 性能模式? (y/N): " config_cpu
    if [[ ! $config_cpu =~ ^[Yy]$ ]]; then
        print_info "跳过 CPU 优化"
        return
    fi
    
    # 检查是否支持 cpupower
    if ! command -v cpupower &> /dev/null; then
        print_warning "未安装 cpupower 工具"
        case $OS in
            ubuntu|debian)
                read -p "是否安装 cpupower? (y/N): " install_cpu
                if [[ $install_cpu =~ ^[Yy]$ ]]; then
                    sudo apt-get install -y linux-tools-$(uname -r) || sudo apt-get install -y linux-tools-generic
                fi
                ;;
            centos|rhel|rocky|almalinux)
                read -p "是否安装 cpupower? (y/N): " install_cpu
                if [[ $install_cpu =~ ^[Yy]$ ]]; then
                    sudo yum install -y kernel-tools
                fi
                ;;
        esac
    fi
    
    if command -v cpupower &> /dev/null; then
        # 设置性能模式
        print_info "当前 CPU 频率调节器:"
        cpupower frequency-info | grep "governor" || true
        
        echo ""
        read -p "是否设置为性能模式? (y/N): " set_performance
        if [[ $set_performance =~ ^[Yy]$ ]]; then
            sudo cpupower frequency-set -g performance
            print_success "CPU 频率调节器已设置为性能模式"
        fi
    fi
}

# 优化网络接口
optimize_network_interface() {
    print_info "优化网络接口..."
    
    read -p "是否优化网络接口参数? (y/N): " optimize_nic
    if [[ ! $optimize_nic =~ ^[Yy]$ ]]; then
        print_info "跳过网络接口优化"
        return
    fi
    
    # 列出网络接口
    print_info "可用的网络接口:"
    ip link show | grep -E "^[0-9]+:" | awk '{print $2}' | sed 's/:$//'
    
    echo ""
    read -p "请输入要优化的网络接口 (如 eth0): " NIC
    
    if [[ -z "$NIC" ]]; then
        print_warning "未输入接口名，跳过优化"
        return
    fi
    
    # 增加网络接口缓冲区
    print_info "优化网络接口 $NIC..."
    sudo ethtool -G "$NIC" rx 4096 tx 4096 2>/dev/null || print_warning "无法设置缓冲区大小"
    
    # 启用 offload 特性
    sudo ethtool -K "$NIC" tso on gso on gro on 2>/dev/null || print_warning "无法启用 offload 特性"
    
    print_success "网络接口优化完成"
}

# 清理系统
clean_system() {
    print_info "清理系统..."
    
    read -p "是否清理系统缓存? (y/N): " do_clean
    if [[ ! $do_clean =~ ^[Yy]$ ]]; then
        print_info "跳过系统清理"
        return
    fi
    
    # 清理包管理器缓存
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
    
    # 清理日志
    print_info "清理旧日志..."
    sudo journalctl --vacuum-time=7d
    
    # 清理临时文件
    print_info "清理临时文件..."
    sudo rm -rf /tmp/* 2>/dev/null || true
    
    print_success "系统清理完成"
}

# 显示当前系统参数
show_current_params() {
    echo ""
    print_info "==================== 当前系统参数 ===================="
    echo ""
    
    echo "网络参数:"
    echo "  TCP 接收缓冲区: $(sysctl net.ipv4.tcp_rmem 2>/dev/null | cut -d'=' -f2)"
    echo "  TCP 发送缓冲区: $(sysctl net.ipv4.tcp_wmem 2>/dev/null | cut -d'=' -f2)"
    echo "  最大连接队列: $(sysctl net.core.somaxconn 2>/dev/null | cut -d'=' -f2)"
    echo "  TCP 拥塞控制: $(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | cut -d'=' -f2)"
    
    echo ""
    echo "文件系统参数:"
    echo "  最大文件描述符: $(sysctl fs.file-max 2>/dev/null | cut -d'=' -f2)"
    echo "  inotify watches: $(sysctl fs.inotify.max_user_watches 2>/dev/null | cut -d'=' -f2)"
    
    echo ""
    echo "内存参数:"
    echo "  Swappiness: $(sysctl vm.swappiness 2>/dev/null | cut -d'=' -f2)"
    echo "  脏页比例: $(sysctl vm.dirty_ratio 2>/dev/null | cut -d'=' -f2)"
    
    echo ""
    echo "进程限制:"
    echo "  最大进程ID: $(sysctl kernel.pid_max 2>/dev/null | cut -d'=' -f2)"
    
    echo ""
    print_success "===================================================="
}

# 性能测试
run_performance_test() {
    print_info "运行性能测试..."
    
    read -p "是否运行网络性能测试? (需要安装 iperf3) (y/N): " run_net_test
    if [[ $run_net_test =~ ^[Yy]$ ]]; then
        if ! command -v iperf3 &> /dev/null; then
            print_warning "未安装 iperf3"
            read -p "是否安装? (y/N): " install_iperf
            if [[ $install_iperf =~ ^[Yy]$ ]]; then
                case $OS in
                    ubuntu|debian)
                        sudo apt-get install -y iperf3
                        ;;
                    centos|rhel|rocky|almalinux)
                        sudo yum install -y iperf3
                        ;;
                esac
            fi
        fi
    fi
    
    read -p "是否运行磁盘性能测试? (y/N): " run_disk_test
    if [[ $run_disk_test =~ ^[Yy]$ ]]; then
        print_info "运行磁盘写入测试..."
        dd if=/dev/zero of=/tmp/test_disk bs=1M count=1024 conv=fdatasync 2>&1 | grep -E "copied|MB/s"
        rm -f /tmp/test_disk
    fi
}

# 显示使用说明
show_usage() {
    echo ""
    print_success "==================== 优化完成 ===================="
    echo ""
    print_info "🎉 系统性能优化完成！"
    echo ""
    print_info "📖 配置文件:"
    echo "  /etc/sysctl.d/99-performance.conf    # 内核参数配置"
    echo "  /etc/security/limits.conf            # 资源限制配置"
    echo ""
    print_info "🔧 使配置生效:"
    echo "  sudo sysctl -p /etc/sysctl.d/99-performance.conf  # 应用内核参数"
    echo "  重新登录或重启系统                                # 应用资源限制"
    echo ""
    print_info "📊 查看参数:"
    echo "  sysctl -a | grep <参数名>            # 查看内核参数"
    echo "  ulimit -a                            # 查看资源限制"
    echo ""
    print_warning "⚠️  建议重启系统以确保所有优化生效"
    echo ""
    print_success "===================================================="
}

# 主菜单
show_menu() {
    echo ""
    echo "请选择要执行的操作:"
    echo ""
    echo "1) 完整优化 (推荐)"
    echo "   - 内核参数优化"
    echo "   - 文件描述符优化"
    echo "   - 磁盘 I/O 优化"
    echo ""
    echo "2) 仅优化内核参数"
    echo "3) 仅优化文件描述符"
    echo "4) 仅优化磁盘 I/O"
    echo "5) 优化 CPU 性能"
    echo "6) 优化网络接口"
    echo "7) 显示当前参数"
    echo "8) 性能测试"
    echo "9) 退出"
    echo ""
}

# 完整优化
full_optimization() {
    print_info "开始完整系统优化..."
    
    backup_configs
    optimize_kernel
    optimize_limits
    optimize_disk_io
    optimize_cpu
    optimize_network_interface
    clean_system
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
    
    detect_system
    
    # 如果提供了 --auto 参数，执行完整优化
    if [[ "$1" == "--auto" ]]; then
        full_optimization
        exit 0
    fi
    
    # 交互式菜单
    while true; do
        show_menu
        read -p "请选择 [1-9]: " choice
        
        case $choice in
            1)
                full_optimization
                break
                ;;
            2)
                backup_configs
                optimize_kernel
                ;;
            3)
                backup_configs
                optimize_limits
                ;;
            4)
                optimize_disk_io
                ;;
            5)
                optimize_cpu
                ;;
            6)
                optimize_network_interface
                ;;
            7)
                show_current_params
                ;;
            8)
                run_performance_test
                ;;
            9)
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
