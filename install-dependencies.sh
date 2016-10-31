#!/bin/sh
if [ $(lsb_release -r | cut -f 2) == "16.04" ]; then
	luaver="5.3"
	rocklist="luasocket luasec multipart-post lpeg dkjson"
else
	luaver="5.2"
	rocklist="luasocket luasec multipart-post lpeg dkjson luautf8"
fi
sudo apt-get update
sudo apt-get install -y lua$luaver liblua$luaver-dev git python3 libssl-dev fortune-mod fortunes unzip make
sudo python -m pip install BeautifulSoup
sudo python -m pip install demjson
git clone http://github.com/keplerproject/luarocks
cd luarocks
./configure --lua-version=$luaver --versioned-rocks-dir --lua-suffix=$luaver
make build
sudo make install
for rock in $rocklist; do
	sudo luarocks-$luaver install $rock
done
sudo -k
cd ..
echo "Finished."
echo "Use ./launch.sh to start mattata."
