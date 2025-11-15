curl -LO https://github.com/nelsonenzo/tmux-appimage/releases/latest/download/tmux.appimage
mv tmux.appimage ~/.local/bin/tmux
chmod 700 ~/.local/bin/tmux

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Catppuccin tmux theme
mkdir -p ~/.config/tmux/plugins/catppuccin
git clone -b v2.1.3 https://github.com/catppuccin/tmux.git ~/.config/tmux/plugins/catppuccin/tmux
