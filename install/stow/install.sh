curl -LO https://ftp.gnu.org/gnu/stow/stow-latest.tar.gz
tar xzf stow-latest.tar.gz
cd stow-*/
./configure --prefix="$HOME/.local"
make install
cd ..
rm -rf stow-*/ stow-latest.tar.gz
