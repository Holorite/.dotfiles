sudo apt-get update && apt-get install -y \
    cmake \
    clang \
    zsh \
    tmux \
    git \
    git-lfs \
    ripgrep \
    stow \
    zip \
    unzip \
    bat \
    python3.6

# bat symlink on ubuntu
ln -s /usr/bin/batcat ~/.local/bin/bat
# add tokyonight bat theme
mkdir -p "$(bat --config-dir)/themes"
cd "$(bat --config-dir)/themes"
# Replace _night in the lines below with _day, _moon, or _storm if needed.
curl -O https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/sublime/tokyonight_night.tmTheme
bat cache --build
bat --list-themes | grep tokyo # should output "tokyonight_night"
echo '--theme="tokyonight_night"' >> "$(bat --config-dir)/config"

# tmux
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# neovim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux64.tar.gz

# colorscript
git clone git@github.com:Holorite/shell-color-scripts-local-install.git
cd shell-color-scripts-local-install
make install
cd ..
rm -r shell-color-scripts-local-install

# fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
    
# gh cli
(type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
	&& sudo mkdir -p -m 755 /etc/apt/keyrings \
	&& wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
	&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& sudo apt update \
	&& sudo apt install gh -y

# oh my zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# zsh autocomplete, syntax highlighting, and  
# git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
# git clone https://github.com/MichaelAquilina/zsh-you-should-use.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/you-should-use

stow nvim
stow zsh
stow git
stow tmux

# nvm, node, and npm
# PROFILE=/dev/null bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash'
# zsh
# nvm install node
