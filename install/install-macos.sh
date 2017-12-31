printf "\nBefore proceeding, please ensure you have disabled macOS' System\n"
printf "Integrity Protection. This can be done by performing the following\n"
printf "actions:\n\n"
printf "\t• Reboot your Mac, and press cmd + R to enter recovery mode\n"
printf "\t• Open Utilities > Terminal\n"
printf "\t• Execute csrutil disable, then reboot and run this script\n"
printf "\nAfter you have finished using this script, you should go back into\n"
printf "recovery mode, this time executing csrutil enable\n\n"
printf "This script is intended to work with macOS 10.12.3 (16D32), other versions may also\n"
printf "work. Root access is required to complete the installation. Press enter to continue,\n"
printf "or press CTRL + C to abort.\n"
read
if [ ! -f "`which brew`" ]; then
    printf "[Info] Installing Homebrew...\n"
    ruby -e $(sudo curl -fsSL "https://raw.githubusercontent.com/Homebrew/install/master/install")
else
    printf "[Info] Updating Homebrew...\n"
    brew update
fi
brewlist="git wget openssl md5sha1sum coreutils automake cmake readline fortune homebrew/dupes/unzip gnutls ruby"
for formula in $brewlist; do
    printf "[Info] Installing $formula...\n"
    brew install $formula
done
brew link readline --force
brew link unzip --force
if [ ! -f "`which redis-cli`" ]; then
    printf "[Info] Downloading redis 4.0.2...\n"
    sudo wget -N http://download.redis.io/releases/redis-4.0.2.tar.gz
    printf "[Info] Extracting redis 4.0.2...\n"
    tar zxf redis-4.0.2.tar.gz
    cd redis-4.0.2/
    printf "[Info] Installing redis 4.0.2...\n"
    sudo make install PREFIX=/usr/local/Cellar/redis/4.0.2 CC=clang
    sudo make test
    cd ../
fi
sudo cp -R /usr/local/Cellar/openssl/1.0.2k/lib/* /usr/lib/
sudo cp -R /usr/local/Cellar/openssl/1.0.2k/lib/* /usr/local/lib/
if [ ! -f "`which lua`" ]; then
    printf "[Info] Downloading Lua 5.3.4...\n"
    sudo wget -N http://www.lua.org/ftp/lua-5.3.4.tar.gz
    printf "[Info] Extracting Lua 5.3.4...\n"
    sudo tar zxf lua-5.3.4.tar.gz
    cd lua-5.3.4/
    printf "[Info] Installing Lua 5.3.4...\n"
    sudo make macosx test
    sudo make install INSTALL_TOP=/usr
    cd ../
fi
if [ ! -f "`which luarocks`" ]; then
    printf "[Info] Downloading LuaRocks...\n"
    sudo git clone https://github.com/keplerproject/luarocks
    cd luarocks/
    printf "[Info] Building LuaRocks...\n"
    ./configure --lua-version=5.3 --versioned-rocks-dir
    sudo make build
    printf "[Info] Installing LuaRocks...\n"
    sudo make install
fi
printf "[Info] Installing openssl...\n"
sudo luarocks install --server=http://luarocks.org/dev openssl
rocklist="luasocket luasec multipart-post lpeg dkjson serpent redis-lua luafilesystem uuid html-entities luaossl feedparser telegram-bot-lua lbase64 luacrypto lua-requests"
for rock in $rocklist; do
    printf "[Info] Installing $rock...\n"
    sudo luarocks install $rock
done
printf "[Info] Installing redis-dump...\n"
sudo gem install redis-dump
printf "[Info] Cleaning up installation files...\n"
sudo rm -rf lua-5.3.4/
sudo rm lua-5.3.4.tar.gz
sudo rm -rf luarocks/
sudo rm -rf redis-4.0.2/
sudo rm redis-4.0.2.tar.gz
sudo -k
printf "[Info] Installation complete.\n"
