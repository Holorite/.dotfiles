link=$(curl -s https://api.github.com/repos/xxxserxxx/gotop/releases/latest | jq -r '.assets[] | select(.name? | match("tgz$")) | .browser_download_url' | grep "linux_amd64")

curl -sL --output gotop.tgz "$link"
tar -xzf gotop.tgz
mv gotop $HOME/.local/bin/gotop
rm gotop.tgz
