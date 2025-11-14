#!/bin/bash

# V2Ray 完整版安装脚本 v3.0
# 支持VMess、VLESS、Shadowsocks协议
# 支持服务器选择、切换、DNS配置
# 适用于无root权限的Linux服务器

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
    echo "      V2Ray 完整版安装脚本 v3.0"
    echo "=================================================="
    echo "支持协议: VMess | VLESS | Shadowsocks"
    echo "支持功能: 多服务器 | 智能切换 | DNS配置"
    echo "适用环境: 无root权限 Linux 服务器"
    echo "=================================================="
    echo -e "${NC}"
}

# 检查命令是否存在
check_command() {
    if ! command -v $1 >/dev/null 2>&1; then
        print_error "命令 $1 未找到，请确保已安装"
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
        print_error "缺少必要命令: ${missing_commands[*]}"
        print_info "请联系管理员安装这些工具"
        exit 1
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
    echo "1) 本机代理 (仅本机使用)"
    echo "   - SOCKS5: 127.0.0.1:[自定义端口]"
    echo "   - HTTP:   127.0.0.1:[自定义端口]"
    echo "   - 更安全，仅限本机访问"
    echo ""
    echo "2) 局域网共享 (局域网内其他设备可使用)"
    echo "   - SOCKS5: 0.0.0.0:[自定义端口]"
    echo "   - HTTP:   0.0.0.0:[自定义端口]"
    echo "   - 需要设置用户名密码认证"
    echo ""
    echo "📝 后续可自定义设置端口号"
    echo ""

    while true; do
        read -p "请选择代理模式 (1-2) [默认: 1]: " PROXY_MODE_CHOICE

        if [[ -z "$PROXY_MODE_CHOICE" ]]; then
            PROXY_MODE_CHOICE="1"
        fi

        case $PROXY_MODE_CHOICE in
            1)
                PROXY_MODE="local"
                LISTEN_IP="127.0.0.1"
                AUTH_TYPE="noauth"
                print_success "已选择: 本机代理模式"
                break
                ;;
            2)
                PROXY_MODE="network"
                LISTEN_IP="0.0.0.0"
                AUTH_TYPE="password"
                print_success "已选择: 局域网共享模式"
                setup_auth_credentials
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
            # 验证端口格式
            if [[ ! "$SOCKS5_PORT_INPUT" =~ ^[0-9]+$ ]]; then
                print_warning "端口必须是数字"
                continue
            fi
            if [[ "$SOCKS5_PORT_INPUT" -lt 1 || "$SOCKS5_PORT_INPUT" -gt 65535 ]]; then
                print_warning "端口范围必须在1-65535之间"
                continue
            fi
            if [[ "$SOCKS5_PORT_INPUT" -lt 1024 ]]; then
                print_warning "建议使用1024以上的端口避免权限问题"
                read -p "是否继续使用端口 $SOCKS5_PORT_INPUT? (y/N): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    continue
                fi
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
            # 验证端口格式
            if [[ ! "$HTTP_PORT_INPUT" =~ ^[0-9]+$ ]]; then
                print_warning "端口必须是数字"
                continue
            fi
            if [[ "$HTTP_PORT_INPUT" -lt 1 || "$HTTP_PORT_INPUT" -gt 65535 ]]; then
                print_warning "端口范围必须在1-65535之间"
                continue
            fi
            if [[ "$HTTP_PORT_INPUT" -lt 1024 ]]; then
                print_warning "建议使用1024以上的端口避免权限问题"
                read -p "是否继续使用端口 $HTTP_PORT_INPUT? (y/N): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    continue
                fi
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

    # 端口占用检查
    echo ""
    print_info "检查端口占用情况..."
    if command -v netstat >/dev/null 2>&1; then
        if netstat -tln 2>/dev/null | grep -q ":$SOCKS5_PORT "; then
            print_warning "端口 $SOCKS5_PORT 可能已被占用"
        fi
        if netstat -tln 2>/dev/null | grep -q ":$HTTP_PORT "; then
            print_warning "端口 $HTTP_PORT 可能已被占用"
        fi
    fi
}

# 保存代理模式配置
save_proxy_config() {
    cat > proxy_config.txt << EOF
PROXY_MODE=$PROXY_MODE
LISTEN_IP=$LISTEN_IP
AUTH_TYPE=$AUTH_TYPE
SOCKS5_PORT=$SOCKS5_PORT
HTTP_PORT=$HTTP_PORT
EOF

    if [[ "$AUTH_TYPE" == "password" ]]; then
        echo "AUTH_USER=$PROXY_USER" >> proxy_config.txt
        echo "AUTH_PASS=$PROXY_PASS" >> proxy_config.txt
    fi
}

# 设置认证凭据
setup_auth_credentials() {
    echo ""
    print_info "设置局域网共享认证凭据"
    print_warning "请设置强密码以确保安全"
    echo ""

    # 获取用户名
    while true; do
        read -p "请输入用户名 [默认: v2user]: " PROXY_USER_INPUT
        if [[ -z "$PROXY_USER_INPUT" ]]; then
            PROXY_USER="v2user"
        else
            # 验证用户名格式
            if [[ ! "$PROXY_USER_INPUT" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                print_warning "用户名只能包含字母、数字、下划线和横线"
                continue
            fi
            if [[ ${#PROXY_USER_INPUT} -lt 3 ]]; then
                print_warning "用户名长度至少为3位"
                continue
            fi
            PROXY_USER="$PROXY_USER_INPUT"
        fi
        break
    done

    # 获取密码
    while true; do
        read -s -p "请输入密码: " PROXY_PASS_INPUT
        echo ""
        if [[ -z "$PROXY_PASS_INPUT" ]]; then
            print_warning "密码不能为空"
            continue
        fi
        if [[ ${#PROXY_PASS_INPUT} -lt 6 ]]; then
            print_warning "密码长度至少为6位"
            continue
        fi

        read -s -p "请再次输入密码确认: " PROXY_PASS_CONFIRM
        echo ""
        if [[ "$PROXY_PASS_INPUT" != "$PROXY_PASS_CONFIRM" ]]; then
            print_warning "两次输入的密码不一致"
            continue
        fi

        PROXY_PASS="$PROXY_PASS_INPUT"
        break
    done

    print_success "认证凭据设置完成"
    print_info "用户名: $PROXY_USER"
    print_info "密码: ${PROXY_PASS:0:2}***${PROXY_PASS: -2}"

    # 显示网络信息
    echo ""
    print_info "网络信息提示:"
    print_info "本机IP地址: $(hostname -I | awk '{print $1}' 2>/dev/null || echo '获取失败')"
    print_warning "请确保局域网内其他设备可以访问此IP"
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
    cd "$V2RAY_DIR"
    print_success "创建目录: $V2RAY_DIR"
}

# 下载V2Ray
download_v2ray() {
    print_info "下载V2Ray核心..."
    
    # 获取最新版本
    V2RAY_VERSION=$(curl -s https://api.github.com/repos/v2fly/v2ray-core/releases/latest | grep '"tag_name"' | cut -d'"' -f4 2>/dev/null)
    if [[ -z "$V2RAY_VERSION" ]]; then
        V2RAY_VERSION="v5.37.0"
        print_warning "无法获取最新版本，使用默认版本: $V2RAY_VERSION"
    else
        print_info "最新版本: $V2RAY_VERSION"
    fi
    
    # 下载V2Ray
    V2RAY_URL="https://github.com/v2fly/v2ray-core/releases/download/${V2RAY_VERSION}/v2ray-linux-${V2RAY_ARCH}.zip"
    print_info "下载URL: $V2RAY_URL"
    
    if wget -q --show-progress "$V2RAY_URL" -O "v2ray-linux-${V2RAY_ARCH}.zip"; then
        print_success "V2Ray下载完成"
    else
        print_error "V2Ray下载失败"
        exit 1
    fi
    
    # 解压
    print_info "解压V2Ray..."
    unzip -q "v2ray-linux-${V2RAY_ARCH}.zip"
    
    # 新版本V2Ray可能没有v2ctl，只给v2ray设置权限
    chmod +x v2ray
    if [[ -f v2ctl ]]; then
        chmod +x v2ctl
        print_info "发现v2ctl文件，已设置执行权限"
    else
        print_info "新版本V2Ray，无需v2ctl文件"
    fi
    
    rm "v2ray-linux-${V2RAY_ARCH}.zip"
    print_success "V2Ray解压完成"
    
    # 验证安装
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
    
    # 检查订阅内容
    if [[ ! -s subscription.txt ]]; then
        print_error "订阅文件为空"
        exit 1
    fi
    
    print_success "订阅内容验证通过"
}

# 创建完整版订阅解析脚本
create_full_parser_script() {
    print_info "创建完整版订阅解析脚本..."
    
    cat > full_parser.py << 'EOF'
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
        url_part = ss_url[5:]  # 去掉 ss://
        
        # 分离备注
        if '#' in url_part:
            url_part, remark = url_part.split('#', 1)
            remark = urllib.parse.unquote(remark)
        else:
            remark = ""
        
        # 分离查询参数（去掉?group=等参数）
        if '?' in url_part:
            url_part = url_part.split('?')[0]
        
        # 分离用户信息和服务器信息
        if '@' in url_part:
            # 新格式: ss://base64(method:password)@server:port
            user_info, server_part = url_part.split('@', 1)
            
            # 解码用户信息
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
            # 旧格式: ss://base64(method:password@server:port)
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
        
        # 清理服务器部分，移除多余的/
        server_part = server_part.rstrip('/')
        
        # 分离服务器地址和端口
        if ':' in server_part:
            address, port_str = server_part.rsplit(':', 1)
            # 清理端口号，移除可能的非数字字符
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

def create_v2ray_config_shadowsocks(ss_config, proxy_mode="local", listen_ip="127.0.0.1", auth_type="noauth", auth_user=None, auth_pass=None, socks5_port=1080, http_port=8080):
    """为Shadowsocks创建V2Ray配置"""
    # 根据代理模式配置认证
    socks_settings = {"udp": False}
    if auth_type == "password":
        socks_settings["auth"] = "password"
        socks_settings["accounts"] = [{"user": auth_user, "pass": auth_pass}]
    else:
        socks_settings["auth"] = "noauth"

    return {
        "log": {"loglevel": "warning"},
        "dns": {
            "hosts": {
                "domain:v2fly.org": "www.vicemc.net",
                "domain:github.io": "pages.github.com",
                "domain:wikipedia.org": "www.wikimedia.org"
            },
            "servers": [
                "223.5.5.5",
                {
                    "address": "223.5.5.5",
                    "port": 53,
                    "domains": ["geosite:cn"]
                },
                "114.114.114.114",
                "8.8.8.8"
            ]
        },
        "inbounds": [{
            "tag": "socks",
            "port": socks5_port,
            "listen": listen_ip,
            "protocol": "socks",
            "sniffing": {"enabled": True, "destOverride": ["http", "tls"]},
            "settings": socks_settings
        }, {
            "tag": "http",
            "port": http_port,
            "listen": listen_ip,
            "protocol": "http",
            "sniffing": {"enabled": True, "destOverride": ["http", "tls"]},
            "settings": {"accounts": [{"user": auth_user, "pass": auth_pass}]} if auth_type == "password" else {}
        }],
        "outbounds": [{
            "tag": "proxy",
            "protocol": "shadowsocks",
            "settings": {
                "servers": [{
                    "address": ss_config['address'],
                    "port": ss_config['port'],
                    "method": ss_config['method'],
                    "password": ss_config['password']
                }]
            }
        }, {
            "tag": "direct",
            "protocol": "freedom",
            "settings": {}
        }],
        "routing": {
            "domainStrategy": "IPOnDemand",
            "rules": [
                {"type": "field", "ip": ["geoip:private"], "outboundTag": "direct"},
                {"type": "field", "ip": ["geoip:cn"], "outboundTag": "direct"},
                {"type": "field", "domain": ["geosite:cn"], "outboundTag": "direct"}
            ]
        }
    }

def create_v2ray_config_vless(vless_config, proxy_mode="local", listen_ip="127.0.0.1", auth_type="noauth", auth_user=None, auth_pass=None, socks5_port=1080, http_port=8080):
    """为VLESS创建V2Ray配置"""
    # 根据代理模式配置认证
    socks_settings = {"udp": False}
    if auth_type == "password":
        socks_settings["auth"] = "password"
        socks_settings["accounts"] = [{"user": auth_user, "pass": auth_pass}]
    else:
        socks_settings["auth"] = "noauth"

    return {
        "log": {"loglevel": "warning"},
        "dns": {
            "hosts": {
                "domain:v2fly.org": "www.vicemc.net",
                "domain:github.io": "pages.github.com",
                "domain:wikipedia.org": "www.wikimedia.org"
            },
            "servers": [
                "223.5.5.5",
                {
                    "address": "223.5.5.5",
                    "port": 53,
                    "domains": ["geosite:cn"]
                },
                "114.114.114.114",
                "8.8.8.8"
            ]
        },
        "inbounds": [{
            "tag": "socks",
            "port": socks5_port,
            "listen": listen_ip,
            "protocol": "socks",
            "sniffing": {"enabled": True, "destOverride": ["http", "tls"]},
            "settings": socks_settings
        }, {
            "tag": "http",
            "port": http_port,
            "listen": listen_ip,
            "protocol": "http",
            "sniffing": {"enabled": True, "destOverride": ["http", "tls"]},
            "settings": {"accounts": [{"user": auth_user, "pass": auth_pass}]} if auth_type == "password" else {}
        }],
        "outbounds": [{
            "tag": "proxy",
            "protocol": "vless",
            "settings": {
                "vnext": [{
                    "address": vless_config['address'],
                    "port": vless_config['port'],
                    "users": [{
                        "id": vless_config['id'],
                        "encryption": vless_config['encryption']
                    }]
                }]
            },
            "streamSettings": {
                "network": vless_config['type'],
                "security": vless_config['security'] if vless_config['security'] else "none"
            }
        }, {
            "tag": "direct",
            "protocol": "freedom",
            "settings": {}
        }],
        "routing": {
            "domainStrategy": "IPOnDemand",
            "rules": [
                {"type": "field", "ip": ["geoip:private"], "outboundTag": "direct"},
                {"type": "field", "ip": ["geoip:cn"], "outboundTag": "direct"},
                {"type": "field", "domain": ["geosite:cn"], "outboundTag": "direct"}
            ]
        }
    }

def create_v2ray_config_vmess(vmess_config, proxy_mode="local", listen_ip="127.0.0.1", auth_type="noauth", auth_user=None, auth_pass=None, socks5_port=1080, http_port=8080):
    """为VMess创建V2Ray配置"""
    # 根据代理模式配置认证
    socks_settings = {"udp": False}
    if auth_type == "password":
        socks_settings["auth"] = "password"
        socks_settings["accounts"] = [{"user": auth_user, "pass": auth_pass}]
    else:
        socks_settings["auth"] = "noauth"

    config = {
        "log": {"loglevel": "warning"},
        "dns": {
            "hosts": {
                "domain:v2fly.org": "www.vicemc.net",
                "domain:github.io": "pages.github.com",
                "domain:wikipedia.org": "www.wikimedia.org"
            },
            "servers": [
                "223.5.5.5",
                {
                    "address": "223.5.5.5",
                    "port": 53,
                    "domains": ["geosite:cn"]
                },
                "114.114.114.114",
                "8.8.8.8"
            ]
        },
        "inbounds": [{
            "tag": "socks",
            "port": socks5_port,
            "listen": listen_ip,
            "protocol": "socks",
            "sniffing": {"enabled": True, "destOverride": ["http", "tls"]},
            "settings": socks_settings
        }, {
            "tag": "http",
            "port": http_port,
            "listen": listen_ip,
            "protocol": "http",
            "sniffing": {"enabled": True, "destOverride": ["http", "tls"]},
            "settings": {"accounts": [{"user": auth_user, "pass": auth_pass}]} if auth_type == "password" else {}
        }],
        "outbounds": [{
            "tag": "proxy",
            "protocol": "vmess",
            "settings": {
                "vnext": [{
                    "address": vmess_config['address'],
                    "port": vmess_config['port'],
                    "users": [{
                        "id": vmess_config['id'],
                        "alterId": vmess_config['aid'],
                        "security": "auto"
                    }]
                }]
            },
            "streamSettings": {
                "network": vmess_config['net'],
                "security": vmess_config['tls'] if vmess_config['tls'] else "none"
            }
        }, {
            "tag": "direct",
            "protocol": "freedom",
            "settings": {}
        }],
        "routing": {
            "domainStrategy": "IPOnDemand",
            "rules": [
                {"type": "field", "ip": ["geoip:private"], "outboundTag": "direct"},
                {"type": "field", "ip": ["geoip:cn"], "outboundTag": "direct"},
                {"type": "field", "domain": ["geosite:cn"], "outboundTag": "direct"}
            ]
        }
    }

    # 处理WebSocket
    if vmess_config['net'] == 'ws':
        config["outbounds"][0]["streamSettings"]["wsSettings"] = {
            "path": vmess_config['path'] if vmess_config['path'] else "/",
            "headers": {"Host": vmess_config['host']} if vmess_config['host'] else {}
        }

    # 处理TLS
    if vmess_config['tls'] == 'tls':
        config["outbounds"][0]["streamSettings"]["tlsSettings"] = {
            "allowInsecure": False,
            "serverName": vmess_config['sni'] if vmess_config['sni'] else vmess_config['address']
        }

    return config

def generate_config_for_server(server_index):
    """为指定服务器生成配置"""
    try:
        with open('servers_all.json', 'r') as f:
            servers_data = json.load(f)
    except:
        return False

    # 读取代理模式配置
    proxy_mode = "local"
    listen_ip = "127.0.0.1"
    auth_type = "noauth"
    auth_user = None
    auth_pass = None
    socks5_port = 1080
    http_port = 8080

    try:
        with open('proxy_config.txt', 'r') as f:
            proxy_config = {}
            for line in f:
                if '=' in line:
                    key, value = line.strip().split('=', 1)
                    proxy_config[key] = value

            proxy_mode = proxy_config.get('PROXY_MODE', 'local')
            listen_ip = proxy_config.get('LISTEN_IP', '127.0.0.1')
            auth_type = proxy_config.get('AUTH_TYPE', 'noauth')
            auth_user = proxy_config.get('AUTH_USER')
            auth_pass = proxy_config.get('AUTH_PASS')
            socks5_port = int(proxy_config.get('SOCKS5_PORT', '1080'))
            http_port = int(proxy_config.get('HTTP_PORT', '8080'))
    except:
        print("⚠️  未找到代理模式配置，使用默认设置")

    if server_index >= len(servers_data['servers']):
        return False

    selected_config = servers_data['servers'][server_index]

    if selected_config['protocol'] == 'vless':
        v2ray_config = create_v2ray_config_vless(selected_config, proxy_mode, listen_ip, auth_type, auth_user, auth_pass, socks5_port, http_port)
    elif selected_config['protocol'] == 'vmess':
        v2ray_config = create_v2ray_config_vmess(selected_config, proxy_mode, listen_ip, auth_type, auth_user, auth_pass, socks5_port, http_port)
    elif selected_config['protocol'] == 'shadowsocks':
        v2ray_config = create_v2ray_config_shadowsocks(selected_config, proxy_mode, listen_ip, auth_type, auth_user, auth_pass, socks5_port, http_port)
    else:
        return False

    with open('config.json', 'w') as f:
        json.dump(v2ray_config, f, indent=2, ensure_ascii=False)

    # 更新当前服务器索引
    servers_data['current_server'] = server_index
    with open('servers_all.json', 'w') as f:
        json.dump(servers_data, f, indent=2, ensure_ascii=False)

    return True

def main():
    print("=== V2Ray完整协议订阅解析器 v3.0 ===")
    
    # 读取订阅文件
    with open('subscription.txt', 'r') as f:
        content = f.read().strip()
    
    # 解码base64
    if not content.startswith(('vmess://', 'vless://', 'ss://', 'trojan://')):
        try:
            content = base64.b64decode(content).decode('utf-8')
            print("✅ Base64解码成功")
        except Exception as e:
            print(f"❌ Base64解码失败: {e}")
            return
    
    # 分割行
    lines = content.split('\n')
    print(f"📊 检测到 {len(lines)} 行内容")
    
    configs = []
    stats = {'vmess': 0, 'vless': 0, 'shadowsocks': 0, 'failed': 0, 'skipped': 0}
    
    for i, line in enumerate(lines, 1):
        line = line.strip()
        if not line:
            stats['skipped'] += 1
            continue
        
        config = None
        if line.startswith('vmess://'):
            config = parse_vmess(line)
            if config:
                stats['vmess'] += 1
                configs.append(config)
                print(f"✅ [{len(configs)}] VMess: {config['remark']}")
            else:
                stats['failed'] += 1
                
        elif line.startswith('vless://'):
            config = parse_vless(line)
            if config:
                stats['vless'] += 1
                configs.append(config)
                print(f"✅ [{len(configs)}] VLESS: {config['remark']}")
            else:
                stats['failed'] += 1
                
        elif line.startswith('ss://'):
            config = parse_shadowsocks(line)
            if config:
                stats['shadowsocks'] += 1
                configs.append(config)
                print(f"✅ [{len(configs)}] SS: {config['remark']}")
            else:
                stats['failed'] += 1
        else:
            if len(line) > 10:
                pass  # 静默跳过未知协议
            stats['skipped'] += 1
    
    print(f"\n📊 解析统计:")
    print(f"  VMess: {stats['vmess']}")
    print(f"  VLESS: {stats['vless']}")
    print(f"  Shadowsocks: {stats['shadowsocks']}")
    print(f"  失败: {stats['failed']}")
    print(f"  跳过: {stats['skipped']}")
    print(f"  总计: {len(configs)} 个有效配置")
    
    if not configs:
        print("❌ 没有找到有效配置")
        return
    
    # 保存所有配置
    servers_data = {
        'servers': configs,
        'current_server': 0,
        'total': len(configs),
        'stats': stats
    }
    
    with open('servers_all.json', 'w') as f:
        json.dump(servers_data, f, indent=2, ensure_ascii=False)
    
    print(f"✅ 已保存 {len(configs)} 个服务器配置")
    
    # 显示服务器列表
    print(f"\n=== 所有服务器 ({len(configs)}) ===")
    for i, server in enumerate(configs, 1):
        protocol_emoji = {
            'vmess': '🔵',
            'vless': '🟢', 
            'shadowsocks': '🟡'
        }.get(server['protocol'], '⚪')
        
        print(f"[{i}] {protocol_emoji} {server['remark']}")
        print(f"    {server['protocol'].upper()} - {server['address']}:{server['port']}")
        
        if i >= 10 and len(configs) > 10:
            print(f"... 还有 {len(configs) - 10} 个服务器")
            break
    
    # 让用户选择
    if len(sys.argv) > 1 and sys.argv[1] == "--auto":
        choice = 1
    else:
        choice_input = input(f"\n请选择要使用的服务器 (1-{len(configs)}) [默认: 1]: ").strip()
        try:
            choice = int(choice_input) if choice_input else 1
            if choice < 1 or choice > len(configs):
                choice = 1
        except ValueError:
            choice = 1
    
    # 生成配置
    if generate_config_for_server(choice - 1):
        selected_config = configs[choice - 1]
        print(f"\n✅ 已生成配置文件: config.json")
        print(f"✅ 选择的服务器: {selected_config['remark']}")
        print(f"✅ 协议: {selected_config['protocol'].upper()}")
        print(f"✅ 地址: {selected_config['address']}:{selected_config['port']}")
    else:
        print("❌ 配置生成失败")

if __name__ == "__main__":
    main()
EOF

    chmod +x full_parser.py
    print_success "完整版订阅解析脚本创建完成"
}

# 解析订阅并生成配置
parse_subscription() {
    print_info "解析订阅配置..."
    
    if python3 full_parser.py; then
        print_success "订阅解析成功"
    else
        print_error "订阅解析失败"
        exit 1
    fi
    
    # 测试配置文件
    print_info "测试V2Ray配置..."
    if ./v2ray test -config config.json; then
        print_success "配置文件测试通过"
    else
        print_error "配置文件测试失败"
        exit 1
    fi
}

# 创建完整的管理脚本
create_management_scripts() {
    print_info "创建管理脚本..."
    
    # 创建服务器管理器
    cat > server_manager.py << 'EOF'
#!/usr/bin/env python3
import json
import sys

def load_servers():
    try:
        with open('servers_all.json', 'r') as f:
            return json.load(f)
    except:
        print("❌ 未找到服务器列表，请先运行: python3 full_parser.py")
        return None

def list_servers(filter_protocol=None):
    data = load_servers()
    if not data:
        return
    
    servers = data['servers']
    if filter_protocol:
        servers = [s for s in servers if s['protocol'] == filter_protocol]
    
    protocol_emoji = {
        'vmess': '🔵',
        'vless': '🟢', 
        'shadowsocks': '🟡'
    }
    
    print(f"=== 服务器列表 ({len(servers)}) ===")
    if 'stats' in data:
        stats = data['stats']
        print(f"统计: VMess({stats['vmess']}) VLESS({stats['vless']}) SS({stats['shadowsocks']})")
        print()
    
    for i, server in enumerate(servers, 1):
        emoji = protocol_emoji.get(server['protocol'], '⚪')
        marker = " [当前]" if i-1 == data.get('current_server', 0) else ""
        print(f"[{i}] {emoji} {server['remark']}{marker}")
        print(f"    {server['protocol'].upper()} - {server['address']}:{server['port']}")

def switch_server(index):
    from full_parser import generate_config_for_server
    
    data = load_servers()
    if not data:
        return False
    
    if index < 1 or index > len(data['servers']):
        print("❌ 无效的服务器编号")
        return False
    
    if generate_config_for_server(index - 1):
        selected = data['servers'][index - 1]
        print(f"✅ 已切换到: {selected['remark']}")
        print(f"✅ 协议: {selected['protocol'].upper()}")
        return True
    else:
        print("❌ 切换失败")
        return False

def show_help():
    print("服务器管理器 v3.0")
    print("")
    print("用法:")
    print("  python3 server_manager.py list [protocol]  - 列出服务器")
    print("  python3 server_manager.py switch <num>     - 切换服务器")
    print("  python3 server_manager.py vmess            - 只显示VMess服务器")
    print("  python3 server_manager.py vless            - 只显示VLESS服务器") 
    print("  python3 server_manager.py ss               - 只显示Shadowsocks服务器")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        list_servers()
    elif sys.argv[1] == "list":
        protocol = sys.argv[2] if len(sys.argv) > 2 else None
        list_servers(protocol)
    elif sys.argv[1] == "switch":
        if len(sys.argv) < 3:
            print("请指定服务器编号")
        else:
            try:
                index = int(sys.argv[2])
                switch_server(index)
            except ValueError:
                print("编号必须是数字")
    elif sys.argv[1] in ['vmess', 'vless', 'ss']:
        protocol = 'shadowsocks' if sys.argv[1] == 'ss' else sys.argv[1]
        list_servers(protocol)
    else:
        show_help()
EOF

    chmod +x server_manager.py

    # 创建启动脚本
    cat > start.sh << 'EOF'
#!/bin/bash
cd ~/v2ray

echo "=== 启动 V2Ray ==="

# 检查是否已运行
if [ -f v2ray.pid ] && kill -0 $(cat v2ray.pid) 2>/dev/null; then
    echo "⚠️  V2Ray已在运行 (PID: $(cat v2ray.pid))"
    echo "如需重启，请先运行: ./restart.sh"
    exit 0
fi

# 检查配置文件
if [ ! -f config.json ]; then
    echo "❌ 配置文件不存在，请先运行安装脚本"
    exit 1
fi

# 读取端口配置
SOCKS5_PORT="1080"
HTTP_PORT="8080"
if [ -f proxy_config.txt ]; then
    SOCKS5_PORT=$(grep "SOCKS5_PORT=" proxy_config.txt | cut -d'=' -f2 2>/dev/null || echo "1080")
    HTTP_PORT=$(grep "HTTP_PORT=" proxy_config.txt | cut -d'=' -f2 2>/dev/null || echo "8080")
fi

# 显示当前服务器信息
if [ -f servers_all.json ]; then
    CURRENT_SERVER=$(python3 -c "import json; data=json.load(open('servers_all.json')); print(data['servers'][data['current_server']]['remark'])" 2>/dev/null)
    if [ -n "$CURRENT_SERVER" ]; then
        echo "📡 当前服务器: $CURRENT_SERVER"
    fi
fi

# 测试配置
echo "🔍 测试配置文件..."
if ! ./v2ray test -config config.json >/dev/null 2>&1; then
    echo "❌ 配置文件测试失败"
    exit 1
fi

# 启动V2Ray
echo "🚀 启动V2Ray..."
nohup ./v2ray run -config config.json > v2ray.log 2>&1 &
echo $! > v2ray.pid

# 等待服务启动
sleep 2

# 验证启动
if kill -0 $(cat v2ray.pid) 2>/dev/null; then
    echo "✅ V2Ray启动成功 (PID: $(cat v2ray.pid))"
    echo "📡 SOCKS5代理: 127.0.0.1:$SOCKS5_PORT"
    echo "🌐 HTTP代理: 127.0.0.1:$HTTP_PORT"
    echo ""
    echo "💡 设置代理环境变量:"
    echo "export http_proxy=http://127.0.0.1:$HTTP_PORT"
    echo "export https_proxy=http://127.0.0.1:$HTTP_PORT"
else
    echo "❌ V2Ray启动失败，请检查日志: tail -f v2ray.log"
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
        echo "🛑 正在停止V2Ray (PID: $PID)..."
        
        # 等待进程结束
        for i in {1..5}; do
            if ! kill -0 $PID 2>/dev/null; then
                echo "✅ V2Ray已停止"
                rm -f v2ray.pid
                exit 0
            fi
            sleep 1
        done
        
        # 强制结束
        kill -9 $PID 2>/dev/null
        echo "✅ V2Ray已强制停止"
    else
        echo "⚠️  进程不存在，清理PID文件"
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

echo "=== V2Ray 状态检查 ==="

# 读取端口配置
SOCKS5_PORT="1080"
HTTP_PORT="8080"
if [ -f proxy_config.txt ]; then
    SOCKS5_PORT=$(grep "SOCKS5_PORT=" proxy_config.txt | cut -d'=' -f2 2>/dev/null || echo "1080")
    HTTP_PORT=$(grep "HTTP_PORT=" proxy_config.txt | cut -d'=' -f2 2>/dev/null || echo "8080")
fi

# 显示当前服务器信息
if [ -f servers_all.json ]; then
    echo "📋 服务器信息:"
    python3 server_manager.py list 2>/dev/null || echo "  无法读取服务器列表"
    echo ""
fi

if [ -f v2ray.pid ] && kill -0 $(cat v2ray.pid) 2>/dev/null; then
    echo "✅ V2Ray正在运行 (PID: $(cat v2ray.pid))"
    echo "📡 SOCKS5代理: 127.0.0.1:$SOCKS5_PORT"
    echo "🌐 HTTP代理: 127.0.0.1:$HTTP_PORT"

    # 检查端口占用
    if command -v netstat >/dev/null 2>&1; then
        echo ""
        echo "端口监听状态:"
        netstat -tlnp 2>/dev/null | grep ":$SOCKS5_PORT\|:$HTTP_PORT" | head -2
    fi
else
    echo "❌ V2Ray未运行"
    [ -f v2ray.pid ] && rm -f v2ray.pid
fi

echo ""
echo "日志文件: ~/v2ray/v2ray.log"
if [ -f v2ray.log ]; then
    echo "最新日志:"
    tail -3 v2ray.log
fi
EOF

    # 创建重启脚本
    cat > restart.sh << 'EOF'
#!/bin/bash
cd ~/v2ray

echo "=== 重启 V2Ray ==="
./stop.sh
sleep 2
./start.sh
EOF

    # 创建服务器切换脚本
    cat > switch.sh << 'EOF'
#!/bin/bash
cd ~/v2ray

echo "=== V2Ray 服务器切换器 v3.0 ==="

# 显示所有服务器
python3 server_manager.py list

echo ""
echo "🎯 可用命令:"
echo "  数字 - 切换到指定服务器"
echo "  vmess - 只显示VMess服务器"
echo "  vless - 只显示VLESS服务器" 
echo "  ss - 只显示Shadowsocks服务器"
echo "  rescan - 重新扫描订阅"
echo ""

read -p "请输入选择: " choice

case "$choice" in
    [0-9]*)
        if python3 server_manager.py switch "$choice"; then
            echo "🔄 重启V2Ray..."
            ./restart.sh
        fi
        ;;
    vmess|vless|ss)
        python3 server_manager.py "$choice"
        echo ""
        read -p "选择服务器编号: " num
        if [[ "$num" =~ ^[0-9]+$ ]]; then
            if python3 server_manager.py switch "$num"; then
                echo "🔄 重启V2Ray..."
                ./restart.sh
            fi
        fi
        ;;
    rescan)
        echo "🔄 重新解析订阅..."
        python3 full_parser.py
        ;;
    *)
        echo "❌ 无效选择"
        ;;
esac
EOF

    # 创建订阅更新脚本
    cat > update.sh << 'EOF'
#!/bin/bash
cd ~/v2ray

echo "=== 更新订阅配置 v3.0 ==="

# 获取当前订阅URL
if [ -f subscription_url.txt ]; then
    CURRENT_URL=$(cat subscription_url.txt)
    echo "📋 当前订阅: $CURRENT_URL"
    echo ""
    read -p "是否使用当前订阅链接? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        # 输入新的订阅链接
        echo "请输入新的订阅链接:"
        read -p "订阅URL: " NEW_URL
        if [[ -n "$NEW_URL" && "$NEW_URL" =~ ^https?:// ]]; then
            echo "$NEW_URL" > subscription_url.txt
            SUBSCRIPTION_URL="$NEW_URL"
            echo "✅ 已更新订阅链接"
        else
            echo "❌ 无效的订阅链接"
            exit 1
        fi
    else
        SUBSCRIPTION_URL="$CURRENT_URL"
    fi
else
    # 第一次使用，需要输入订阅链接
    echo "请输入订阅链接:"
    read -p "订阅URL: " SUBSCRIPTION_URL
    if [[ -z "$SUBSCRIPTION_URL" || ! "$SUBSCRIPTION_URL" =~ ^https?:// ]]; then
        echo "❌ 无效的订阅链接"
        exit 1
    fi
    echo "$SUBSCRIPTION_URL" > subscription_url.txt
fi

# 备份当前配置
if [ -f config.json ]; then
    cp config.json config.json.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ 已备份当前配置"
fi

# 备份当前服务器列表
if [ -f servers_all.json ]; then
    cp servers_all.json servers_all.json.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ 已备份服务器列表"
fi

# 下载新订阅
echo "📥 下载订阅..."
if curl -L "$SUBSCRIPTION_URL" -o subscription.txt; then
    echo "✅ 订阅下载成功"
else
    echo "❌ 订阅下载失败"
    exit 1
fi

# 解析订阅
echo "🔍 解析订阅..."
if python3 full_parser.py; then
    echo "✅ 订阅解析成功"
    
    # 询问是否重启
    read -p "是否立即重启V2Ray应用新配置? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./restart.sh
    else
        echo "💡 新配置已生成，运行 ./restart.sh 应用"
    fi
else
    echo "❌ 订阅解析失败"
    exit 1
fi
EOF

    # 创建连接脚本
    cat > connect.sh << 'EOF'
#!/bin/bash
cd ~/v2ray

echo "=== V2Ray 快速连接 v3.0 ==="

# 启动V2Ray（如果未运行）
if ! [ -f v2ray.pid ] || ! kill -0 $(cat v2ray.pid) 2>/dev/null; then
    echo "🚀 启动V2Ray..."
    ./start.sh
    sleep 2
fi

# 读取端口配置
SOCKS5_PORT="1080"
HTTP_PORT="8080"
if [ -f proxy_config.txt ]; then
    SOCKS5_PORT=$(grep "SOCKS5_PORT=" proxy_config.txt | cut -d'=' -f2 2>/dev/null || echo "1080")
    HTTP_PORT=$(grep "HTTP_PORT=" proxy_config.txt | cut -d'=' -f2 2>/dev/null || echo "8080")
fi

# 设置代理环境变量
export http_proxy=http://127.0.0.1:$HTTP_PORT
export https_proxy=http://127.0.0.1:$HTTP_PORT
export HTTP_PROXY=http://127.0.0.1:$HTTP_PORT
export HTTPS_PROXY=http://127.0.0.1:$HTTP_PORT
export ftp_proxy=http://127.0.0.1:$HTTP_PORT
export FTP_PROXY=http://127.0.0.1:$HTTP_PORT
export no_proxy="localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12"
export NO_PROXY="localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12"

echo "✅ 代理环境变量已设置"
echo "🌐 当前终端会话已连接代理"

# 显示当前服务器
if [ -f servers_all.json ]; then
    CURRENT_SERVER=$(python3 -c "import json; data=json.load(open('servers_all.json')); print(data['servers'][data['current_server']]['remark'])" 2>/dev/null)
    if [ -n "$CURRENT_SERVER" ]; then
        echo "📡 当前服务器: $CURRENT_SERVER"
    fi
fi

echo ""
echo "🔍 测试连接:"
if timeout 5 curl -s http://httpbin.org/ip >/dev/null 2>&1; then
    echo "✅ 代理连接正常"
    IP=$(timeout 5 curl -s http://httpbin.org/ip 2>/dev/null | grep -o '"origin": "[^"]*' | cut -d'"' -f4 2>/dev/null)
    if [ -n "$IP" ]; then
        echo "🌍 当前IP: $IP"
    fi
else
    echo "❌ 代理连接失败，请检查配置"
fi

# 启动一个新的bash会话，继承代理设置
echo ""
echo "💡 输入 'exit' 退出代理会话"
echo "💡 可用命令: v2status, v2switch, v2update"
bash
EOF

    # 设置执行权限
    chmod +x *.sh
    
    print_success "管理脚本创建完成"
}

# 创建别名配置
create_aliases() {
    print_info "配置命令别名..."
    
    # 检查是否已存在别名
    if grep -q "# V2Ray 完整版管理别名" ~/.bashrc 2>/dev/null; then
        print_warning "别名已存在，跳过配置"
        return
    fi
    
    cat >> ~/.bashrc << 'EOF'

# V2Ray 完整版管理别名 v3.0
alias v2start="cd ~/v2ray && ./start.sh"
alias v2stop="cd ~/v2ray && ./stop.sh"
alias v2status="cd ~/v2ray && ./status.sh"
alias v2restart="cd ~/v2ray && ./restart.sh"
alias v2connect="cd ~/v2ray && ./connect.sh"
alias v2switch="cd ~/v2ray && ./switch.sh"
alias v2update="cd ~/v2ray && ./update.sh"
alias v2log="cd ~/v2ray && tail -f v2ray.log"
alias v2list="cd ~/v2ray && python3 server_manager.py list"
alias v2vmess="cd ~/v2ray && python3 server_manager.py vmess"
alias v2vless="cd ~/v2ray && python3 server_manager.py vless"
alias v2ss="cd ~/v2ray && python3 server_manager.py ss"
alias v2scan="cd ~/v2ray && python3 full_parser.py"

# 代理管理别名
alias proxy_on="cd ~/v2ray && ./connect.sh"
alias proxy_off="unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY FTP_PROXY ftp_proxy NO_PROXY no_proxy"
alias proxy_status='echo "HTTP_PROXY: $HTTP_PROXY"; echo "HTTPS_PROXY: $HTTPS_PROXY"'
EOF

    print_success "别名配置完成"
}

# 测试安装
test_installation() {
    print_info "测试V2Ray安装..."
    
    # 启动V2Ray
    if ./start.sh; then
        print_success "V2Ray启动成功"
        
        # 等待服务稳定
        sleep 3
        
        # 测试代理连接
        print_info "测试代理连接..."
        export http_proxy=http://127.0.0.1:8080
        export https_proxy=http://127.0.0.1:8080
        
        if timeout 10 curl -s http://httpbin.org/ip >/dev/null 2>&1; then
            IP=$(timeout 10 curl -s http://httpbin.org/ip 2>/dev/null | grep -o '"origin": "[^"]*' | cut -d'"' -f4 2>/dev/null)
            print_success "代理连接测试成功"
            if [ -n "$IP" ]; then
                print_success "当前IP: $IP"
            fi
        else
            print_warning "代理连接测试失败，可能需要等待服务稳定"
        fi
    else
        print_error "V2Ray启动失败"
        return 1
    fi
}

# 显示使用说明
show_usage() {
    echo ""
    print_success "==================== 安装完成 ===================="
    echo ""
    print_info "🎉 V2Ray v3.0 已成功安装到: $V2RAY_DIR"
    echo ""

    # 读取代理模式信息
    if [[ -f proxy_config.txt ]]; then
        source proxy_config.txt
        if [[ "$PROXY_MODE" == "network" ]]; then
            print_info "🌐 代理模式: 局域网共享"
            print_info "🔧 认证信息: 用户名 $AUTH_USER"
            LOCAL_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "YOUR_IP")
            echo ""
            print_menu "🌐 代理设置 (局域网模式):"
            echo "  SOCKS5: $LOCAL_IP:$SOCKS5_PORT"
            echo "  HTTP:   $LOCAL_IP:$HTTP_PORT"
            echo "  认证:   用户名密码认证"
            echo ""
            print_info "💡 局域网设备连接设置:"
            echo "  SOCKS5代理地址: socks5://$AUTH_USER:$AUTH_PASS@$LOCAL_IP:$SOCKS5_PORT"
            echo "  HTTP代理地址:    http://$AUTH_USER:$AUTH_PASS@$LOCAL_IP:$HTTP_PORT"
        else
            print_info "🔒 代理模式: 本机代理"
            echo ""
            print_menu "🌐 代理设置 (本机模式):"
            echo "  SOCKS5: 127.0.0.1:$SOCKS5_PORT"
            echo "  HTTP:   127.0.0.1:$HTTP_PORT"
            echo "  认证:   无需认证"
            echo ""
            print_menu "📱 环境变量:"
            echo "  export http_proxy=http://127.0.0.1:$HTTP_PORT"
            echo "  export https_proxy=http://127.0.0.1:$HTTP_PORT"
        fi
    else
        print_menu "🌐 代理设置 (默认本机模式):"
        echo "  SOCKS5: 127.0.0.1:1080"
        echo "  HTTP:   127.0.0.1:8080"
    fi

    echo ""
    print_info "🔧 DNS: 223.5.5.5 (阿里云)"
    echo ""
    print_menu "🚀 常用命令:"
    echo "  v2start     - 启动服务"
    echo "  v2stop      - 停止服务"
    echo "  v2status    - 查看状态"
    echo "  v2restart   - 重启服务"
    echo "  v2connect   - 快速连接代理"
    echo ""
    print_menu "⚡ 服务器管理:"
    echo "  v2switch    - 切换服务器"
    echo "  v2list      - 列出所有服务器"
    echo "  v2vmess     - 列出VMess服务器"
    echo "  v2vless     - 列出VLESS服务器"
    echo "  v2ss        - 列出Shadowsocks服务器"
    echo "  v2update    - 更新订阅"
    echo "  v2scan      - 重新解析订阅"
    echo ""
    print_menu "🔄 服务器重启后:"
    echo "  1. 运行: v2start"
    echo "  2. 连接代理: v2connect"
    echo ""
    print_warning "⚡ 请运行 'source ~/.bashrc' 来加载别名配置"
    echo ""
    
    # 显示服务器统计
    if [[ -f servers_all.json ]]; then
        TOTAL=$(python3 -c "import json; print(json.load(open('servers_all.json'))['total'])" 2>/dev/null)
        if [[ -n "$TOTAL" ]]; then
            print_info "📊 共解析到 $TOTAL 个服务器节点"
        fi
    fi
    
    echo ""
    print_success "🎊 V2Ray完整版部署成功！现在你可以畅游互联网了！"
    print_success "=================================================="
}

# 清理函数
cleanup() {
    if [[ $? -ne 0 ]]; then
        print_error "安装过程中出现错误"
        print_info "清理临时文件..."
        cd "$HOME"
        if [[ -d "$V2RAY_DIR" ]]; then
            rm -rf "$V2RAY_DIR"
        fi
        exit 1
    fi
}

# 主函数
main() {
    # 显示横幅
    print_banner

    # 设置错误处理
    trap cleanup EXIT

    # 检查环境
    check_environment

    # 获取订阅链接
    get_subscription_url

    # 选择代理模式
    select_proxy_mode

    # 创建安装目录
    create_directories

    # 下载V2Ray
    download_v2ray

    # 下载订阅内容
    download_subscription

    # 创建完整版解析脚本
    create_full_parser_script

    # 解析订阅配置
    parse_subscription

    # 创建管理脚本
    create_management_scripts

    # 创建别名
    create_aliases

    # 测试安装
    test_installation

    # 显示使用说明
    show_usage

    # 取消错误处理
    trap - EXIT
}

# 运行主函数
main "$@"
