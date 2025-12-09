# Python 环境配置脚本

## 概述

`setup_python.sh` 使用 Miniconda 提供完整的 Python 环境管理解决方案，特别针对国内网络环境优化。

## 功能特性

### 1. Miniconda 安装

- 支持多个 Python 版本（3.9-3.11）
- 自动检测系统架构（x86_64, aarch64）
- 从国内镜像源下载，速度快
- 自动初始化 shell 环境

### 2. 镜像源配置

#### conda 镜像源

| 镜像源 | 地址 | 说明 |
|--------|------|------|
| 清华大学 | `mirrors.tuna.tsinghua.edu.cn` | 推荐 |
| 阿里云 | `mirrors.aliyun.com` | 稳定 |
| 中科大 | `mirrors.ustc.edu.cn` | 教育网友好 |

#### pip 镜像源

| 镜像源 | 地址 | 说明 |
|--------|------|------|
| 清华大学 | `pypi.tuna.tsinghua.edu.cn` | 推荐 |
| 阿里云 | `mirrors.aliyun.com/pypi` | 稳定 |
| 中科大 | `pypi.mirrors.ustc.edu.cn` | 教育网友好 |
| 豆瓣 | `pypi.douban.com` | 老牌 |
| 腾讯云 | `mirrors.cloud.tencent.com/pypi` | 快速 |

### 3. 预配置环境

- **数据科学环境**: numpy, pandas, matplotlib, scipy, scikit-learn, jupyter
- **深度学习环境**: PyTorch
- **基础工具**: ipython, jupyterlab, virtualenv

### 4. 开发工具

- pylint: 代码检查
- black: 代码格式化
- pytest: 单元测试

## 使用方法

### 交互式安装

```bash
wget https://raw.githubusercontent.com/qfpqhyl/server-scripts/main/python/setup_python.sh
chmod +x setup_python.sh
./setup_python.sh
```

### 自动安装

```bash
./setup_python.sh --auto
```

## 菜单选项

1. **完整安装（推荐）**: Miniconda + 镜像源 + 工具
2. **仅安装 Miniconda**: 只安装 Miniconda
3. **仅配置镜像源**: 只配置 conda 和 pip 镜像
4. **创建常用环境**: 创建数据科学/深度学习环境
5. **测试安装**: 验证安装是否成功
6. **退出**

## conda 常用命令

### 环境管理

```bash
# 列出所有环境
conda env list

# 创建新环境
conda create -n myenv python=3.11

# 创建环境并安装包
conda create -n myenv python=3.11 numpy pandas

# 激活环境
conda activate myenv

# 退出环境
conda deactivate

# 删除环境
conda remove -n myenv --all

# 克隆环境
conda create -n newenv --clone myenv

# 导出环境
conda env export > environment.yml

# 从文件创建环境
conda env create -f environment.yml
```

### 包管理

```bash
# 搜索包
conda search package

# 安装包
conda install package

# 安装指定版本
conda install package=1.2.3

# 更新包
conda update package

# 更新所有包
conda update --all

# 删除包
conda remove package

# 列出已安装的包
conda list

# 清理缓存
conda clean -a
```

## pip 常用命令

```bash
# 安装包
pip install package

# 安装指定版本
pip install package==1.2.3

# 从 requirements.txt 安装
pip install -r requirements.txt

# 升级包
pip install --upgrade package

# 卸载包
pip uninstall package

# 列出已安装的包
pip list

# 显示包信息
pip show package

# 导出依赖
pip freeze > requirements.txt

# 搜索包
pip search package
```

## 预配置环境使用

### 数据科学环境

```bash
# 激活环境
conda activate datascience

# 启动 Jupyter Lab
jupyter lab

# 或启动 Jupyter Notebook
jupyter notebook
```

### 深度学习环境

```bash
# 激活环境
conda activate pytorch

# 验证 PyTorch 安装
python -c "import torch; print(torch.__version__); print(torch.cuda.is_available())"

# 安装额外包
pip install tensorboard matplotlib seaborn
```

## 配置文件

### .condarc

位置：`~/.condarc`

示例配置：

```yaml
channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
show_channel_urls: true
```

### pip.conf

位置：`~/.pip/pip.conf`

示例配置：

```ini
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
[install]
trusted-host = pypi.tuna.tsinghua.edu.cn
```

## 常见使用场景

### 数据分析项目

```bash
# 创建项目环境
conda create -n data_project python=3.11 numpy pandas matplotlib seaborn

# 激活环境
conda activate data_project

# 安装额外工具
pip install jupyter scikit-learn

# 启动 Jupyter
jupyter notebook
```

### 机器学习项目

```bash
# 创建环境
conda create -n ml_project python=3.11

# 激活环境
conda activate ml_project

# 安装 PyTorch
pip install torch torchvision torchaudio

# 安装其他库
pip install scikit-learn pandas numpy matplotlib seaborn

# 安装 Jupyter
pip install jupyter jupyterlab
```

### Web 开发项目

```bash
# 创建环境
conda create -n web_project python=3.11

# 激活环境
conda activate web_project

# 安装 Flask
pip install flask flask-sqlalchemy flask-migrate

# 或安装 Django
pip install django djangorestframework
```

## 故障排除

### conda 命令不可用

```bash
# 重新初始化
~/miniconda3/bin/conda init bash

# 重新加载配置
source ~/.bashrc

# 或重新打开终端
```

### 包安装失败

```bash
# 清理缓存
conda clean -a

# 更新 conda
conda update conda

# 尝试使用 pip
pip install package
```

### 环境冲突

```bash
# 创建新的干净环境
conda create -n clean_env python=3.11

# 激活并测试
conda activate clean_env
```

### 镜像源速度慢

尝试更换其他镜像源：

```bash
# 清除现有配置
conda config --remove-key channels

# 添加新镜像源（例如阿里云）
conda config --add channels https://mirrors.aliyun.com/anaconda/pkgs/main
conda config --add channels https://mirrors.aliyun.com/anaconda/pkgs/free
conda config --set show_channel_urls yes
```

## 最佳实践

1. **为每个项目创建独立环境**
   ```bash
   conda create -n project_name python=3.11
   ```

2. **使用 requirements.txt 管理依赖**
   ```bash
   pip freeze > requirements.txt
   ```

3. **定期清理缓存**
   ```bash
   conda clean -a
   ```

4. **使用 environment.yml 共享环境**
   ```bash
   conda env export > environment.yml
   ```

5. **保持 conda 和包更新**
   ```bash
   conda update conda
   conda update --all
   ```

## 卸载 Miniconda

```bash
# 删除 Miniconda 目录
rm -rf ~/miniconda3

# 删除配置文件
rm -rf ~/.conda
rm -f ~/.condarc

# 删除 shell 初始化代码
# 编辑 ~/.bashrc，删除 conda init 添加的代码
```

## 参考资料

- [Conda 官方文档](https://docs.conda.io/)
- [Miniconda 下载](https://docs.conda.io/en/latest/miniconda.html)
- [pip 官方文档](https://pip.pypa.io/)
- [清华大学镜像站](https://mirrors.tuna.tsinghua.edu.cn/)
