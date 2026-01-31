---
title: "文档导航"
description: "项目文档的总体导航和快速参考"
type: "教程"
status: "完成"
priority: "中"
created_date: "2025-11-11"
last_updated: "2025-01-31"
tags: ["导航", "文档中心"]
version: "2.0"
---

# 文档中心 (Documentation Center)

欢迎来到 dev-env 项目的完整文档中心。本目录包含所有主要功能模块的详细文档。

---

## 📚 文档分类

### 🏗️ [项目管理文档](management/)

项目管理相关的文档，包括产品需求、技术规划、任务追踪等。

**关键文档**:
* [产品需求文档 (PRD)](management/PRD.md) - 产品功能和需求说明
* [技术架构规划 (PLANNING)](management/PLANNING.md) - 技术架构和实施计划
* [任务追踪 (TASK)](management/TASK.md) - 开发任务和进度追踪
* [Agent 配置 (AGENTS)](management/AGENTS.md) - Claude Agent 配置说明
* [MCP 配置 (MCP_SETUP)](management/MCP_SETUP.md) - Model Context Protocol 设置

### 🌍 [环境指示符功能](ENVIRONMENT_INDICATORS_IMPLEMENTATION_JOURNEY.md)

在 ZSH 提示符中显示环境上下文信息（容器状态、SSH 状态、代理状态）的完整实现记录。

**功能特性**:

* 🖥️/🐳: 物理主机/Docker 容器状态
* 🌐/🏠: SSH/本地会话状态
* 🔐: 代理启用状态
* 显示在 Powerlevel10k 第一行右侧
* 一键安装，自动配置

**关键文档**:

* [全程实现记录](ENVIRONMENT_INDICATORS_IMPLEMENTATION_JOURNEY.md) - 8个提交的完整开发过程
* [设置指南](P10K_ENV_INDICATORS_SETUP.md) - Powerlevel10k 集成指南
* [技术知识库](KNOWLEDGE_BASE.md) - 可复用的技术模式
* [技术决策](ADRs/001-powerlevel10k-integration.md) - ADR 格式的决策记录

### 🔧 [代理功能文档](proxy/)

dev-env v2.1 代理功能的完整文档，包括优化说明、快速参考、集成指南等。

**适合人群**: 所有需要配置网络代理的用户

**关键文档**:

* [快速参考](proxy/PROXY_QUICK_REFERENCE.md) - 5 分钟快速上手
* [优化说明](proxy/PROXY_OPTIMIZATION.md) - 深入了解优化原理
* [集成指南](proxy/PROXY_INTEGRATION_GUIDE.md) - 系统集成和部署
* [完成报告](proxy/PROXY_ENHANCEMENT_SUMMARY.md) - 项目成果统计

[→ 进入代理功能文档](proxy/)

### 🎨 [ZSH 配置文档](zsh-config/)

ZSH Shell 环境配置、性能优化、故障排除的完整指南。

**适合人群**: ZSH 配置管理者、系统管理员、性能优化人员

**关键文档**:

* [性能优化指南](zsh-config/PERFORMANCE_OPTIMIZATION_GUIDE.md) - 启动速度优化技术
* [配置分析](zsh-config/ZSH_CONFIG_ANALYSIS.md) - 深度配置架构分析
* [配置模板](zsh-config/ZSH_CONFIG_TEMPLATE.md) - 配置模板和最佳实践
* [故障排除](zsh-config/TROUBLESHOOTING_DEBUG_GUIDE.md) - 问题诊断和修复
* [性能优化](zsh-config/PERFORMANCE_OPTIMIZATION_GUIDE.md) - 性能分析和优化策略

[→ 进入 ZSH 配置文档](zsh-config/)

---

## 🎯 按用户类型快速导航

### 👤 **我是第一次使用 dev-env**

1. 查看 [项目主文档](../README.md)
2. 根据需求选择：
   * 需要代理功能 → [代理快速参考](proxy/PROXY_QUICK_REFERENCE.md)
   * 需要配置 ZSH → [ZSH 配置模板](zsh-config/ZSH_CONFIG_TEMPLATE.md)

### 🔧 **我需要集成和部署**

* [代理集成指南](proxy/PROXY_INTEGRATION_GUIDE.md) - 代理功能集成
* [ZSH 配置分析](zsh-config/ZSH_CONFIG_ANALYSIS.md) - 了解现有配置

### 🛠️ **我需要故障排除**

* [代理功能快速参考](proxy/PROXY_QUICK_REFERENCE.md) - 代理相关问题
* [ZSH 故障排除指南](zsh-config/TROUBLESHOOTING_DEBUG_GUIDE.md) - ZSH 相关问题

### 📊 **我需要性能优化**

* [ZSH 性能优化指南](zsh-config/PERFORMANCE_OPTIMIZATION_GUIDE.md)
* [代理优化说明](proxy/PROXY_OPTIMIZATION.md)

### 🏗️ **我是项目维护者**

* 所有文档清单见下方
* [项目开发指南](../CLAUDE.md) - 开发标准和规范

---

## 📋 完整文档清单

### 代理功能 (proxy/)

| 文档 | 大小 | 用途 |
|------|------|------|
| [PROXY_QUICK_REFERENCE.md](proxy/PROXY_QUICK_REFERENCE.md) | 6.3 KB | 快速参考和常用示例 |
| [PROXY_OPTIMIZATION.md](proxy/PROXY_OPTIMIZATION.md) | 8.6 KB | 优化原理和方法论 |
| [PROXY_INTEGRATION_GUIDE.md](proxy/PROXY_INTEGRATION_GUIDE.md) | 8.6 KB | 集成部署和验证 |
| [PROXY_ENHANCEMENT_SUMMARY.md](proxy/PROXY_ENHANCEMENT_SUMMARY.md) | 12 KB | 完成报告和统计 |
| [README.md](proxy/README.md) | - | 代理模块导航 |

### ZSH 配置 (zsh-config/)

| 文档 | 用途 |
|------|------|
| [ZSH_CONFIG_ANALYSIS.md](zsh-config/ZSH_CONFIG_ANALYSIS.md) | 配置架构分析 |
| [ZSH_CONFIG_TEMPLATE.md](zsh-config/ZSH_CONFIG_TEMPLATE.md) | 配置模板和使用指南 |
| [TROUBLESHOOTING_DEBUG_GUIDE.md](zsh-config/TROUBLESHOOTING_DEBUG_GUIDE.md) | 问题诊断和修复 |
| [PERFORMANCE_OPTIMIZATION_GUIDE.md](zsh-config/PERFORMANCE_OPTIMIZATION_GUIDE.md) | 性能优化策略 |
| [README.md](zsh-config/README.md) | ZSH 模块导航 |

### 项目管理 (management/)

| 文档 | 用途 |
|------|------|
| [PRD.md](management/PRD.md) | 产品需求文档 |
| [PLANNING.md](management/PLANNING.md) | 技术架构规划 |
| [TASK.md](management/TASK.md) | 任务追踪 |
| [AGENTS.md](management/AGENTS.md) | Claude Agent 配置 |
| [MCP_SETUP.md](management/MCP_SETUP.md) | MCP 协议设置 |

### 其他文档

| 文档 | 用途 |
|------|------|
| [ENVIRONMENT_INDICATORS_IMPLEMENTATION_JOURNEY.md](ENVIRONMENT_INDICATORS_IMPLEMENTATION_JOURNEY.md) | 环境指示符实现记录 |
| [MODULAR_CONFIG.md](MODULAR_CONFIG.md) | 模块化配置系统 |
| [KNOWLEDGE_BASE.md](KNOWLEDGE_BASE.md) | 技术知识库 |
| [REFERENCE_ANALYSIS.md](REFERENCE_ANALYSIS.md) | 参考资料分析 |
| [RELEASE_NOTES.md](RELEASE_NOTES.md) | 版本发布说明 |
| [TEST_SUITE_PLAN.md](TEST_SUITE_PLAN.md) | 测试计划 |

### 存档文档 (archive/)

历史文档和临时报告存档，包括：
* 配置生命周期管理架构文档
* 文档维护报告
* 集成测试完成报告
* 任务历史记录

---

## 🔗 相关链接

* [项目主文档](../README.md) - 项目概述和快速开始
* [文档总索引](DOCUMENTATION_INDEX.md) - 全项目文档索引
* [开发指南](../CLAUDE.md) - 项目开发规范和指南
* [变更日志](../CHANGELOG.md) - 版本变更历史

---

## 📖 文档结构说明

```
docs/
├── README.md (本文件 - 文档中心)
├── DOCUMENTATION_INDEX.md (文档总索引)
├── management/ (项目管理文档)
│   ├── PRD.md (产品需求)
│   ├── PLANNING.md (技术规划)
│   ├── TASK.md (任务追踪)
│   ├── AGENTS.md (Agent配置)
│   └── MCP_SETUP.md (MCP设置)
├── proxy/ (代理功能相关文档)
│   ├── README.md (代理模块导航)
│   ├── PROXY_QUICK_REFERENCE.md
│   ├── PROXY_OPTIMIZATION.md
│   ├── PROXY_INTEGRATION_GUIDE.md
│   └── PROXY_ENHANCEMENT_SUMMARY.md
├── zsh-config/ (ZSH 配置相关文档)
│   ├── README.md (ZSH 模块导航)
│   ├── ZSH_CONFIG_ANALYSIS.md
│   ├── ZSH_CONFIG_TEMPLATE.md
│   ├── TROUBLESHOOTING_DEBUG_GUIDE.md
│   └── PERFORMANCE_OPTIMIZATION_GUIDE.md
├── ADRs/ (架构决策记录)
├── archive/ (历史文档存档)
└── (其他功能模块文档)
```

---

## 💡 文档使用建议

1. **首次使用**: 从相应模块的 README.md 开始
2. **快速查阅**: 使用快速参考文档
3. **深度学习**: 阅读优化说明和分析文档
4. **问题解决**: 参考故障排除指南
5. **性能优化**: 查看性能优化指南

---

**最后更新**: 2025-01-31
**文档版本**: 2.0
**维护者**: Development Team
