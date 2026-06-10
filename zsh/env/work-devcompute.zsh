# work-devcompute environment (hu-juliray-lv, /mlsys/lasvegas/scratch)
#
export XDG_DATA_HOME=/local/mnt/workspace/juliray/.local/share
export XDG_CACHE_HOME=/local/mnt/workspace/juliray/.cache
export XDG_STATE_HOME=/local/mnt/workspace/juliray/.local/state
export NPM_CONFIG_CACHE=/local/mnt/workspace/juliray/.cache/npm

alias scratch="cd /prj/qct/mlsys/lasvegas/scratch/juliray/"
hash -d lwork=/local/mnt/workspace/juliray
hash -d envs=/local/mnt/workspace/juliray/envs

pyenv() {
    local env_name="$1"
    if [ -z "$env_name" ]; then
        echo "Usage: source-env <env_name>"
        return 1
    fi

    local env_base="/local/mnt/workspace/juliray/envs/"
    if [ $env_name = "list" ]; then
        echo "Available environments:"
        ls "$env_base"
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
