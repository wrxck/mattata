# mattata v2.0 - Multi-stage Docker build
# Builder stage: compile Lua and dependencies
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    unzip \
    libreadline-dev \
    libssl-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Lua 5.3
RUN cd /tmp && \
    wget -q https://www.lua.org/ftp/lua-5.3.6.tar.gz && \
    tar xzf lua-5.3.6.tar.gz && \
    cd lua-5.3.6 && \
    make linux && \
    make install && \
    cd / && rm -rf /tmp/lua-5.3.6*

# Install LuaRocks
RUN cd /tmp && \
    wget -q https://luarocks.org/releases/luarocks-3.9.2.tar.gz && \
    tar xzf luarocks-3.9.2.tar.gz && \
    cd luarocks-3.9.2 && \
    ./configure --with-lua=/usr/local && \
    make && make install && \
    cd / && rm -rf /tmp/luarocks-3.9.2*

# Install telegram-bot-lua v3.0 from source (v3.0 not yet published to luarocks)
RUN cd /tmp && \
    git clone --depth 1 https://github.com/wrxck/telegram-bot-lua.git && \
    cd telegram-bot-lua && \
    luarocks make telegram-bot-lua-3.0-0.rockspec && \
    cd / && rm -rf /tmp/telegram-bot-lua

# Install remaining Lua dependencies
RUN luarocks install pgmoon && \
    luarocks install redis-lua && \
    luarocks install luaossl

# Runtime stage
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    libreadline8 \
    libssl3 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy Lua installation from builder
COPY --from=builder /usr/local /usr/local

# Set up app directory
WORKDIR /app
COPY . /app

# Run as non-root
RUN useradd -m mattata
USER mattata

CMD ["lua", "main.lua"]
