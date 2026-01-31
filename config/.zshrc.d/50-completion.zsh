# ===============================================
# ZSH Completion System (Cached)
# ===============================================
# Description: Optimized completion system with caching

_dev_env_init_completion() {
    setopt LOCAL_OPTIONS EXTENDED_GLOB
    autoload -Uz compinit
    zmodload zsh/stat 2>/dev/null || true

    local cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/dev-env"
    local dump_file="${cache_root}/zcompdump-${HOST}-${ZSH_VERSION}"
    local dump_ttl=${ZSH_COMPDUMP_TTL:-86400}

    [[ -d "${cache_root}" ]] || mkdir -p "${cache_root}"

    local -a compinit_args
    compinit_args=(-d "${dump_file}")

    if [[ -s "${dump_file}" ]]; then
        local -a dump_stat
        if zstat -A dump_stat +mtime -- "${dump_file}" 2>/dev/null; then
            if (( EPOCHSECONDS - dump_stat[1] < dump_ttl )); then
                compinit_args=(-C "${compinit_args[@]}")
            fi
        fi
    fi

    if [[ "${compinit_args[1]}" != "-C" ]]; then
        local -a insecure_dirs
        insecure_dirs=(${(@f)$(compaudit 2>/dev/null)})
        if (( ${#insecure_dirs} )); then
            compinit_args=(-i "${compinit_args[@]}")
        fi
    fi

    compinit "${compinit_args[@]}"
}

_dev_env_init_completion
unset -f _dev_env_init_completion
