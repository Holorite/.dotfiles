# Keep pip/uv off the small home dir. On work hosts these point at the big
# workspace volume; on home/default workspace_dir is $HOME, so these resolve
# to the usual ~/.cache / ~/.local locations and nothing changes.
_ws="$(workspace_dir)"
export PIP_CACHE_DIR="$_ws/.cache/pip"
export UV_CACHE_DIR="$_ws/.cache/uv"
export UV_PYTHON_INSTALL_DIR="$_ws/.local/share/uv/python"
unset _ws
