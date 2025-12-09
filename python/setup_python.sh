#!/bin/bash

# Python 环境配置脚本 v1.0
# 使用 Miniconda 管理 Python 环境

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
    echo "      Python 环境配置脚本 v1.0"
    echo "=================================================="
    echo "功能: Miniconda 安装 | pip 换源 | 环境管理"
    echo "=================================================="
    echo -e "${NC}"
}

# 检测系统架构
detect_architecture() {
    print_info "检测系统架构..."
    
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            CONDA_ARCH="x86_64"
            ;;
        aarch64|arm64)
            CONDA_ARCH="aarch64"
            ;;
        *)
            print_error "不支持的系统架构: $ARCH"
            exit 1
            ;;
    esac
    
    print_success "系统架构: $ARCH (Conda: $CONDA_ARCH)"
}

# 检查 Conda 是否已安装
check_conda_installed() {
    if command -v conda &> /dev/null; then
        CONDA_VERSION=$(conda --version | awk '{print $2}')
        CONDA_PATH=$(which conda)
        print_info "检测到已安装 Conda 版本: $CONDA_VERSION"
        print_info "安装路径: $CONDA_PATH"
        return 0
    else
        print_info "未检测到 Conda"
        return 1
    fi
}

# 选择 Miniconda 版本
select_miniconda_version() {
    echo ""
    echo "选择 Miniconda 版本:"
    echo "1) Miniconda3 (Python 3.11，推荐)"
    echo "2) Miniconda3 (Python 3.10)"
    echo "3) Miniconda3 (Python 3.9)"
    echo "4) 最新版本"
    echo ""
    
    read -p "请选择 [1-4, 默认: 1]: " version_choice
    version_choice=${version_choice:-1}
    
    case $version_choice in
        1)
            MINICONDA_VERSION="py311_23.11.0-2"
            PYTHON_VERSION="3.11"
            ;;
        2)
            MINICONDA_VERSION="py310_23.11.0-2"
            PYTHON_VERSION="3.10"
            ;;
        3)
            MINICONDA_VERSION="py39_23.11.0-2"
            PYTHON_VERSION="3.9"
            ;;
        4)
            MINICONDA_VERSION="latest"
            PYTHON_VERSION="latest"
            ;;
        *)
            MINICONDA_VERSION="py311_23.11.0-2"
            PYTHON_VERSION="3.11"
            ;;
    esac
    
    print_info "选择的 Python 版本: $PYTHON_VERSION"
}

# 下载 Miniconda
download_miniconda() {
    print_info "下载 Miniconda..."
    
    # 选择下载源
    echo ""
    echo "选择下载源:"
    echo "1) 清华大学镜像 (推荐)"
    echo "2) 阿里云镜像"
    echo "3) 中国科技大学镜像"
    echo "4) 官方源"
    echo ""
    
    read -p "请选择 [1-4, 默认: 1]: " mirror_choice
    mirror_choice=${mirror_choice:-1}
    
    case $mirror_choice in
        1)
            MIRROR_URL="https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda"
            MIRROR_NAME="清华大学"
            ;;
        2)
            MIRROR_URL="https://mirrors.aliyun.com/anaconda/miniconda"
            MIRROR_NAME="阿里云"
            ;;
        3)
            MIRROR_URL="https://mirrors.ustc.edu.cn/anaconda/miniconda"
            MIRROR_NAME="中国科技大学"
            ;;
        4)
            MIRROR_URL="https://repo.anaconda.com/miniconda"
            MIRROR_NAME="官方"
            ;;
        *)
            MIRROR_URL="https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda"
            MIRROR_NAME="清华大学"
            ;;
    esac
    
    print_info "使用 $MIRROR_NAME 镜像源"
    
    # 构建下载 URL
    if [[ "$MINICONDA_VERSION" == "latest" ]]; then
        DOWNLOAD_URL="$MIRROR_URL/Miniconda3-latest-Linux-${CONDA_ARCH}.sh"
    else
        DOWNLOAD_URL="$MIRROR_URL/Miniconda3-${MINICONDA_VERSION}-Linux-${CONDA_ARCH}.sh"
    fi
    
    INSTALLER_FILE="Miniconda3-installer.sh"
    
    print_info "下载地址: $DOWNLOAD_URL"
    print_info "正在下载..."
    
    if wget -O "$INSTALLER_FILE" "$DOWNLOAD_URL"; then
        print_success "Miniconda 下载完成"
    else
        print_error "下载失败"
        exit 1
    fi
}

# 安装 Miniconda
install_miniconda() {
    print_info "安装 Miniconda..."
    
    # 选择安装路径
    echo ""
    read -p "请输入安装路径 [默认: $HOME/miniconda3]: " INSTALL_PATH
    INSTALL_PATH=${INSTALL_PATH:-$HOME/miniconda3}
    
    print_info "安装路径: $INSTALL_PATH"
    
    # 检查路径是否存在
    if [[ -d "$INSTALL_PATH" ]]; then
        print_warning "目录已存在: $INSTALL_PATH"
        read -p "是否删除并重新安装? (y/N): " remove_existing
        if [[ $remove_existing =~ ^[Yy]$ ]]; then
            rm -rf "$INSTALL_PATH"
            print_success "已删除现有目录"
        else
            print_error "安装已取消"
            exit 1
        fi
    fi
    
    # 运行安装程序
    print_info "运行安装程序..."
    bash "$INSTALLER_FILE" -b -p "$INSTALL_PATH"
    
    # 清理安装文件
    rm -f "$INSTALLER_FILE"
    
    print_success "Miniconda 安装完成"
    
    # 初始化 conda
    print_info "初始化 conda..."
    "$INSTALL_PATH/bin/conda" init bash
    
    # 加载 conda 环境
    source "$HOME/.bashrc"
    
    print_success "conda 初始化完成"
}

# 配置 conda 源
configure_conda_channels() {
    print_info "配置 conda 镜像源..."
    
    echo ""
    echo "选择 conda 镜像源:"
    echo "1) 清华大学镜像 (推荐)"
    echo "2) 阿里云镜像"
    echo "3) 中国科技大学镜像"
    echo "4) 官方源"
    echo "5) 跳过配置"
    echo ""
    
    read -p "请选择 [1-5, 默认: 1]: " channel_choice
    channel_choice=${channel_choice:-1}
    
    case $channel_choice in
        1)
            print_info "配置清华大学镜像源..."
            conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
            conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free
            conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
            conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/pro
            conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2
            ;;
        2)
            print_info "配置阿里云镜像源..."
            conda config --add channels https://mirrors.aliyun.com/anaconda/pkgs/main
            conda config --add channels https://mirrors.aliyun.com/anaconda/pkgs/free
            conda config --add channels https://mirrors.aliyun.com/anaconda/pkgs/r
            ;;
        3)
            print_info "配置中国科技大学镜像源..."
            conda config --add channels https://mirrors.ustc.edu.cn/anaconda/pkgs/main
            conda config --add channels https://mirrors.ustc.edu.cn/anaconda/pkgs/free
            conda config --add channels https://mirrors.ustc.edu.cn/anaconda/pkgs/r
            ;;
        4)
            print_info "使用官方源"
            ;;
        5)
            print_info "跳过 conda 源配置"
            return
            ;;
        *)
            print_warning "无效选择，跳过配置"
            return
            ;;
    esac
    
    # 设置显示通道地址
    conda config --set show_channel_urls yes
    
    print_success "conda 镜像源配置完成"
}

# 配置 pip 源
configure_pip_mirrors() {
    print_info "配置 pip 镜像源..."
    
    echo ""
    echo "选择 pip 镜像源:"
    echo "1) 清华大学镜像 (推荐)"
    echo "2) 阿里云镜像"
    echo "3) 中国科技大学镜像"
    echo "4) 豆瓣镜像"
    echo "5) 腾讯云镜像"
    echo "6) 官方源"
    echo "7) 跳过配置"
    echo ""
    
    read -p "请选择 [1-7, 默认: 1]: " pip_choice
    pip_choice=${pip_choice:-1}
    
    case $pip_choice in
        1)
            PIP_MIRROR="https://pypi.tuna.tsinghua.edu.cn/simple"
            PIP_NAME="清华大学"
            ;;
        2)
            PIP_MIRROR="https://mirrors.aliyun.com/pypi/simple/"
            PIP_NAME="阿里云"
            ;;
        3)
            PIP_MIRROR="https://pypi.mirrors.ustc.edu.cn/simple/"
            PIP_NAME="中国科技大学"
            ;;
        4)
            PIP_MIRROR="https://pypi.douban.com/simple/"
            PIP_NAME="豆瓣"
            ;;
        5)
            PIP_MIRROR="https://mirrors.cloud.tencent.com/pypi/simple"
            PIP_NAME="腾讯云"
            ;;
        6)
            print_info "使用官方源"
            return
            ;;
        7)
            print_info "跳过 pip 源配置"
            return
            ;;
        *)
            print_warning "无效选择，跳过配置"
            return
            ;;
    esac
    
    print_info "配置 $PIP_NAME pip 镜像源..."
    
    # 创建 pip 配置目录
    mkdir -p ~/.pip
    
    # 写入配置
    cat > ~/.pip/pip.conf <<EOF
[global]
index-url = $PIP_MIRROR
trusted-host = ${PIP_MIRROR#https://}
trusted-host = ${PIP_MIRROR#http://}
EOF
    
    # 移除协议部分
    sed -i 's|https://||g' ~/.pip/pip.conf
    sed -i 's|http://||g' ~/.pip/pip.conf
    sed -i 's|/simple.*||g' ~/.pip/pip.conf
    
    # 重新写入正确格式
    cat > ~/.pip/pip.conf <<EOF
[global]
index-url = $PIP_MIRROR
[install]
trusted-host = $(echo $PIP_MIRROR | sed 's|https://||' | sed 's|http://||' | cut -d'/' -f1)
EOF
    
    print_success "pip 镜像源配置完成"
}

# 创建常用环境
create_common_environments() {
    print_info "创建常用 Python 环境..."
    
    read -p "是否创建数据科学环境? (包含 numpy, pandas, matplotlib) (y/N): " create_ds
    if [[ $create_ds =~ ^[Yy]$ ]]; then
        print_info "创建数据科学环境 'datascience'..."
        conda create -n datascience python=3.11 numpy pandas matplotlib scipy scikit-learn jupyter -y
        print_success "数据科学环境创建完成"
    fi
    
    read -p "是否创建深度学习环境? (包含 PyTorch) (y/N): " create_dl
    if [[ $create_dl =~ ^[Yy]$ ]]; then
        print_info "创建深度学习环境 'pytorch'..."
        conda create -n pytorch python=3.11 -y
        conda activate pytorch
        pip install torch torchvision torchaudio
        conda deactivate
        print_success "深度学习环境创建完成"
    fi
}

# 安装常用工具
install_common_tools() {
    print_info "安装常用 Python 工具..."
    
    read -p "是否在 base 环境安装常用工具? (y/N): " install_tools
    if [[ ! $install_tools =~ ^[Yy]$ ]]; then
        print_info "跳过工具安装"
        return
    fi
    
    print_info "安装常用工具包..."
    
    # 基础工具
    pip install --upgrade pip
    pip install ipython
    pip install jupyterlab
    pip install virtualenv
    
    # 开发工具
    read -p "是否安装开发工具? (pylint, black, pytest) (y/N): " install_dev
    if [[ $install_dev =~ ^[Yy]$ ]]; then
        pip install pylint black pytest pytest-cov
        print_success "开发工具安装完成"
    fi
    
    print_success "常用工具安装完成"
}

# 配置 conda 自动激活
configure_conda_autoactivate() {
    print_info "配置 conda 自动激活..."
    
    read -p "是否配置 conda 自动激活? (Y/n): " auto_activate
    auto_activate=${auto_activate:-Y}
    
    if [[ $auto_activate =~ ^[Yy]$ ]]; then
        # 默认情况下 conda init 已经配置了自动激活
        print_success "conda 将在新终端自动激活"
    else
        # 禁用自动激活
        conda config --set auto_activate_base false
        print_success "已禁用 conda 自动激活"
    fi
}

# 显示使用说明
show_usage() {
    echo ""
    print_success "==================== 安装完成 ===================="
    echo ""
    print_info "🎉 Python 环境配置完成！"
    echo ""
    print_info "📚 常用命令:"
    echo "  conda --version               # 查看 conda 版本"
    echo "  conda env list                # 列出所有环境"
    echo "  conda create -n myenv python=3.11  # 创建新环境"
    echo "  conda activate myenv          # 激活环境"
    echo "  conda deactivate              # 退出环境"
    echo "  conda install package         # 安装包"
    echo "  pip install package           # 使用 pip 安装包"
    echo ""
    print_info "📖 配置文件:"
    echo "  ~/.condarc                    # conda 配置"
    echo "  ~/.pip/pip.conf               # pip 配置"
    echo ""
    print_info "🔧 环境管理:"
    echo "  conda create -n name python=3.x    # 创建环境"
    echo "  conda remove -n name --all         # 删除环境"
    echo "  conda clean -a                     # 清理缓存"
    echo ""
    print_warning "⚠️  请运行 'source ~/.bashrc' 或重新打开终端来加载 conda"
    echo ""
    print_success "=================================================="
}

# 测试安装
test_installation() {
    print_info "测试 Python 环境..."
    
    # 测试 conda
    if command -v conda &> /dev/null; then
        print_success "conda 可用"
        conda --version
    else
        print_warning "conda 不可用，请重新打开终端"
    fi
    
    # 测试 Python
    if command -v python &> /dev/null; then
        PYTHON_VERSION=$(python --version 2>&1 | awk '{print $2}')
        print_success "Python 版本: $PYTHON_VERSION"
    fi
    
    # 测试 pip
    if command -v pip &> /dev/null; then
        PIP_VERSION=$(pip --version | awk '{print $2}')
        print_success "pip 版本: $PIP_VERSION"
    fi
    
    echo ""
    print_info "环境列表:"
    conda env list 2>/dev/null || print_warning "请重新打开终端后查看"
}

# 主菜单
show_menu() {
    echo ""
    echo "请选择要执行的操作:"
    echo ""
    echo "1) 完整安装 (推荐)"
    echo "   - 安装 Miniconda"
    echo "   - 配置镜像源"
    echo "   - 安装常用工具"
    echo ""
    echo "2) 仅安装 Miniconda"
    echo "3) 仅配置镜像源 (conda + pip)"
    echo "4) 创建常用环境"
    echo "5) 测试安装"
    echo "6) 退出"
    echo ""
}

# 完整安装
full_installation() {
    print_info "开始完整 Python 环境配置..."
    
    detect_architecture
    select_miniconda_version
    download_miniconda
    install_miniconda
    
    # 重新加载环境
    if [[ -f "$HOME/.bashrc" ]]; then
        source "$HOME/.bashrc"
    fi
    
    configure_conda_channels
    configure_pip_mirrors
    configure_conda_autoactivate
    install_common_tools
    create_common_environments
    test_installation
    show_usage
}

# 主函数
main() {
    print_banner
    
    # 如果提供了 --auto 参数，执行完整安装
    if [[ "$1" == "--auto" ]]; then
        if check_conda_installed; then
            print_warning "Conda 已安装"
            read -p "是否重新安装? (y/N): " reinstall
            if [[ ! $reinstall =~ ^[Yy]$ ]]; then
                print_info "退出脚本"
                exit 0
            fi
        fi
        full_installation
        exit 0
    fi
    
    # 检查 Conda 是否已安装
    check_conda_installed
    
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
                detect_architecture
                select_miniconda_version
                download_miniconda
                install_miniconda
                ;;
            3)
                if ! check_conda_installed; then
                    print_error "请先安装 Conda"
                else
                    configure_conda_channels
                    configure_pip_mirrors
                fi
                ;;
            4)
                if ! check_conda_installed; then
                    print_error "请先安装 Conda"
                else
                    create_common_environments
                fi
                ;;
            5)
                test_installation
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
