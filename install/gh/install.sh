link=$(curl -s https://api.github.com/repos/cli/cli/releases/latest | jq -r '.assets[] | select(.name? | match("linux_amd64.tar.gz$")) | .browser_download_url')

curl -sL --output gh.tar.gz $link
tar -xzf gh.tar.gz
mv gh*/bin/gh $HOME/.local/bin/gh
rm -r gh*
