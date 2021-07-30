FROM alpine:latest

ARG LUA_VER=5.3.6
ARG LUA_NAME="lua-$LUA_VER"

ARG LUAROCKS_VER=3.7.0
ARG LUAROCKS_NAME="luarocks-$LUAROCKS_VER"

ENV USR nonroot
ENV HOME /home/${USR}
ENV PROJECT_DIR ${HOME}/code

RUN addgroup -g 1000 ${USR}\
  && adduser -S -h ${HOME} -u 1000 -G ${USR} ${USR}

RUN apk upgrade -U && apk add --no-cache\
    # shared library
    readline-dev

# installs lua
RUN apk upgrade -U && apk add --no-cache --virtual .build-deps\
        ca-certificates\
        curl\
        gcc\
        libc-dev\
        make\
        openssl\
    && set -ex\
    && curl "https://www.lua.org/ftp/$LUA_NAME.tar.gz" -so- | tar xvfz - -C /tmp\
    && cd "/tmp/$LUA_NAME"\
    && make linux && make install\
    && rm -rf /tmp/*\
    && apk del .build-deps

# installs luarocks
RUN apk upgrade -U && apk add --no-cache --virtual .build-deps\
        ca-certificates\
        curl\
        gcc\
        libc-dev\
        make\
        openssl\
    && set -ex\
    && curl "http://luarocks.github.io/luarocks/releases/$LUAROCKS_NAME.tar.gz" -so- | tar xvfz - -C /tmp\
    && cd "/tmp/$LUAROCKS_NAME"\
    && ./configure\
    && make && make install\
    && rm -rf /tmp/*\
    && apk del .build-deps

# installs mattata dependencies
RUN apk upgrade -U && apk add --no-cache --update --virtual .build-deps\
        coreutils\
        curl-dev\
        curl\
        expat-dev\
        gcc\
        git\
        imagemagick\
        libgd\
        libc-dev\
        ca-certificates\
        lua-lzlib\
        make\
        musl-dev\
        openssl-dev\
        pcre-dev\
        ruby-dev\
        ruby\
        tar\
        tesseract-ocr\
        unzip\
        wget\
    && luarocks install --server=http://luarocks.org/dev openssl\
    && luarocks install dkjson\
    && luarocks install feedparser\
    && luarocks install html-entities\
    && luarocks install lbase64\
    && luarocks install lpeg\
    && luarocks install lrexlib-pcre\
    && luarocks install luafilesystem\
    && luarocks install luasec\
    && luarocks install luasocket\
    && luarocks install md5\
    && luarocks install multipart-post\
    && luarocks install redis-lua\
    && luarocks install serpent\
    && luarocks install telegram-bot-lua\
    && luarocks install uuid\
    && apk del .build-deps

COPY --chown=nonroot:nonroot . ${PROJECT_DIR}
USER ${USR}
WORKDIR ${PROJECT_DIR}

CMD /usr/local/bin/lua -e "require('mattata').run({}, require('configuration'))"