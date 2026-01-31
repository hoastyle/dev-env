# Changelog

All notable changes to the dev-env project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.0] - 2026-01-31

### Added

#### Template System
- Configuration template system with 4 preset templates
  - `dev-full.zshrc`: Full development environment (~1.5s startup, ~35MB)
  - `dev-minimal.zshrc`: Lightweight development (~100ms startup, ~20MB)
  - `server.zshrc`: Production server environment (~50ms startup, ~15MB)
  - `docker.zshrc`: Docker container optimized (~20ms startup, ~10MB)
- Interactive template selector tool (`scripts/zsh_template_selector.sh`)
- Template comparison and benchmarking features
- Custom template support in `templates/custom/` directory

#### Core Libraries
- `lib_platform_compat.sh`: Cross-platform compatibility layer
  - OS type detection (`get_os_type`, `is_macos`)
  - Cross-platform file operations (`get_file_size`, `get_timestamp_ms`)
  - Relative date calculation (`get_date_relative`)
  - macOS/Linux command differences abstraction
- `lib_logging.sh`: Structured logging system
  - 5 log levels (DEBUG, INFO, SUCCESS, WARN, ERROR)
  - Automatic log rotation (10MB threshold, 5 files retained)
  - Log viewing and management utilities
- `lib_performance.sh`: Performance monitoring and trend analysis
  - Startup time recording to CSV
  - Performance trend visualization
  - Regression detection (20% threshold)
  - Statistical analysis (avg, min, max, stddev)

#### Testing Infrastructure
- Complete unit test suite
  - `test_path_detection.sh`: Path detection and resolution tests
  - `test_error_handling.sh`: Error handling scenario tests
  - `test_config_validation.sh`: Configuration validation tests
- Performance testing suite
  - `test_startup_benchmark.sh`: Startup time measurement
  - `test_memory_usage.sh`: Memory usage analysis
- Test libraries
  - `lib/test_utils.sh`: Test framework utilities
  - `lib/assertions.sh`: Assertion functions
  - `lib/fixtures.sh`: Test fixtures

#### CI/CD Integration
- GitHub Actions workflow (`.github/workflows/test.yml`)
  - Multi-platform testing (Ubuntu, macOS)
  - Unit tests automation
  - Performance benchmarks
  - Script validation
  - Configuration syntax checks
  - Template system tests

### Changed

#### Script Updates
- `zsh_launcher.sh`: Integrated logging and performance libraries
- `zsh_tools.sh`: Added performance reporting commands
  - `perf-report`: Show performance trends for all modes
  - `perf-trend`: Show specific mode trend
  - `perf-info`: Display performance data information

#### Documentation
- Updated README.md with template system documentation
- Added `templates/README.md`: Template system guide
- Updated project structure section
- Enhanced version history

### Fixed

- Removed `export -f` statements that caused ZSH compatibility issues
- Fixed log file initialization by adding explicit `init_logging()` calls
- Corrected template selector script syntax error

### Security

- No security updates in this release

### Dependencies

- No new external dependencies added
- Python 3 or Perl required for millisecond timing (optional fallback)

## [2.1.1] - 2025-10-19

### Fixed
- Eliminated hardcoded paths for better portability
- Improved Antigen download with fallback sources
- Enhanced configuration file path detection mechanism
- Unified documentation version numbers

## [2.1.0] - 2025-10-17

### Added
- Proxy functionality enhancement
  - `check_proxy` command: Check proxy status
  - `proxy_status` command: Display complete proxy configuration
  - Configuration file management (`~/.proxy_config`)
  - Proxy availability validation (TCP connection test)
  - Custom proxy address support
- Complete documentation system (5 new documents, 1000+ lines)
  - Proxy optimization documentation
  - Quick reference guide
  - Integration guide
  - Enhancement summary
  - Documentation index

### Changed
- Reduced code duplication by 75% (from 60% to 15%)
- Improved proxy function modularity

## [2.0.0] - 2025-10-16

### Added
- Multi-mode launcher system
  - `zsh_launcher.sh`: Multi-mode ZSH launcher
  - `zsh_minimal.sh`: Minimal mode launcher
  - Three startup modes: minimal (2ms), fast (0.6s), normal (full)
- Performance optimization tools
  - `zsh_optimizer.sh`: Performance analysis and optimization
  - Detailed performance analysis system
  - High-precision segmented performance testing
- Lazy loading system
  - On-demand completion activation
  - On-demand development environment loading
- Backup and restore mechanism
  - Automatic configuration backup
  - Quick restore functionality

### Changed
- Major performance breakthrough: 99.9% startup speed improvement
- Identified and optimized ZSH completion bottleneck (437ms savings)

### Fixed
- Performance optimization for faster startup times

## [1.3.0] - 2025-10-16

### Added
- Detailed performance analysis system (`performance.zsh`)
- High-precision segmented performance testing (`benchmark-detailed` command)
- Performance scoring and optimization suggestions
- Plugin performance analysis
- Memory usage analysis
- Millisecond-precision timing (ZSH and Bash compatible)

## [1.2.0] - 2025-10-16

### Added
- Unified command help system (`help.zsh`)
- `--help` / `-h` parameter support for all custom commands
- Command discovery and categorization
- Detailed troubleshooting guide
- Help system validation in tests

### Changed
- Improved parameter checking and error messages

## [1.1.0] - 2025-10-15

### Added
- Modular function management system
- Environment detection module (`environment.zsh`)
- Search enhancement module (`search.zsh`)
- Utility functions module (`utils.zsh`)

### Fixed
- Installation script path issues

### Changed
- Improved documentation and usage guides

## [1.0.0] - 2025-10-15

### Added
- Initial release
- Complete ZSH configuration management
- Antigen plugin manager integration
- Development tool integration (FZF, fd, ripgrep)
- Automated installation and configuration tools
- Performance optimization and monitoring
- Docker environment support
- Comprehensive documentation

---

## Version Summary

| Version | Date | Key Features |
|---------|------|-------------|
| **2.2.0** | 2026-01-31 | Template system, core libraries, testing suite, CI/CD |
| **2.1.1** | 2025-10-19 | Portability fixes, hardcoded path elimination |
| **2.1.0** | 2025-10-17 | Proxy optimization, documentation system |
| **2.0.0** | 2025-10-16 | Multi-mode launcher, 99.9% performance boost |
| **1.3.0** | 2025-10-16 | Performance analysis system |
| **1.2.0** | 2025-10-16 | Unified help system |
| **1.1.0** | 2025-10-15 | Modular functions |
| **1.0.0** | 2025-10-15 | Initial release |

---

## Upgrade Guide

### From 2.1.x to 2.2.0

1. **Update your repository:**
   ```bash
   git pull origin master
   ```

2. **Optional: Try the new template system:**
   ```bash
   ./scripts/zsh_template_selector.sh list
   ```

3. **Optional: Run the test suite:**
   ```bash
   ./tests/unit/test_path_detection.sh
   ./tests/unit/test_config_validation.sh
   ```

4. **Existing configurations remain compatible** - no migration needed

### From 2.0.x to 2.1.x

1. **Update your repository:**
   ```bash
   git pull origin master
   ```

2. **Existing configurations remain compatible**

### From 1.x to 2.0.0

1. **Backup your current configuration:**
   ```bash
   ./scripts/zsh_tools.sh backup
   ```

2. **Update your repository:**
   ```bash
   git pull origin master
   ```

3. **Choose your startup mode:**
   ```bash
   ./scripts/zsh_launcher.sh normal    # Full features
   ./scripts/zsh_launcher.sh fast      # Balanced
   ./scripts/zsh_launcher.sh minimal   # Fastest
   ```

---

## Migration Notes

### Breaking Changes

**Version 2.0.0**:
- Default startup mode changed from "normal" to user-selectable
- Configuration files renamed (`.zshrc.optimized`, `.zshrc.ultra-optimized`)

**Version 1.0.0**:
- Initial stable release

### Deprecation Notices

None currently deprecated.

---

## Future Plans

See [docs/management/PLANNING.md](docs/management/PLANNING.md) for upcoming features and roadmap.
