FROM alpine:3.14

ARG LUA_ROCKS_VER=3.7.0
ARG LUA_ROCKS_NAME="luarocks-$LUA_ROCKS_VER"

ENV USR nonroot
ENV HOME /home/${USR}
ENV PROJECT_DIR ${HOME}/code

RUN addgroup -g 1000 ${USR}\
  && adduser -S -h ${HOME} -u 1000 -G ${USR} ${USR}

RUN apk add --no-cache --update \
    coreutils\
    curl-dev\
    curl\
    expat-dev\
    gcc\
    git\
    imagemagick\
    libgd\
    lua-lzlib\
    lua5.3-dev\
    make\
    musl-dev\
    openssl-dev\
    pcre-dev\
    readline-dev\
    ruby-dev\
    ruby\
    tar\
    tesseract-ocr\
    unzip\
    wget\
    && :

RUN curl "http://luarocks.github.io/luarocks/releases/$LUA_ROCKS_NAME.tar.gz" -so- | tar xvfz - -C /tmp
RUN cd "/tmp/$LUA_ROCKS_NAME" && ./configure && make && make install

RUN luarocks install --server=http://luarocks.org/dev openssl
RUN luarocks install dkjson
RUN luarocks install feedparser
RUN luarocks install html-entities
RUN luarocks install lbase64
RUN luarocks install lpeg
RUN luarocks install lrexlib-pcre
RUN luarocks install luafilesystem
RUN luarocks install luasec
RUN luarocks install luasocket
RUN luarocks install md5
RUN luarocks install multipart-post
RUN luarocks install redis-lua
RUN luarocks install serpent
RUN luarocks install telegram-bot-lua
RUN luarocks install uuid

COPY --chown=nonroot:nonroot . ${PROJECT_DIR}
USER ${USR}
WORKDIR ${PROJECT_DIR}

CMD lua5.3 -e "require('mattata').run({}, require('configuration'))"