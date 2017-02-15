#!/bin/sh
echo "\nPress Enter to continue the installation of mattata's dependencies. Use 'Ctrl-C' to exit.\n"
read
sudo wget "https://raw.githubusercontent.com/wrxck/mattata-redis/master/mattata-redis.lua" -O mattata-redis.lua
sudo wget "https://raw.githubusercontent.com/wrxck/mattata-ai/master/mattata-ai.lua" -O mattata-ai.lua
sudo apt-get update
sudo apt-get install -y lua5.3 liblua5.3-dev git redis-server libssl-dev fortune-mod fortunes cowsay fortune unzip make
git clone http://github.com/keplerproject/luarocks
cd luarocks
./configure --lua-version=5.3 --versioned-rocks-dir --lua-suffix=5.3
make build
sudo make install
sudo luarocks-5.3 install --server=http://luarocks.org/dev openssl
rocklist="luasocket luasec multipart-post lpeg dkjson serpent redis-lua luafilesystem oauth uuid html-entities luaossl feedparser"
for rock in $rocklist; do
    sudo luarocks-5.3 install $rock
done
sudo -k
cd ..
sudo chmod +x launch.sh
echo "Finished. Use './launch' to start mattata. Be sure to set your bot token in configuration.example.lua, and then rename it to configuration.lua!"