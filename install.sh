if [ ! -d ~/.local/bin ]; then
	mkdir -p ~/.local/bin
fi

# sudo apt-get update && apt-get install -y \
#     cmake \
#     clang \
#     zsh \
#     tmux \
#     git \
#     git-lfs \
#     ripgrep \
#     stow \
#     zip \
#     unzip \
#     python3.6

# bat
# ./install/bat/install.sh

# tmux
# ./install/tmux/install.sh

# neovim
# ./install/neovim/install.sh

# Lazygit
# ./install/lazygit/install.sh

# colorscript
# ./install/colorscript/install.sh

# fzf
# ./install/fzf/install.sh

# nvm
# ./install/nvm/install.sh
    
# gh cli
# (type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
# 	&& sudo mkdir -p -m 755 /etc/apt/keyrings \
# 	&& wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
# 	&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
# 	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
# 	&& sudo apt update \
# 	&& sudo apt install gh -y

# oh my zsh
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# zsh autocomplete, syntax highlighting, and  
# git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
# git clone https://github.com/MichaelAquilina/zsh-you-should-use.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/you-should-use

stow nvim
stow zsh
stow git
stow tmux
