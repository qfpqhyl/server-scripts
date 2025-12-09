#!/bin/bash

# V2Ray WSL 安装脚本 v1.0
# 支持VMess、VLESS、Shadowsocks协议
# 适用于WSL (Windows Subsystem for Linux)

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 打印带颜色的消息
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

print_menu() {
    echo -e "${CYAN}[MENU]${NC} $1"
}

print_banner() {
    echo -e "${PURPLE}"
    echo "=================================================="
    echo "      V2Ray WSL 安装脚本 v1.0"
    echo "=================================================="
    echo "支持协议: VMess | VLESS | Shadowsocks"
    echo "适用环境: WSL (Windows Subsystem for Linux)"
    echo "=================================================="
    echo -e "${NC}"
}

# 检查是否在WSL环境中
check_wsl_environment() {
    print_info "检查WSL环境..."
    
    if ! grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
        print_warning "未检测到WSL环境，此脚本专为WSL设计"
        read -p "是否继续安装? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    print_success "WSL环境检查通过"
}

# 检查命令是否存在
check_command() {
    if ! command -v $1 >/dev/null 2>&1; then
        print_error "命令 $1 未找到"
        return 1
    fi
    return 0
}

# 检查系统环境
check_environment() {
    print_info "检查系统环境..."
    
    # 检查操作系统
    if [[ ! -f /etc/os-release ]]; then
        print_error "无法确定操作系统类型"
        exit 1
    fi
    
    # 检查架构
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            V2RAY_ARCH="64"
            ;;
        i386|i686)
            V2RAY_ARCH="32"
            ;;
        armv7l)
            V2RAY_ARCH="arm32-v7a"
            ;;
        aarch64)
            V2RAY_ARCH="arm64-v8a"
            ;;
        *)
            print_error "不支持的系统架构: $ARCH"
            exit 1
            ;;
    esac
    
    print_success "系统架构: $ARCH (V2Ray: $V2RAY_ARCH)"
    
    # 检查必要命令
    local missing_commands=()
    for cmd in curl wget unzip python3; do
        if ! check_command $cmd; then
            missing_commands+=($cmd)
        fi
    done
    
    if [ ${#missing_commands[@]} -ne 0 ]; then
        print_warning "缺少必要命令: ${missing_commands[*]}"
        print_info "尝试安装缺失的工具..."
        sudo apt-get update
        sudo apt-get install -y curl wget unzip python3
    fi
    
    print_success "环境检查通过"
}

# 获取订阅链接
get_subscription_url() {
    echo ""
    print_info "请输入你的V2Ray订阅链接"
    print_warning "订阅链接格式通常为: https://domain.com/link/xxxxx"
    echo ""

    while true; do
        read -p "请输入订阅链接: " SUBSCRIPTION_URL

        if [[ -z "$SUBSCRIPTION_URL" ]]; then
            print_warning "订阅链接不能为空，请重新输入"
            continue
        fi

        if [[ ! "$SUBSCRIPTION_URL" =~ ^https?:// ]]; then
            print_warning "订阅链接格式不正确，应以 http:// 或 https:// 开头"
            continue
        fi

        # 测试订阅链接
        print_info "测试订阅链接..."
        if curl -L -s --max-time 10 "$SUBSCRIPTION_URL" >/dev/null 2>&1; then
            print_success "订阅链接测试成功"
            break
        else
            print_warning "无法访问订阅链接，请检查链接是否正确"
            read -p "是否继续使用此链接? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                break
            fi
        fi
    done

    # 保存订阅链接
    echo "$SUBSCRIPTION_URL" > subscription_url.txt
    print_success "订阅链接已保存"
}

# 选择代理模式
select_proxy_mode() {
    echo ""
    print_menu "选择代理模式"
    echo ""
    echo "1) 本机代理 (仅WSL内使用)"
    echo "   - SOCKS5: 127.0.0.1:[自定义端口]"
    echo "   - HTTP:   127.0.0.1:[自定义端口]"
    echo ""
    echo "2) Windows共享 (WSL + Windows 系统使用)"
    echo "   - SOCKS5: 0.0.0.0:[自定义端口]"
    echo "   - HTTP:   0.0.0.0:[自定义端口]"
    echo "   - Windows可通过WSL IP访问"
    echo ""

    while true; do
        read -p "请选择代理模式 (1-2) [默认: 2]: " PROXY_MODE_CHOICE

        if [[ -z "$PROXY_MODE_CHOICE" ]]; then
            PROXY_MODE_CHOICE="2"
        fi

        case $PROXY_MODE_CHOICE in
            1)
                PROXY_MODE="local"
                LISTEN_IP="127.0.0.1"
                print_success "已选择: 本机代理模式"
                break
                ;;
            2)
                PROXY_MODE="windows"
                LISTEN_IP="0.0.0.0"
                print_success "已选择: Windows共享模式"
                break
                ;;
            *)
                print_warning "无效选择，请输入 1 或 2"
                ;;
        esac
    done

    # 初始化默认端口
    SOCKS5_PORT="1080"
    HTTP_PORT="8080"

    # 设置端口配置
    setup_port_config

    # 保存代理模式配置
    save_proxy_config
}

# 设置端口配置
setup_port_config() {
    echo ""
    print_info "配置代理端口"
    print_warning "请确保端口未被占用，推荐使用1024以上的端口"
    echo ""

    # 设置SOCKS5端口
    while true; do
        read -p "请输入SOCKS5代理端口 [默认: 1080]: " SOCKS5_PORT_INPUT
        if [[ -z "$SOCKS5_PORT_INPUT" ]]; then
            SOCKS5_PORT="1080"
        else
            if [[ ! "$SOCKS5_PORT_INPUT" =~ ^[0-9]+$ ]]; then
                print_warning "端口必须是数字"
                continue
            fi
            if [[ "$SOCKS5_PORT_INPUT" -lt 1 || "$SOCKS5_PORT_INPUT" -gt 65535 ]]; then
                print_warning "端口范围必须在1-65535之间"
                continue
            fi
            SOCKS5_PORT="$SOCKS5_PORT_INPUT"
        fi
        break
    done

    # 设置HTTP端口
    while true; do
        read -p "请输入HTTP代理端口 [默认: 8080]: " HTTP_PORT_INPUT
        if [[ -z "$HTTP_PORT_INPUT" ]]; then
            HTTP_PORT="8080"
        else
            if [[ ! "$HTTP_PORT_INPUT" =~ ^[0-9]+$ ]]; then
                print_warning "端口必须是数字"
                continue
            fi
            if [[ "$HTTP_PORT_INPUT" -lt 1 || "$HTTP_PORT_INPUT" -gt 65535 ]]; then
                print_warning "端口范围必须在1-65535之间"
                continue
            fi
            if [[ "$HTTP_PORT_INPUT" == "$SOCKS5_PORT" ]]; then
                print_warning "HTTP端口不能与SOCKS5端口相同"
                continue
            fi
            HTTP_PORT="$HTTP_PORT_INPUT"
        fi
        break
    done

    print_success "端口配置完成"
    print_info "SOCKS5端口: $SOCKS5_PORT"
    print_info "HTTP端口: $HTTP_PORT"
}

# 保存代理模式配置
save_proxy_config() {
    CONFIG_CONTENT="PROXY_MODE=$PROXY_MODE
LISTEN_IP=$LISTEN_IP
SOCKS5_PORT=$SOCKS5_PORT
HTTP_PORT=$HTTP_PORT"

    echo "$CONFIG_CONTENT" > proxy_config.txt
    
    if [[ -n "$V2RAY_DIR" ]]; then
        echo "$CONFIG_CONTENT" > "$V2RAY_DIR/proxy_config.txt" 2>/dev/null || true
    fi
}

# 创建安装目录
create_directories() {
    print_info "创建安装目录..."

    V2RAY_DIR="$HOME/v2ray"

    if [[ -d "$V2RAY_DIR" ]]; then
        print_warning "目录 $V2RAY_DIR 已存在"
        read -p "是否删除现有目录并重新安装? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if [[ -f "$V2RAY_DIR/stop.sh" ]]; then
                print_info "停止现有V2Ray服务..."
                cd "$V2RAY_DIR" && ./stop.sh >/dev/null 2>&1 || true
            fi
            rm -rf "$V2RAY_DIR"
            print_success "已删除现有目录"
        else
            print_error "安装已取消"
            exit 1
        fi
    fi

    mkdir -p "$V2RAY_DIR"

    if [[ -f "proxy_config.txt" ]]; then
        cp proxy_config.txt "$V2RAY_DIR/"
        print_success "已复制代理配置到安装目录"
    fi

    cd "$V2RAY_DIR"
    print_success "创建目录: $V2RAY_DIR"
}

# 下载V2Ray - 使用Linux版本
download_v2ray() {
    print_info "下载V2Ray核心..."
    
    V2RAY_VERSION=$(curl -s https://api.github.com/repos/v2fly/v2ray-core/releases/latest | grep '"tag_name"' | cut -d'"' -f4 2>/dev/null)
    if [[ -z "$V2RAY_VERSION" ]]; then
        V2RAY_VERSION="v5.37.0"
        print_warning "无法获取最新版本，使用默认版本: $V2RAY_VERSION"
    else
        print_info "最新版本: $V2RAY_VERSION"
    fi
    
    V2RAY_URL="https://github.com/v2fly/v2ray-core/releases/download/${V2RAY_VERSION}/v2ray-linux-${V2RAY_ARCH}.zip"
    print_info "下载URL: $V2RAY_URL"
    
    if wget -q --show-progress "$V2RAY_URL" -O "v2ray-linux-${V2RAY_ARCH}.zip"; then
        print_success "V2Ray下载完成"
    else
        print_error "V2Ray下载失败"
        exit 1
    fi
    
    print_info "解压V2Ray..."
    unzip -q "v2ray-linux-${V2RAY_ARCH}.zip"
    
    chmod +x v2ray
    if [[ -f v2ctl ]]; then
        chmod +x v2ctl
    fi
    
    rm "v2ray-linux-${V2RAY_ARCH}.zip"
    print_success "V2Ray解压完成"
    
    if ./v2ray version >/dev/null 2>&1; then
        VERSION_INFO=$(./v2ray version | head -1)
        print_success "V2Ray安装成功: $VERSION_INFO"
    else
        print_error "V2Ray安装失败"
        exit 1
    fi
}

# 下载订阅内容
download_subscription() {
    print_info "下载订阅内容..."
    
    if curl -L "$SUBSCRIPTION_URL" -o subscription.txt; then
        print_success "订阅内容下载成功"
    else
        print_error "订阅内容下载失败"
        exit 1
    fi
    
    if [[ ! -s subscription.txt ]]; then
        print_error "订阅文件为空"
        exit 1
    fi
    
    print_success "订阅内容验证通过"
}

# 创建订阅解析脚本（与Linux版本相同的逻辑）
create_parser_script() {
    print_info "创建订阅解析脚本..."
    
    # 创建订阅解析器
    cat > full_parser.py << 'PARSER_EOF'
#!/usr/bin/env python3
import base64
import json
import urllib.parse
import sys
import re

def parse_vmess(vmess_url):
    """解析vmess链接"""
    if not vmess_url.startswith('vmess://'):
        return None
    
    try:
        encoded = vmess_url[8:]
        missing_padding = len(encoded) % 4
        if missing_padding:
            encoded += '=' * (4 - missing_padding)
        
        decoded = base64.b64decode(encoded).decode('utf-8')
        config = json.loads(decoded)
        
        return {
            'protocol': 'vmess',
            'id': config.get('id', ''),
            'address': config.get('add', ''),
            'port': int(config.get('port', 443)),
            'aid': int(config.get('aid', 0)),
            'net': config.get('net', 'tcp'),
            'type': config.get('type', 'none'),
            'host': config.get('host', ''),
            'path': config.get('path', ''),
            'tls': config.get('tls', ''),
            'sni': config.get('sni', ''),
            'remark': config.get('ps', f'VMess-{config.get("add", "Unknown")}')
        }
    except Exception as e:
        return None

def parse_vless(vless_url):
    """解析vless链接"""
    if not vless_url.startswith('vless://'):
        return None
    
    try:
        url_part = vless_url[8:]
        if '@' not in url_part:
            return None
            
        user_info, server_part = url_part.split('@', 1)
        
        if '?' not in server_part:
            server_addr = server_part.split('#')[0]
            params = {}
            remark = ""
        else:
            server_addr, query_part = server_part.split('?', 1)
            if '#' in query_part:
                query_string, remark = query_part.split('#', 1)
                remark = urllib.parse.unquote(remark)
            else:
                query_string = query_part
                remark = ""
            params = urllib.parse.parse_qs(query_string)
            params = {k: v[0] if v else '' for k, v in params.items()}
        
        if ':' in server_addr:
            address, port = server_addr.rsplit(':', 1)
        else:
            address = server_addr
            port = "443"
        
        return {
            'protocol': 'vless',
            'id': user_info,
            'address': address,
            'port': int(port),
            'encryption': params.get('encryption', 'none'),
            'type': params.get('type', 'tcp'),
            'security': params.get('security', ''),
            'path': params.get('path', '/'),
            'remark': remark if remark else f'VLESS-{address}'
        }
    except Exception as e:
        return None

def parse_shadowsocks(ss_url):
    """解析shadowsocks链接"""
    if not ss_url.startswith('ss://'):
        return None
    
    try:
        url_part = ss_url[5:]
        
        if '#' in url_part:
            url_part, remark = url_part.split('#', 1)
            remark = urllib.parse.unquote(remark)
        else:
            remark = ""
        
        if '?' in url_part:
            url_part = url_part.split('?')[0]
        
        if '@' in url_part:
            user_info, server_part = url_part.split('@', 1)
            
            try:
                missing_padding = len(user_info) % 4
                if missing_padding:
                    user_info += '=' * (4 - missing_padding)
                decoded_user = base64.b64decode(user_info).decode('utf-8')
                
                if ':' in decoded_user:
                    method, password = decoded_user.split(':', 1)
                else:
                    method = 'aes-256-gcm'
                    password = decoded_user
            except:
                method = 'aes-256-gcm'
                password = user_info
        else:
            try:
                missing_padding = len(url_part) % 4
                if missing_padding:
                    url_part += '=' * (4 - missing_padding)
                decoded = base64.b64decode(url_part).decode('utf-8')
                
                if '@' in decoded:
                    user_part, server_part = decoded.split('@', 1)
                    if ':' in user_part:
                        method, password = user_part.split(':', 1)
                    else:
                        method = 'aes-256-gcm'
                        password = user_part
                else:
                    return None
            except:
                return None
        
        server_part = server_part.rstrip('/')
        
        if ':' in server_part:
            address, port_str = server_part.rsplit(':', 1)
            port_str = re.sub(r'[^\d]', '', port_str)
            try:
                port = int(port_str)
            except ValueError:
                return None
        else:
            address = server_part
            port = 443
        
        return {
            'protocol': 'shadowsocks',
            'method': method,
            'password': password,
            'address': address,
            'port': port,
            'remark': remark if remark else f'SS-{address}'
        }
    except Exception as e:
        return None

def create_v2ray_config(config_data, proxy_mode="local", listen_ip="127.0.0.1", socks5_port=1080, http_port=8080):
    """创建V2Ray配置"""
    protocol = config_data['protocol']
    
    base_config = {
        "log": {"loglevel": "warning"},
        "dns": {
            "servers": ["223.5.5.5", "114.114.114.114", "8.8.8.8"]
        },
        "inbounds": [{
            "tag": "socks",
            "port": socks5_port,
            "listen": listen_ip,
            "protocol": "socks",
            "sniffing": {"enabled": True, "destOverride": ["http", "tls"]},
            "settings": {"auth": "noauth", "udp": False}
        }, {
            "tag": "http",
            "port": http_port,
            "listen": listen_ip,
            "protocol": "http",
            "sniffing": {"enabled": True, "destOverride": ["http", "tls"]},
            "settings": {}
        }],
        "outbounds": [],
        "routing": {
            "domainStrategy": "IPOnDemand",
            "rules": [
                {"type": "field", "ip": ["geoip:private"], "outboundTag": "direct"},
                {"type": "field", "ip": ["geoip:cn"], "outboundTag": "direct"},
                {"type": "field", "domain": ["geosite:cn"], "outboundTag": "direct"}
            ]
        }
    }
    
    if protocol == 'vmess':
        base_config["outbounds"].append({
            "tag": "proxy",
            "protocol": "vmess",
            "settings": {
                "vnext": [{
                    "address": config_data['address'],
                    "port": config_data['port'],
                    "users": [{
                        "id": config_data['id'],
                        "alterId": config_data['aid'],
                        "security": "auto"
                    }]
                }]
            },
            "streamSettings": {
                "network": config_data['net'],
                "security": config_data['tls'] if config_data['tls'] else "none"
            }
        })
        
        if config_data['net'] == 'ws':
            base_config["outbounds"][0]["streamSettings"]["wsSettings"] = {
                "path": config_data['path'] if config_data['path'] else "/",
                "headers": {"Host": config_data['host']} if config_data['host'] else {}
            }
            
        if config_data['tls'] == 'tls':
            base_config["outbounds"][0]["streamSettings"]["tlsSettings"] = {
                "allowInsecure": False,
                "serverName": config_data['sni'] if config_data['sni'] else config_data['address']
            }
            
    elif protocol == 'vless':
        base_config["outbounds"].append({
            "tag": "proxy",
            "protocol": "vless",
            "settings": {
                "vnext": [{
                    "address": config_data['address'],
                    "port": config_data['port'],
                    "users": [{
                        "id": config_data['id'],
                        "encryption": config_data['encryption']
                    }]
                }]
            },
            "streamSettings": {
                "network": config_data['type'],
                "security": config_data['security'] if config_data['security'] else "none"
            }
        })
        
    elif protocol == 'shadowsocks':
        base_config["outbounds"].append({
            "tag": "proxy",
            "protocol": "shadowsocks",
            "settings": {
                "servers": [{
                    "address": config_data['address'],
                    "port": config_data['port'],
                    "method": config_data['method'],
                    "password": config_data['password']
                }]
            }
        })
    
    base_config["outbounds"].append({
        "tag": "direct",
        "protocol": "freedom",
        "settings": {}
    })
    
    return base_config

def main():
    print("=== V2Ray订阅解析器 (WSL版本) ===")
    
    with open('subscription.txt', 'r') as f:
        content = f.read().strip()
    
    if not content.startswith(('vmess://', 'vless://', 'ss://')):
        try:
            content = base64.b64decode(content).decode('utf-8')
            print("✅ Base64解码成功")
        except Exception as e:
            print(f"❌ Base64解码失败: {e}")
            return
    
    lines = content.split('\n')
    configs = []
    
    for line in lines:
        line = line.strip()
        if not line:
            continue
        
        config = None
        if line.startswith('vmess://'):
            config = parse_vmess(line)
        elif line.startswith('vless://'):
            config = parse_vless(line)
        elif line.startswith('ss://'):
            config = parse_shadowsocks(line)
        
        if config:
            configs.append(config)
            print(f"✅ [{len(configs)}] {config['protocol'].upper()}: {config['remark']}")
    
    if not configs:
        print("❌ 没有找到有效配置")
        return
    
    servers_data = {
        'servers': configs,
        'current_server': 0,
        'total': len(configs)
    }
    
    with open('servers_all.json', 'w') as f:
        json.dump(servers_data, f, indent=2, ensure_ascii=False)
    
    print(f"\n✅ 已保存 {len(configs)} 个服务器配置")
    
    # 读取代理配置
    proxy_mode = "local"
    listen_ip = "127.0.0.1"
    socks5_port = 1080
    http_port = 8080
    
    try:
        with open('proxy_config.txt', 'r') as f:
            for line in f:
                if '=' in line:
                    key, value = line.strip().split('=', 1)
                    if key == 'PROXY_MODE':
                        proxy_mode = value
                    elif key == 'LISTEN_IP':
                        listen_ip = value
                    elif key == 'SOCKS5_PORT':
                        socks5_port = int(value)
                    elif key == 'HTTP_PORT':
                        http_port = int(value)
    except FileNotFoundError:
        print("⚠️  未找到proxy_config.txt，使用默认设置")
    
    # 选择第一个服务器
    choice = 1
    if len(sys.argv) > 1 and sys.argv[1] != "--auto":
        try:
            choice = int(sys.argv[1])
            if choice < 1 or choice > len(configs):
                choice = 1
        except ValueError:
            choice = 1
    
    selected_config = configs[choice - 1]
    v2ray_config = create_v2ray_config(selected_config, proxy_mode, listen_ip, socks5_port, http_port)
    
    with open('config.json', 'w') as f:
        json.dump(v2ray_config, f, indent=2, ensure_ascii=False)
    
    print(f"\n✅ 已生成配置文件: config.json")
    print(f"✅ 选择的服务器: {selected_config['remark']}")

if __name__ == "__main__":
    main()
PARSER_EOF

    chmod +x full_parser.py
    print_success "订阅解析脚本创建完成"
}

# 解析订阅并生成配置
parse_subscription() {
    print_info "解析订阅配置..."
    
    if python3 full_parser.py --auto; then
        print_success "订阅解析成功"
    else
        print_error "订阅解析失败"
        exit 1
    fi
    
    print_info "测试V2Ray配置..."
    if ./v2ray test -config config.json; then
        print_success "配置文件测试通过"
    else
        print_error "配置文件测试失败"
        exit 1
    fi
}

# 创建管理脚本
create_management_scripts() {
    print_info "创建管理脚本..."
    
    # 创建启动脚本
    cat > start.sh << 'EOF'
#!/bin/bash
cd ~/v2ray

echo "=== 启动 V2Ray (WSL) ==="

if [ -f v2ray.pid ] && kill -0 $(cat v2ray.pid) 2>/dev/null; then
    echo "⚠️  V2Ray已在运行 (PID: $(cat v2ray.pid))"
    exit 0
fi

if [ ! -f config.json ]; then
    echo "❌ 配置文件不存在"
    exit 1
fi

# 读取端口配置
SOCKS5_PORT="1080"
HTTP_PORT="8080"
if [ -f proxy_config.txt ]; then
    SOCKS5_PORT=$(grep "SOCKS5_PORT=" proxy_config.txt | cut -d'=' -f2)
    HTTP_PORT=$(grep "HTTP_PORT=" proxy_config.txt | cut -d'=' -f2)
fi

echo "🚀 启动V2Ray..."
nohup ./v2ray run -config config.json > v2ray.log 2>&1 &
echo $! > v2ray.pid

sleep 2

if kill -0 $(cat v2ray.pid) 2>/dev/null; then
    echo "✅ V2Ray启动成功 (PID: $(cat v2ray.pid))"
    echo "📡 SOCKS5代理: 127.0.0.1:$SOCKS5_PORT"
    echo "🌐 HTTP代理: 127.0.0.1:$HTTP_PORT"
    
    # 获取WSL IP地址
    WSL_IP=$(hostname -I | awk '{print $1}')
    if [ -n "$WSL_IP" ]; then
        echo ""
        echo "🔹 Windows系统代理设置:"
        echo "   SOCKS5: $WSL_IP:$SOCKS5_PORT"
        echo "   HTTP:   $WSL_IP:$HTTP_PORT"
    fi
else
    echo "❌ V2Ray启动失败"
    rm -f v2ray.pid
    exit 1
fi
EOF

    # 创建停止脚本
    cat > stop.sh << 'EOF'
#!/bin/bash
cd ~/v2ray

echo "=== 停止 V2Ray ==="
if [ -f v2ray.pid ]; then
    PID=$(cat v2ray.pid)
    if kill -0 $PID 2>/dev/null; then
        kill $PID
        echo "✅ V2Ray已停止"
    fi
    rm -f v2ray.pid
else
    echo "⚠️  V2Ray未运行"
fi
EOF

    # 创建状态脚本
    cat > status.sh << 'EOF'
#!/bin/bash
cd ~/v2ray

echo "=== V2Ray 状态 (WSL) ==="

if [ -f v2ray.pid ] && kill -0 $(cat v2ray.pid) 2>/dev/null; then
    echo "✅ V2Ray正在运行 (PID: $(cat v2ray.pid))"
    
    # 读取端口配置
    if [ -f proxy_config.txt ]; then
        SOCKS5_PORT=$(grep "SOCKS5_PORT=" proxy_config.txt | cut -d'=' -f2)
        HTTP_PORT=$(grep "HTTP_PORT=" proxy_config.txt | cut -d'=' -f2)
        echo "📡 SOCKS5代理: 127.0.0.1:$SOCKS5_PORT"
        echo "🌐 HTTP代理: 127.0.0.1:$HTTP_PORT"
        
        # 获取WSL IP
        WSL_IP=$(hostname -I | awk '{print $1}')
        if [ -n "$WSL_IP" ]; then
            echo ""
            echo "🔹 Windows访问地址:"
            echo "   SOCKS5: $WSL_IP:$SOCKS5_PORT"
            echo "   HTTP:   $WSL_IP:$HTTP_PORT"
        fi
    fi
else
    echo "❌ V2Ray未运行"
fi
EOF

    # 创建重启脚本
    cat > restart.sh << 'EOF'
#!/bin/bash
cd ~/v2ray
./stop.sh
sleep 2
./start.sh
EOF

    chmod +x *.sh
    print_success "管理脚本创建完成"
}

# 创建别名配置
create_aliases() {
    print_info "配置命令别名..."
    
    if grep -q "# V2Ray WSL 管理别名" ~/.bashrc 2>/dev/null; then
        print_warning "别名已存在，跳过配置"
        return
    fi
    
    cat >> ~/.bashrc << 'EOF'

# V2Ray WSL 管理别名
alias v2start="cd ~/v2ray && ./start.sh"
alias v2stop="cd ~/v2ray && ./stop.sh"
alias v2status="cd ~/v2ray && ./status.sh"
alias v2restart="cd ~/v2ray && ./restart.sh"
EOF

    print_success "别名配置完成"
}

# 显示使用说明
show_usage() {
    echo ""
    print_success "==================== 安装完成 ===================="
    echo ""
    print_info "🎉 V2Ray WSL 已成功安装到: $V2RAY_DIR"
    echo ""
    
    if [[ -f proxy_config.txt ]]; then
        source proxy_config.txt
        print_menu "🌐 代理设置:"
        echo "  WSL内访问:"
        echo "    SOCKS5: 127.0.0.1:$SOCKS5_PORT"
        echo "    HTTP:   127.0.0.1:$HTTP_PORT"
        
        if [[ "$PROXY_MODE" == "windows" ]]; then
            WSL_IP=$(hostname -I | awk '{print $1}')
            echo ""
            echo "  Windows系统访问:"
            echo "    SOCKS5: $WSL_IP:$SOCKS5_PORT"
            echo "    HTTP:   $WSL_IP:$HTTP_PORT"
        fi
    fi
    
    echo ""
    print_menu "🚀 常用命令:"
    echo "  v2start     - 启动服务"
    echo "  v2stop      - 停止服务"
    echo "  v2status    - 查看状态"
    echo "  v2restart   - 重启服务"
    echo ""
    print_warning "⚡ 请运行 'source ~/.bashrc' 来加载别名配置"
    echo ""
    print_success "=================================================="
}

# 主函数
main() {
    print_banner
    check_wsl_environment
    check_environment
    get_subscription_url
    select_proxy_mode
    create_directories
    download_v2ray
    download_subscription
    create_parser_script
    parse_subscription
    create_management_scripts
    create_aliases
    show_usage
}

main "$@"
