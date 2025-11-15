link=$(curl -s https://api.github.com/repos/sharkdp/bat/releases/latest | jq -r '.assets[] | select(.name? | match("tar.gz$")) | .browser_download_url' | grep "$(uname -m).*gnu")

curl -sL --output bat.tar.gz $link
tar -xzf bat.tar.gz
mv bat*/bat $HOME/.local/bin/bat
rm -r bat*

# add tokyonight bat theme
mkdir -p "$(bat --config-dir)/themes"
cd "$(bat --config-dir)/themes"
# Replace _night in the lines below with _day, _moon, or _storm if needed.
curl -O https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/sublime/tokyonight_night.tmTheme
bat cache --build
bat --list-themes | grep tokyo # should output "tokyonight_night"
echo '--theme="tokyonight_night"' >> "$(bat --config-dir)/config"
rm tokyonight_night.tmTheme
