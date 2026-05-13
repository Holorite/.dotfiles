if [ ! -d ~/.local/bin ]; then
	mkdir -p ~/.local/bin
fi

# Set up environment
if [ ! -f ~/.dotfiles_env ]; then
	echo "Select DOTFILES_ENV:"
	echo "  1) work-argos"
	echo "  2) work-devcompute"
	echo "  3) home"
	printf "Choice [1-3]: "
	read env_choice
	case "$env_choice" in
		1) echo "work-argos" > ~/.dotfiles_env ;;
		2) echo "work-devcompute" > ~/.dotfiles_env ;;
		3) echo "home" > ~/.dotfiles_env ;;
		*) echo "Invalid choice"; exit 1 ;;
	esac
	echo "DOTFILES_ENV set to: $(cat ~/.dotfiles_env)"
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

# Symlink env-specific gitconfig
DOTFILES_ENV=$(cat ~/.dotfiles_env)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/git/.gitconfig.$DOTFILES_ENV" ]; then
    ln -sf "$SCRIPT_DIR/git/.gitconfig.$DOTFILES_ENV" ~/.gitconfig.local
fi

# Use personal email for the dotfiles repo itself
git -C "$SCRIPT_DIR" config user.email julian.r8y@gmail.com
