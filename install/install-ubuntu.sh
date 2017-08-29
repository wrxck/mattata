printf "This script is intended to work with Ubuntu 16.04.2 LTS, other versions may also\n"
printf "work. Root access is required to complete the installation. Press enter to continue,\n"
printf "or press CTRL + C to abort.\n"
read
sudo apt-get update
Sudo apt-get install -y git wget openssl coreutils make gcc libreadline-dev libssl-dev redis-server libssl-dev fortune-mod fortunes cowsay fortune unzip libexpat1-dev libcurl3 libcurl3-gnutls libcurl4-openssl-dev ruby ruby-dev"
if [ ! -f "`which lua5.3`" ]
then
    printf "[Info] Downloading Lua 5.3.4...\n"
    sudo wget -N http://www.lua.org/ftp/lua-5.3.4.tar.gz
    printf "[Info] Extracting Lua 5.3.4...\n"
    tar zxf lua-5.3.4.tar.gz
    cd lua-5.3.4/
    printf "[Info] Building Lua 5.3.4...\n"
    sudo make linux test
    printf "[Info] Installing Lua 5.3.4...\n"
    sudo make install
    
    sudo mv -f /usr/local/bin/lua /usr/bin/lua5.3
    sudo ln /usr/bin/lua5.3 /usr/local/bin/lua5.3
    sudo mv -f /usr/local/bin/luac /usr/bin/luac5.3
    sudo ln /usr/bin/luac5.3 /usr/local/bin/luac5.3
    cd ../
fi
if [ ! -f "`which luarocks-5.3`" ]
then
    printf "[Info] Downloading LuaRocks...\n"
    sudo git clone https://github.com/keplerproject/luarocks
    cd luarocks/
    printf "[Info] Building LuaRocks...\n"
    sudo ./configure --lua-version=5.3 --versioned-rocks-dir --lua-suffix=5.3
    sudo make build
    printf "[Info] Installing LuaRocks...\n"
    sudo make install
    cd ../
fi
printf "[Info] Installing openssl...\n"
sudo luarocks-5.3 install --server=http://luarocks.org/dev openssl
rocklist="luasocket luasec multipart-post lpeg dkjson serpent redis-lua luafilesystem uuid html-entities luaossl feedparser telegram-bot-lua lbase64 luacrypto"
for rock in $rocklist
do
    printf "[Info] Installing $rock...\n"
    sudo luarocks-5.3 install $rock
done
printf "[Info] Installing redis-dump...\n"
sudo gem install redis-dump
sudo -K
printf "[Info] Installation complete.\n"
