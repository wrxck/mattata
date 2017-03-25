sudo apt-get update
aptlist="git wget openssl coreutils"
for package in $aptlist
do
    printf "[Info] Installing $package...\n"
    sudo apt-get install $package
done
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
    sudo make install INSTALL_TOP=/usr
    sudo mv -f /usr/bin/lua /usr/bin/lua5.3
    sudo cp /usr/bin/lua5.3 /usr/local/bin/lua5.3
    sudo mv -f /usr/bin/luac /usr/bin/luac5.3
    sudo cp /usr/bin/luac5.3 /usr/local/bin/luac5.3
    cd ../../
fi
if [ ! -f "`which luarocks-5.3`" ]
then
    printf "[Info] Downloading LuaRocks...\n"
    sudo git clone https://github.com/keplerproject/luarocks
    cd luarocks/
    printf "[Info] Building LuaRocks...\n"
    ./configure --lua-version=5.3 --versioned-rocks-dir --lua-suffix=5.3
    sudo make build
    printf "[Info] Installing LuaRocks...\n"
    sudo make install
fi
printf "[Info] Installing openssl...\n"
sudo luarocks-5.3 install --server=http://luarocks.org/dev openssl
rocklist="luasocket luasec multipart-post lpeg dkjson serpent redis-lua luafilesystem oauth uuid html-entities luaossl feedparser telegram-bot-lua"
for rock in $rocklist
do
    printf "[Info] Installing $rock...\n"
    sudo luarocks-5.3 install $rock
done
sudo -k
printf "[Info] Installation complete!\n"