# 代理功能快速参考指南

## 🚀 快速开始

### 1. 启用代理
```bash
proxy                    # 使用默认配置启用
proxy 127.0.0.1:7890    # 使用自定义地址
proxy 127.0.0.1:7890 -v # 启用并验证连接
```

### 2. 检查状态
```bash
check_proxy              # 快速检查 (输出: ✅/❌)
check_proxy -s          # 显示详细状态
proxy_status            # 显示完整配置信息
```

### 3. 禁用代理
```bash
unproxy                 # 清除所有代理变量
```

---

## 📋 命令速查表

| 命令 | 功能 | 示例 |
|------|------|------|
| `proxy` | 启用代理 | `proxy 127.0.0.1:7890 --verify` |
| `unproxy` | 禁用代理 | `unproxy` |
| `check_proxy` | 检查状态 | `check_proxy --status` |
| `proxy_status` | 详细信息 | `proxy_status` |

---

## 💡 常用场景

### 场景 1：启用默认代理
```bash
$ proxy
✅ 代理已启用
   地址: http://127.0.0.1:7890
   NO_PROXY: localhost,127.0.0.1,.local,*.local
```

### 场景 2：使用 V2Ray 代理
```bash
$ proxy 127.0.0.1:10808
✅ 代理已启用
   地址: http://127.0.0.1:10808
   NO_PROXY: localhost,127.0.0.1,.local,*.local
```

### 场景 3：验证代理连接
```bash
$ proxy 127.0.0.1:7890 --verify
✅ 代理已启用
   地址: http://127.0.0.1:7890
   NO_PROXY: localhost,127.0.0.1,.local,*.local

✅ 127.0.0.1:7890 连接正常
```

### 场景 4：查看完整代理配置
```bash
$ proxy_status

📊 代理状态信息：
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🟢 代理状态: 已启用
   http_proxy: http://127.0.0.1:7890
   https_proxy: http://127.0.0.1:7890
   all_proxy: http://127.0.0.1:7890

⚙️  默认配置:
   代理地址: 127.0.0.1:7890
   NO_PROXY: localhost,127.0.0.1,.local,*.local

🔍 代理服务可用性检测:
   ✅ 127.0.0.1:7890 连接正常
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 场景 5：禁用代理
```bash
$ unproxy
❌ 代理已禁用
```

---

## ⚙️ 配置文件 (~/.proxy_config)

### 默认内容
```bash
# Proxy Configuration File
PROXY_ADDRESS=127.0.0.1:7890
NO_PROXY_LIST=localhost,127.0.0.1,.local,*.local
PROXY_TIMEOUT=3
```

### 修改配置
```bash
# 编辑配置文件
nano ~/.proxy_config

# 改为使用 V2Ray
PROXY_ADDRESS=127.0.0.1:10808

# 保存后，下次使用 proxy 命令会应用新配置
proxy    # 使用新的 10808 端口
```

---

## 🔍 命令选项详解

### `proxy` 命令
```bash
proxy [host:port] [--verify|-v]

参数说明：
  [host:port]  可选，自定义代理地址 (e.g., 127.0.0.1:7890)
  --verify     可选，验证代理服务是否可用
  -v           同上，简写形式

示例：
  proxy                           # 使用配置文件
  proxy 127.0.0.1:7890            # 自定义地址
  proxy 192.168.1.1:1080 --verify # 自定义地址并验证
```

### `check_proxy` 命令
```bash
check_proxy [--status|-s]

参数说明：
  --status     显示详细状态信息
  -s           同上，简写形式

示例：
  check_proxy         # 快速检查
  check_proxy -s      # 显示详细信息
```

### `proxy_status` 命令
```bash
proxy_status

功能：显示完整的代理配置和可用性检测结果

输出包括：
  - 当前代理状态 (已启用/未启用)
  - 所有代理环境变量值
  - 默认配置信息
  - 代理服务可用性检测结果
```

### `unproxy` 命令
```bash
unproxy

功能：清除所有代理相关环境变量

清除变量：
  - http_proxy / HTTP_PROXY
  - https_proxy / HTTPS_PROXY
  - all_proxy / ALL_PROXY
  - ftp_proxy / FTP_PROXY
  - no_proxy / NO_PROXY
```

---

## 🆘 故障排除

### 问题 1：代理连接失败
```bash
# 验证代理地址
$ proxy 127.0.0.1:7890 --verify
❌ 127.0.0.1:7890 连接超时或拒绝

# 解决方案：
# 1. 检查代理服务是否运行
# 2. 确认代理地址和端口正确
# 3. 检查防火墙设置
```

### 问题 2：环境变量未设置
```bash
# 检查代理是否启用
$ check_proxy
❌ 代理未启用

# 解决方案：
proxy 127.0.0.1:7890    # 重新启用代理
```

### 问题 3：配置文件不存在
```bash
# 首次使用会自动创建
$ proxy
# ~/.proxy_config 会被自动创建
# 如需修改默认值，编辑该文件
```

### 问题 4：查看帮助信息
```bash
# 查看所有代理命令帮助
zsh_help 实用工具

# 查看具体命令帮助
zsh_help proxy
zsh_help check_proxy
zsh_help proxy_status
zsh_help unproxy
```

---

## 📚 相关命令

### 查看环境变量
```bash
# 查看代理相关环境变量
echo $http_proxy
echo $https_proxy
echo $no_proxy

# 或查看所有代理变量
env | grep -i proxy
```

### 测试代理连接
```bash
# 使用 curl 测试代理
curl -x http://127.0.0.1:7890 https://www.google.com

# 使用 wget 测试代理
wget -e http_proxy=127.0.0.1:7890 https://www.google.com
```

### 检查代理可用性
```bash
# 尝试连接代理服务
timeout 3 bash -c "echo > /dev/tcp/127.0.0.1/7890" && echo "Connected" || echo "Failed"
```

---

## 🎯 最佳实践

### 1. 定期检查代理状态
```bash
# 工作开始时检查
check_proxy --status

# 发现问题时查看详细信息
proxy_status
```

### 2. 验证代理配置
```bash
# 修改配置后验证
proxy 127.0.0.1:7890 --verify
```

### 3. 使用配置文件管理多个代理
```bash
# ~/.proxy_config
# 快速修改 PROXY_ADDRESS，重新启用即可
PROXY_ADDRESS=127.0.0.1:7890   # Clash
PROXY_ADDRESS=127.0.0.1:10808  # V2Ray
```

### 4. 脚本中使用代理
```bash
# 脚本开始
proxy 127.0.0.1:7890

# 执行需要代理的命令
curl https://api.example.com

# 脚本结束
unproxy
```

---

## 🔗 关键文件

| 文件 | 用途 |
|------|------|
| `~/.proxy_config` | 代理配置文件 |
| `zsh-functions/utils.zsh` | 代理功能实现 |
| `zsh-functions/help.zsh` | 帮助系统 |
| `PROXY_OPTIMIZATION.md` | 详细优化文档 |

---

## 📞 快速帮助

```bash
# 查看所有命令
zsh_help

# 查看代理相关命令
zsh_help 实用工具

# 查看具体命令帮助
proxy --help
check_proxy --help
proxy_status --help
unproxy --help

# 或
zsh_help proxy
zsh_help check_proxy
zsh_help proxy_status
zsh_help unproxy
```

---

## 📊 版本信息

- **版本**: 2.1
- **更新日期**: 2025-10-17
- **维护者**: Development Team
- **状态**: ✅ 生产就绪
