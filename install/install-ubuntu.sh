printf "This script is intended to work with Ubuntu 16.04.2 LTS, other versions may also\n"
printf "work. Root access is required to complete the installation. Press enter to continue,\n"
printf "or press CTRL + C to abort.\n"
read
set -e
sudo apt-get update
aptlist="git wget openssl coreutils make gcc libreadline-dev libssl-dev redis-server unzip libexpat1-dev libcurl3 libcurl3-gnutls libcurl4-openssl-dev ruby ruby-dev lua-requests"
for package in $aptlist; do
    printf "[Info] Installing $package...\n"
    sudo apt-get install $package
done
if [ ! -f "`which lua`" ]; then
    printf "[Info] Downloading Lua 5.3.4...\n"
    wget -N http://www.lua.org/ftp/lua-5.3.4.tar.gz
    printf "[Info] Extracting Lua 5.3.4...\n"
    tar zxf lua-5.3.4.tar.gz
    cd lua-5.3.4/
    printf "[Info] Installing Lua 5.3.4...\n"
    sudo make linux test
    sudo make install
    sudo cp /usr/local/bin/lua /usr/bin/lua
    sudo cp /usr/local/bin/luac /usr/bin/luac
    cd ../
fi
if [ ! -f "`which luarocks`" ]; then
    printf "[Info] Downloading LuaRocks...\n"
    git clone --recursive https://github.com/keplerproject/luarocks
    cd luarocks/
    printf "[Info] Building LuaRocks...\n"
    sudo ./configure --lua-version=5.3 --versioned-rocks-dir
    sudo make build
    printf "[Info] Installing LuaRocks...\n"
    sudo make install
    cd ../
fi
printf "[Info] Installing openssl...\n"
sudo luarocks install --server=http://luarocks.org/dev openssl
rocklist="luasocket luasec multipart-post lpeg dkjson serpent redis-lua luafilesystem uuid html-entities luaossl feedparser telegram-bot-lua lbase64 luacrypto"
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
sudo -k
printf "[Info] Installation complete.\n"
