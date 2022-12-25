printf "This script is intended to work with Ubuntu 16.04 - 18.04, other versions may also\n"
printf "work. Root access is required to complete the installation. Press enter to continue,\n"
printf "or press CTRL + C to abort.\n"
read
set -e
sudo apt-get update
aptlist="git wget openssl coreutils make gcc libreadline-dev redis-server unzip libexpat1-dev libcurl4 libcurl4-gnutls ruby ruby-dev libgd-dev imagemagick tesseract-ocr libpcre3-dev"
for package in $aptlist; do
    printf "[Info] Installing $package...\n"
    sudo apt-get --yes --force-yes install $package
done
if [ ! -f "`which lua`" ]; then
    printf "[Info] Downloading Lua 5.3.5...\n"
    wget -N http://www.lua.org/ftp/lua-5.3.5.tar.gz
    printf "[Info] Extracting Lua 5.3.5...\n"
    tar zxf lua-5.3.5.tar.gz
    cd lua-5.3.5/
    printf "[Info] Installing Lua 5.3.5...\n"
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
rocklist="luasocket luasec multipart-post lpeg dkjson serpent redis-lua luafilesystem uuid html-entities feedparser telegram-bot-lua lzlib lrexlib-pcre md5 lbase64"
for rock in $rocklist; do
    printf "[Info] Installing $rock...\n"
    sudo luarocks install $rock
done
printf "[Info] Installing lua-captcha...\n"
git clone git://github.com/lua-programming/lua-captcha.git
cp patch/malloc.patch lua-captcha/
cd lua-captcha/
git apply malloc.patch
sudo luarocks make rockspec/lua-captcha-1.0-0.rockspec
cd ../
printf "[Info] Installing redis-dump...\n"
sudo gem install redis-dump
printf "[Info] Installing ImageMagick...\n"
wget https://imagemagick.org/download/binaries/magick
printf "[Info] Cleaning up installation files...\n"
sudo rm -rf lua-5.3.5/
sudo rm lua-5.3.5.tar.gz
sudo rm -rf luarocks/
sudo rm -rf patch/
sudo rm -rf lua-captcha/
sudo -k
printf "[Info] Installation complete.\n"
