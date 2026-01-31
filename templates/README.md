# ZSH Configuration Templates

This directory contains pre-configured ZSH templates for different use cases.

## Available Templates

### Development Templates

#### `dev/dev-full.zshrc`
- **Description**: Full-featured development environment
- **Features**:
  - Powerlevel10k theme
  - Complete Antigen plugin suite
  - FZF fuzzy search
  - Autojump directory navigation
  - Python/Conda/NVM environments
  - Custom functions integration
- **Startup Time**: ~1.5s
- **Use Case**: Daily development work with maximum productivity
- **Memory Usage**: ~35-50MB

#### `dev/dev-minimal.zshrc`
- **Description**: Lightweight development environment
- **Features**:
  - Simple prompt (no Powerlevel10k)
  - Lazy-loaded environments (Python, NVM, Conda)
  - Lazy-loaded FZF and Autojump
  - Essential development aliases
- **Startup Time**: ~50-100ms
- **Use Case**: Quick development tasks, scripting, resource-constrained systems
- **Memory Usage**: ~15-25MB

### Server Templates

#### `server/server.zshrc`
- **Description**: Production server environment
- **Features**:
  - Minimal prompt with exit status
  - System monitoring functions
  - Service management aliases
  - Docker helpers (if available)
  - Security utilities
  - Log viewing shortcuts
- **Startup Time**: ~20-50ms
- **Use Case**: Production servers, minimal resource usage
- **Memory Usage**: ~10-15MB

### Docker Templates

#### `docker/docker.zshrc`
- **Description**: Docker container optimized
- **Features**:
  - Ultra-minimal prompt
  - CI/CD friendly functions
  - Service wait utilities
  - Container resource monitoring
  - No completion by default (fastest startup)
- **Startup Time**: ~5-20ms
- **Use Case**: Docker containers, CI/CD pipelines
- **Memory Usage**: ~5-10MB

## Usage

### Interactive Template Selection

Use the template selector script:

```bash
./scripts/zsh_template_selector.sh
```

### Manual Template Application

```bash
# Apply a template
cp templates/dev/dev-full.zshrc ~/.zshrc

# Or with the selector
./scripts/zsh_template_selector.sh apply dev-full

# Preview a template
./scripts/zsh_template_selector.sh preview server
```

### Template Comparison

```bash
# Compare startup times
./scripts/zsh_template_selector.sh benchmark

# Compare features
./scripts/zsh_template_selector.sh compare
```

## Custom Templates

You can create custom templates in the `templates/custom/` directory:

```bash
mkdir -p templates/custom
cp templates/dev/dev-minimal.zshrc templates/custom/my-custom.zshrc
# Edit my-custom.zshrc to your needs
```

The template selector will automatically discover custom templates.

## Template Format

Templates should follow these conventions:

1. **Header**: Include template name, description, and use case
2. **Startup Time**: Indicate expected startup time
3. **Comments**: Clearly document each section
4. **Modularity**: Use lazy loading where appropriate
5. **Compatibility**: Support both macOS and Linux

## Template Variables

Templates can use the following special variables:

- `$DOCKER_ENV`: Set to `true` in Docker environments
- `$IN_CONTAINER`: Set to `true` when running inside a container
- `$FAST_MODE`: Set to `true` to skip heavy initialization
- `$ZSH_LAUNCHER_ACTIVE`: Set when using zsh_launcher.sh

## See Also

- `scripts/zsh_template_selector.sh` - Template selector tool
- `scripts/zsh_launcher.sh` - Multi-mode launcher
- `docs/CONFIG_LIFECYCLE_MANAGEMENT.md` - Configuration management guide
