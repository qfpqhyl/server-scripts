# Linux 性能优化脚本

## 概述

`optimize.sh` 提供全面的 Linux 系统性能优化，涵盖内核参数、网络、磁盘 I/O、内存管理等多个方面。

## 功能特性

### 1. 网络性能优化

- **TCP 缓冲区优化**: 提升网络吞吐量
- **连接队列优化**: 提升并发连接处理能力
- **TIME_WAIT 优化**: 减少端口占用
- **TCP Fast Open**: 减少连接建立时间
- **BBR 拥塞控制**: 提升带宽利用率

### 2. 文件系统优化

- **文件描述符限制**: 提升到 2097152
- **inotify 限制**: 优化文件监控性能
- **管道优化**: 提升进程间通信

### 3. 内存管理优化

- **Swap 优化**: 减少 swap 使用
- **脏页优化**: 优化磁盘写入
- **内存分配**: 优化内存分配策略

### 4. 磁盘 I/O 优化

- **调度器优化**: SSD 使用 none，HDD 使用 mq-deadline
- **I/O 队列**: 优化 I/O 队列深度

### 5. CPU 优化

- **频率调节器**: 设置为性能模式
- **进程限制**: 优化进程和线程数限制

### 6. 安全优化

- **SYN Cookies**: 防止 SYN Flood 攻击
- **连接保护**: 优化连接安全参数

## 使用方法

### 交互式优化

```bash
wget https://raw.githubusercontent.com/qfpqhyl/server-scripts/main/performance/optimize.sh
chmod +x optimize.sh
sudo ./optimize.sh
```

### 自动优化

```bash
sudo ./optimize.sh --auto
```

## 菜单选项

1. **完整优化（推荐）**: 执行所有优化
2. **仅优化内核参数**: 只优化内核参数
3. **仅优化文件描述符**: 只优化文件描述符限制
4. **仅优化磁盘 I/O**: 只优化磁盘调度器
5. **优化 CPU 性能**: 设置 CPU 性能模式
6. **优化网络接口**: 优化网络接口参数
7. **显示当前参数**: 查看当前系统参数
8. **性能测试**: 运行性能测试
9. **退出**

## 优化参数详解

### 网络参数

```bash
# TCP 缓冲区大小
net.core.rmem_max = 16777216          # 最大接收缓冲区 16MB
net.core.wmem_max = 16777216          # 最大发送缓冲区 16MB
net.ipv4.tcp_rmem = 4096 87380 16777216    # TCP 接收缓冲区
net.ipv4.tcp_wmem = 4096 65536 16777216    # TCP 发送缓冲区

# 连接队列
net.core.somaxconn = 8192             # 最大监听队列
net.ipv4.tcp_max_syn_backlog = 8192   # SYN 队列大小

# TCP 优化
net.ipv4.tcp_slow_start_after_idle = 0     # 禁用慢启动
net.ipv4.tcp_fin_timeout = 30              # FIN 超时时间
net.ipv4.tcp_tw_reuse = 1                  # 重用 TIME_WAIT
net.ipv4.tcp_fastopen = 3                  # 启用 TCP Fast Open

# BBR 拥塞控制
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
```

### 文件系统参数

```bash
# 文件描述符
fs.file-max = 2097152                 # 系统最大文件描述符
fs.nr_open = 2097152                  # 进程最大文件描述符

# inotify
fs.inotify.max_user_instances = 8192  # 最大实例数
fs.inotify.max_user_watches = 524288  # 最大监控数

# 管道
fs.pipe-max-size = 1048576            # 最大管道大小
```

### 内存参数

```bash
# Swap
vm.swappiness = 10                    # 降低 swap 使用

# 脏页
vm.dirty_ratio = 20                   # 脏页比例
vm.dirty_background_ratio = 10        # 后台写回比例
vm.dirty_expire_centisecs = 3000      # 脏页过期时间
vm.dirty_writeback_centisecs = 500    # 写回间隔

# 内存分配
vm.overcommit_memory = 1              # 允许内存过度分配
vm.min_free_kbytes = 65536            # 最小空闲内存
```

### 进程参数

```bash
# 进程限制
kernel.pid_max = 4194304              # 最大进程 ID
kernel.threads-max = 2097152          # 最大线程数
```

### 用户限制

```bash
# 文件描述符
* soft nofile 1048576
* hard nofile 1048576

# 进程数
* soft nproc 65535
* hard nproc 65535

# 内存锁定
* soft memlock unlimited
* hard memlock unlimited
```

## 性能测试

### 网络性能测试

使用 iperf3 测试网络性能：

```bash
# 服务器端
iperf3 -s

# 客户端
iperf3 -c <server_ip> -t 30 -P 10
```

### 磁盘性能测试

```bash
# 写入测试
dd if=/dev/zero of=/tmp/test bs=1M count=1024 conv=fdatasync

# 读取测试
dd if=/tmp/test of=/dev/null bs=1M

# 随机读写测试（需要安装 fio）
fio --name=random-rw --ioengine=libaio --rw=randrw --bs=4k --size=1G --numjobs=4 --runtime=60 --time_based --group_reporting
```

### CPU 性能测试

```bash
# 安装 sysbench
sudo apt-get install sysbench  # Ubuntu/Debian
sudo yum install sysbench      # CentOS/RHEL

# CPU 测试
sysbench cpu --cpu-max-prime=20000 run
```

## 查看当前参数

```bash
# 查看所有内核参数
sysctl -a

# 查看特定参数
sysctl net.ipv4.tcp_congestion_control
sysctl vm.swappiness
sysctl fs.file-max

# 查看用户限制
ulimit -a

# 查看当前文件描述符使用
cat /proc/sys/fs/file-nr
```

## 应用配置

### 临时应用（重启后失效）

```bash
# 应用单个参数
sudo sysctl -w net.ipv4.tcp_tw_reuse=1

# 应用配置文件
sudo sysctl -p /etc/sysctl.d/99-performance.conf
```

### 永久应用

配置会写入到：
- `/etc/sysctl.d/99-performance.conf` - 内核参数
- `/etc/security/limits.conf` - 用户限制

重启系统或重新登录后自动生效。

## 验证优化效果

### 网络优化验证

```bash
# 查看 TCP 拥塞控制算法
sysctl net.ipv4.tcp_congestion_control

# 查看连接队列
ss -lnt

# 查看网络统计
netstat -s | grep -E "connections|segments"
```

### 文件系统验证

```bash
# 查看文件描述符使用
cat /proc/sys/fs/file-nr

# 查看当前进程限制
ulimit -n
```

### 内存验证

```bash
# 查看 swap 使用
free -h

# 查看脏页信息
cat /proc/vmstat | grep dirty
```

## 适用场景

### 高并发 Web 服务器

- 优化网络参数
- 增加文件描述符
- 优化 TCP 连接处理

### 数据库服务器

- 增加文件描述符
- 优化内存管理
- 优化磁盘 I/O

### 计算密集型服务器

- 优化 CPU 性能
- 减少 swap 使用
- 优化进程调度

### 存储服务器

- 优化磁盘 I/O
- 优化文件系统
- 增加缓存

## 注意事项

1. **备份重要**: 脚本会自动备份配置，建议保留备份

2. **测试环境**: 建议先在测试环境验证效果

3. **监控观察**: 应用后监控系统运行状况

4. **谨慎调整**: 参数设置过大可能导致资源耗尽

5. **重启生效**: 某些参数需要重启系统才能完全生效

## 回滚配置

### 恢复内核参数

```bash
# 查找备份
ls -la /root/performance_backup_*

# 恢复配置
sudo cp /root/performance_backup_*/sysctl.conf.bak /etc/sysctl.conf

# 删除优化配置
sudo rm /etc/sysctl.d/99-performance.conf

# 应用
sudo sysctl -p
```

### 恢复用户限制

```bash
# 恢复配置
sudo cp /root/performance_backup_*/limits.conf.bak /etc/security/limits.conf

# 重新登录生效
```

## 故障排除

### 参数应用失败

某些参数可能因内核版本不支持而失败：

```bash
# 查看失败的参数
sudo sysctl -p /etc/sysctl.d/99-performance.conf

# 注释掉不支持的参数
sudo vim /etc/sysctl.d/99-performance.conf
```

### BBR 不可用

BBR 需要内核版本 ≥ 4.9：

```bash
# 查看内核版本
uname -r

# 如果版本过低，升级内核或使用其他算法
sudo sysctl -w net.ipv4.tcp_congestion_control=cubic
```

### 系统不稳定

如果优化后系统不稳定：

1. 回滚到备份配置
2. 逐步应用优化
3. 监控系统表现
4. 根据实际情况调整参数

## 监控工具推荐

- **htop**: 系统监控
- **iotop**: 磁盘 I/O 监控
- **nethogs**: 网络流量监控
- **vmstat**: 虚拟内存统计
- **iostat**: I/O 统计
- **sar**: 系统活动报告

## 参考资料

- [Linux 内核文档](https://www.kernel.org/doc/Documentation/)
- [sysctl 文档](https://www.kernel.org/doc/Documentation/sysctl/)
- [TCP 性能优化](https://www.kernel.org/doc/Documentation/networking/ip-sysctl.txt)
