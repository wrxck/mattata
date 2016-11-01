#!/bin/sh
if [ $(lsb_release -r | cut -f 2) == "16.04" ]; then
	luaver="5.3"
else
	luaver="5.2"
fi
sudo apt-get update
sudo apt-get install -y lua$luaver liblua5-dev git python3 libssl-dev fortune-mod fortunes unzip make
# Install Lua dependencies
git clone http://github.com/keplerproject/luarocks
cd luarocks
./configure --lua-version=$luaver --versioned-rocks-dir --lua-suffix=$luaver
make build
sudo make install
sudo luarocks install luasocket
sudo luarocks install luasec
sudo luarocks install --server=http://luarocks.org/dev ltn12
sudo luarocks install multipart-post
sudo luarocks install lpeg
sudo luarocks install dkjson
sudo luarocks install serpent
# Install Python dependencies
sudo python -m pip install BeautifulSoup
sudo python -m pip install demjson
sudo -k
cd ..
echo "Done!"
echo "If you encounter any issues, please contact @wrxck"
echo "Use ./launch.sh to start your copy mattata."
