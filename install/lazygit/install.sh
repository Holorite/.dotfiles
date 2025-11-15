link=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | jq -r '.assets[] | select(.name? | match("tar.gz$")) | .browser_download_url' | grep linux_$(uname -m))

curl -sL --output lazygit.tar.gz $link
tar -xzf lazygit.tar.gz
mv lazygit $HOME/.local/bin/lazygit
rm lazygit.tar.gz

rm README.md
rm LICENSE
