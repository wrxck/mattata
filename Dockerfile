FROM debian:stretch-slim

ENV USR user
ENV HOME /home/$USR

RUN groupadd -g 1000 -r $USR && \
  useradd -u 1000 -d $HOME -m -r -g $USR $USR

RUN apt update -y &&\
    apt install -y \
    cowsay\
    coreutils\
    openssl\
    git\
    gcc\
    libreadline-dev\
    libssh-dev\
    fortune\
    fortunes\
    fortune-mod\
    make\
    liblua5.3-dev\
    lua5.3\
    libexpat1-dev\
    libcurl3\
    libcurl3-gnutls\
    libcurl4-openssl-dev\
    luarocks

RUN luarocks install telegram-bot-lua \
    && luarocks install dkjson\
    && luarocks install feedparser\
    && luarocks install html-entities\
    && luarocks install lbase64\
    && luarocks install lpeg\
    && luarocks install luacrypto\
    && luarocks install luafilesystem\
    && luarocks install luaossl\
    && luarocks install luasec\
    && luarocks install luasocket\
    && luarocks install multipart-post\
    && luarocks install redis-lua\
    && luarocks install serpent\
    && luarocks install uuid

COPY . $HOME
WORKDIR $HOME

RUN chown -R $USR:$USR .
USER $USR
