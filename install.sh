#!/bin/sh
echo "\nPress 'Enter' to begin installing mattata's dependencies. Use 'Ctrl-C' to exit.\n"
read
sudo wget "https://raw.githubusercontent.com/matthewhesketh/mattata-redis/master/mattata-redis.lua"
sudo wget "https://raw.githubusercontent.com/matthewhesketh/mattata-ai/master/mattata-ai.lua"
sudo wget "https://raw.githubusercontent.com/hoelzro/ansicolors/master/ansicolors.lua"
sudo apt-get update
sudo apt-get install -y lua5.2 liblua5.2-dev git mediainfo python3 redis-server libssl-dev fortune-mod fortunes unzip make
git clone http://github.com/keplerproject/luarocks
cd luarocks
./configure --lua-version=5.2 --versioned-rocks-dir --lua-suffix=5.2
make build
sudo make install
rocklist="luasocket luasec multipart-post lpeg dkjson serpent redis-lua luafilesystem oauth luautf8 uuid"
for rock in $rocklist; do
    sudo luarocks-5.2 install $rock
done
sudo -k
cd ..
echo "Finished. Use './launch' to start mattata. Be sure to set your bot token in configuration.example.lua, and then rename it to configuration.lua!"