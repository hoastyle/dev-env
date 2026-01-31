# ===============================================
# Matrix iCrane2 Navigation Functions (Optional)
# ===============================================
# Description: Quick navigation to Matrix/iCrane2 project directories
# Requires: .zshrc.matrix file in home directory
# To enable: Copy .zshrc.matrix to your home directory

# Get current running crane instance directory
_get_crane_run_dir() {
    # Method 1: Get from iCraneMonitor.sh process (most reliable)
    local monitor_cmd=$(pgrep -af 'iCraneMonitor.sh' 2>/dev/null | head -1 | grep -o '/home/ubuntu/matrix/icrane[^ ]*')
    if [ -n "$monitor_cmd" ]; then
        # Check if the path already ends with build/Debug/install/bin
        if [[ "$monitor_cmd" =~ "build/Debug/install/bin" ]]; then
            echo "$monitor_cmd"
        else
            echo "${monitor_cmd}/build/Debug/install/bin"
        fi
        return 0
    fi

    # Method 2: Get from crane process cwd (most reliable fallback)
    local crane_pid=$(pgrep -f 'crane --' | head -1)
    if [ -n "$crane_pid" ]; then
        ls -l /proc/$crane_pid/cwd 2>/dev/null | awk '{print $NF}'
        return 0
    fi

    # Method 3: Get from crane process exe path
    local crane_exe=$(pgrep -f 'crane --' | head -1 | xargs -I {} ls -l /proc/{}/exe 2>/dev/null | awk '{print $NF}')
    if [ -n "$crane_exe" ]; then
        dirname "$crane_exe"
        return 0
    fi

    return 1
}

# cdlog - Change to current running crane's log directory
cdlog() {
    local run_dir=$(_get_crane_run_dir)
    if [ $? -ne 0 ] || [ -z "$run_dir" ]; then
        echo "Error: No running crane instance found"
        return 1
    fi

    local today=$(date "+%Y-%m-%d")
    local log_dir="$run_dir/log_crane_$today"

    if [ -d "$log_dir" ]; then
        cd "$log_dir" && pwd
    else
        # Try to find the latest log directory
        local latest_log=$(ls -dt $run_dir/log_crane_* 2>/dev/null | head -1)
        if [ -n "$latest_log" ]; then
            echo "Warning: Today's log not found, using latest: $latest_log"
            cd "$latest_log" && pwd
        else
            echo "Error: No log directory found in $run_dir"
            return 1
        fi
    fi
}

# cdcrane - Change to current running project's runtime directory
cdcrane() {
    local run_dir=$(_get_crane_run_dir)
    if [ $? -ne 0 ] || [ -z "$run_dir" ]; then
        echo "Error: No running crane instance found"
        return 1
    fi

    if [ -d "$run_dir" ]; then
        cd "$run_dir" && pwd
    else
        echo "Error: Run directory not found: $run_dir"
        return 1
    fi
}
