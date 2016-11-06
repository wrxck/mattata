# Installs Lua, Luarocks, and mattata's dependencies. Works in Ubuntu, maybe Debian.
# Installs Lua 5.3 if your OS is Ubuntu 16.04. Otherwise, 5.2 is installed instead.
#!/bin/sh
rocklist="luasocket luasec multipart-post lpeg dkjson serpent redis-lua"
if [ $(lsb_release -r | cut -f 2) == "16.04" ]; then
    luaver="5.3"
else
    luaver="5.2"
fi
echo "This script will request root privileges to install the required dependencies."
echo "Press enter to continue. Use Ctrl-C to exit."
read
sudo apt-get update
sudo apt-get install -y lua$luaver liblua$luaver-dev git python3 redis-server libssl-dev fortune-mod fortunes unzip make
git clone http://github.com/keplerproject/luarocks
cd luarocks
./configure --lua-version=$luaver --versioned-rocks-dir --lua-suffix=$luaver
make build
sudo make install
for rock in $rocklist; do
    sudo luarocks-$luaver install $rock
done
sudo python -m pip install BeautifulSoup
sudo python -m pip install demjson
sudo python -m pip install youtube-dl
sudo -k
cd ..
echo "Finished. Use ./launch to start mattata."
echo "Be sure to set your bot token in configuration.example.lua,"
echo "and then rename it to configuration.lua!"