set -e
printf "This script is intended to work with Ubuntu 16.04.2 LTS, other versions may also\n"
printf "work. Root access is required to complete the installation. Press enter to continue,\n"
printf "or press CTRL + C to abort.\n"
read
sudo apt-get update
sudo apt-get install -y \
	git \
	wget \
	openssl \
	coreutils \
	make \
	gcc \
	libreadline-dev \
	libssl-dev \
	redis-server \
	libssl-dev \
	fortune-mod \
	fortunes \
	cowsay \
	fortune \
	unzip \
	libexpat1-dev \
	libcurl3 \
	libcurl3-gnutls \
	libcurl4-openssl-dev \
	ruby \
	ruby-dev \
	lua5.3 \
	luarocks
printf "[Info] Installing openssl...\n"
sudo luarocks-5.3 install --server=http://luarocks.org/dev openssl
rocklist="luasocket luasec multipart-post lpeg dkjson serpent redis-lua luafilesystem uuid html-entities luaossl feedparser telegram-bot-lua lbase64 luacrypto"
for rock in $rocklist
do
    printf "[Info] Installing $rock...\n"
    sudo luarocks-5.3 install $rock
done
printf "[Info] Installing redis-dump...\n"
sudo gem install redis-dump
sudo -K
printf "[Info] Installation complete.\n"
