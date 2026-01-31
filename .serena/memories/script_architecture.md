# Script Architecture and Key Functions

## Core Scripts

### install_zsh_config.sh
- One-click installation and setup
- Dependency management (FZF, fd, ripgrep, Antigen)
- Cross-platform support
- Eliminates hardcoded paths (v2.1.1)

### zsh_launcher.sh
- Multi-mode startup: minimal (2ms), fast (0.6s), normal (1.5s)
- Performance benchmarking
- Configuration backup/restore

### zsh_optimizer.sh
- Performance analysis and optimization
- Commands: analyze, optimize, compare, restore, benchmark

### zsh_tools.sh
- Configuration management
- Commands: validate, backup, restore, update, doctor, benchmark, clean

## Function Modules

### context.zsh
- Environment detection (Docker, SSH, GPU)
- Prompt indicators (🖥️ 🌐 🔐)

### search.zsh
- Enhanced search: hg, hig, hrg, hirg

### utils.zsh (v2.1)
- Proxy management: proxy, unproxy, check_proxy, proxy_status

### help.zsh
- Unified help system

### performance.zsh
- Detailed performance analysis
- Millisecond-level precision

## Configuration Variants
- .zshrc: Standard (1.5s)
- .zshrc.optimized: Optimized (0.6s)
- .zshrc.ultra-optimized: Minimal (2ms)
- .zshrc.nvm-optimized: NVM-specific
- .zshrc.modular: Modular structure
