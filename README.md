# mattata

A feature-rich Telegram group management and utility bot, written in Lua.

## Features

- **Group Administration** - Ban, kick, mute, warn, tempban, tempmute, promote, demote, trust
- **Federation System** - Cross-group ban management with federated admin networks
- **Captcha Verification** - Challenge new members before granting chat access
- **Anti-Spam** - Rate limiting, word filters, link filtering
- **100+ Plugins** - Weather, translate, search, currency, Wikipedia, AI chat, and more
- **Multi-Language** - 10 language packs included (EN, DE, AR, PL, PT, TR, Scottish)
- **PostgreSQL + Redis** - PostgreSQL for persistent data, Redis for caching
- **Hot-Reloadable Plugins** - Reload plugins without restarting the bot
- **Docker Ready** - One command deployment with Docker Compose

## Quick Start (Docker)

```bash
cp .env.example .env
# Edit .env and set BOT_TOKEN
docker compose up -d
```

## Quick Start (Manual)

### Prerequisites
- Lua 5.3+
- LuaRocks
- PostgreSQL 14+
- Redis 7+

### Installation

```bash
# Install Lua dependencies
luarocks install telegram-bot-lua
luarocks install pgmoon
luarocks install redis-lua
luarocks install dkjson
luarocks install luautf8

# Configure
cp .env.example .env
# Edit .env with your settings

# Start
lua main.lua
```

## Configuration

All configuration is managed through environment variables. See `.env.example` for the full reference.

### Required
| Variable | Description |
|----------|-------------|
| `BOT_TOKEN` | Telegram Bot API token from @BotFather |

### Optional API Keys
| Variable | Description | Used By |
|----------|-------------|---------|
| `LASTFM_API_KEY` | Last.fm API key | `/lastfm`, `/np` |
| `YOUTUBE_API_KEY` | YouTube Data API v3 key | `/youtube` |
| `SPOTIFY_CLIENT_ID` | Spotify app client ID | `/spotify` |
| `SPOTIFY_CLIENT_SECRET` | Spotify app client secret | `/spotify` |
| `SPAMWATCH_TOKEN` | SpamWatch API token | Anti-spam |
| `OPENAI_API_KEY` | OpenAI API key | `/ai` |
| `ANTHROPIC_API_KEY` | Anthropic API key | `/ai` |

## Architecture

```
mattata/
├── main.lua                    # Entry point
├── src/
│   ├── core/                   # Framework modules
│   │   ├── config.lua          # .env configuration reader
│   │   ├── loader.lua          # Plugin discovery & hot-reload
│   │   ├── router.lua          # Event dispatch
│   │   ├── middleware.lua       # Middleware pipeline
│   │   ├── database.lua        # PostgreSQL (pgmoon)
│   │   ├── redis.lua           # Redis connection
│   │   ├── permissions.lua     # Admin/mod/trusted checks
│   │   ├── session.lua         # Redis session/cache management
│   │   ├── i18n.lua            # Language manager
│   │   └── logger.lua          # Structured logging
│   ├── middleware/              # Middleware chain
│   ├── plugins/                # Plugin categories
│   │   ├── admin/              # Group management (30+ plugins)
│   │   ├── utility/            # Tools & info (25+ plugins)
│   │   ├── fun/                # Entertainment (13 plugins)
│   │   ├── media/              # Media search (6 plugins)
│   │   └── ai/                 # LLM integration
│   ├── db/migrations/          # PostgreSQL schema migrations
│   ├── languages/              # 10 language packs
│   └── data/                   # Static data (slaps, join messages)
├── docker-compose.yml
├── Dockerfile
└── .env.example
```

## Plugin Development

Plugins follow a simple contract:

```lua
local plugin = {}
plugin.name = 'myplugin'
plugin.category = 'utility'
plugin.description = 'Does something useful'
plugin.commands = { 'mycommand', 'alias' }
plugin.help = '/mycommand <args> - Does the thing.'

function plugin.on_message(api, message, ctx)
    return api.send_message(message.chat.id, 'Hello!')
end

return plugin
```

Add your plugin to the category's `init.lua` manifest and it will be auto-loaded.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Credits

Created by [Matt Hesketh](https://github.com/wrxck).
