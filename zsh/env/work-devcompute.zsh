# work-devcompute environment (hu-juliray-lv, /mlsys/lasvegas/scratch)
#
alias scratch="cd \"$(scratch_dir)\""
hash -d lwork=/local/mnt/workspace/juliray
hash -d envs=/local/mnt/workspace/juliray/envs

pyenv() {
    local env_name="$1"
    if [ -z "$env_name" ]; then
        echo "Usage: pyenv <env_name> | pyenv list | pyenv create <env_name>"
        return 1
    fi

    local env_base="/local/mnt/workspace/juliray/envs/"
    if [ $env_name = "list" ]; then
        echo "Available environments:"
        ls "$env_base"
        return 0
    fi

    if [ $env_name = "create" ]; then
        local new_name="$2"
        if [ -z "$new_name" ]; then
            echo "Usage: pyenv create <env_name>"
            return 1
        fi
        local new_path="$env_base/$new_name"
        if [ -d "$new_path" ]; then
            echo "Environment '$new_name' already exists in $envs"
            return 1
        fi
        python3 -m venv "$new_path" || return 1
        source "$new_path/bin/activate"
        echo "Created and activated environment: $new_name"
        return 0
    fi

    local env_path="$env_base/$env_name"
    if [ -d "$env_path" ]; then
        source "$env_path/bin/activate"
        echo "Activated environment: $env_name"
    else
        echo "Environment '$env_name' not found in $envs"
        return 1
    fi
}


# QGenie Environment Variables
[ -f "/usr2/juliray/.qgenie/.exports" ] && source "/usr2/juliray/.qgenie/.exports"
