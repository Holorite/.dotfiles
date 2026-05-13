export RUSTUP_HOME=/prj/qct/mlsys/markham/scratch/juliray/.rustup
export CARGO_HOME=/prj/qct/mlsys/markham/scratch/juliray/.cargo
if [ -d $CARGO_HOME ]; then
    . "$CARGO_HOME/env"
fi

hash -d preptools=/prj/qct/mlsys/markham/scratch/juliray/prepare_time_tools
hash -d symwork=/prj/qct/mlsys/markham/scratch/juliray/work
hash -d lwork=/local/mnt/workspace/juliray

function create_work_sym() {
    ln -s /prj/qct/mlsys/markham/scratch/juliray/work ./symwork
}

alias scratch="cd /prj/qct/mlsys/markham/scratch/juliray"

if [[ ! -d ~/.local/share/nvim/avante/rag_service ]]; then
    mkdir -p /tmp/avante-rag-service && chmod 777 /tmp/avante-rag-service
    ln -s /tmp/avante-rag-service ~/.local/share/nvim/avante/rag_service
fi

function check_uptime() {
    for ((i=0; i<=8; i++)); do
        ssh "argos-$i" -t uptime
    done
}
function check_python() {
    for ((i=0; i<=8; i++)); do
        ssh "argos-$i" -t python3 -V
    done
}

export PATH="$PATH:/usr2/juliray/.local/bin"

# QGenie Environment Variables
[ -f "/usr2/juliray/.qgenie/.exports" ] && source "/usr2/juliray/.qgenie/.exports"
