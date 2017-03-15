printf "\nBefore proceeding, please ensure you have disabled macOS' System\n"
printf "Integrity Protection. This can be done by performing the following\n"
printf "actions:\n\n"
printf "\t• Reboot your Mac, and press cmd + R to enter recovery mode\n"
printf "\t• Open Utilities > Terminal\n"
printf "\t• Execute csrutil disable, then reboot and run this script\n"
printf "\nAfter you have finished using this script, you should go back into\n"
printf "recovery mode, this time executing csrutil enable\n\n"
printf "[Info] Downloading Lua 5.3.4...\n"
if [ ! -f "`which brew`" ]
then
    printf "[Info] Installing Homebrew...\n"
    ruby -e $(sudo curl -fsSL "https://raw.githubusercontent.com/Homebrew/install/master/install")
else
    printf "[Info] Updating Homebrew...\n"
    brew update
fi
brewlist="git wget openssl md5sha1sum"
for formula in $brewlist
do
    printf "[Info] Installing $formula...\n"
    brew install $formula
done
sudo cp -R /usr/local/Cellar/openssl/1.0.2k/lib/* /usr/lib/
sudo cp -R /usr/local/Cellar/openssl/1.0.2k/lib/* /usr/local/lib/
if [ ! -f "`which lua5.3`" ]
then
    printf "[Info] Downloading Lua 5.3.4...\n"
    sudo wget -N http://www.lua.org/ftp/lua-5.3.4.tar.gz
    printf "[Info] Extracting Lua 5.3.4...\n"
    tar zxf lua-5.3.4.tar.gz
    cd lua-5.3.4/
    printf "[Info] Building Lua 5.3.4...\n"
    sudo make macosx test
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