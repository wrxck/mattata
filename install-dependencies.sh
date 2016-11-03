#!/bin/sh
sudo apt-get update
sudo apt-get install -y lua5.2 liblua5-dev git python3 libssl-dev fortune-mod fortunes unzip make
# Install Lua dependencies
git clone http://github.com/keplerproject/luarocks
cd luarocks
./configure --lua-version=5.2 --versioned-rocks-dir --lua-suffix=5.2
make build
sudo make install
sudo luarocks install luasocket
sudo luarocks install luasec
sudo luarocks install --server=http://luarocks.org/dev ltn12
sudo luarocks install multipart-post
sudo luarocks install lpeg
sudo luarocks install dkjson
sudo luarocks install serpent
sudo luarocks install redis-lua
sudo luarocks install fakeredis
sudo luarocks install feedparser
sudo luarocks install luaexpat
# Install Python dependencies
sudo python -m pip install BeautifulSoup
sudo python -m pip install demjson
sudo python -m pip install youtube-dl
sudo -k
cd ..
echo "Done!"
echo "If you encounter any issues, please contact @wrxck"
echo "Use ./launch.sh to start your copy mattata."
