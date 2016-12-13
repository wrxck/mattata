#!/bin/sh
rocklist="luasocket luasec multipart-post lpeg dkjson serpent redis-lua luafilesystem oauth luautf8"
echo "This script will request root privileges to install the required dependencies."
echo "Press enter to continue. Use Ctrl-C to exit."
read
sudo apt-get update
sudo apt-get install -y lua5.2 liblua5.2-dev git mediainfo python-bcrypt python-cffi python3 redis-server libssl-dev fortune-mod fortunes unzip make
git clone http://github.com/keplerproject/luarocks
cd luarocks
./configure --lua-version=5.2 --versioned-rocks-dir --lua-suffix=5.2
make build
sudo make install
for rock in $rocklist; do
    sudo luarocks-5.2 install $rock
done
sudo pip install youtube-dl
sudo -k
cd ..
echo "Finished. Use ./launch to start mattata."
echo "Be sure to set your bot token in configuration.example.lua,"
echo "and then rename it to configuration.lua!"