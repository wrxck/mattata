# mattata

A feature-rich Telegram group management and utility bot, written in Lua.

## Features

- **Group Administration** - Ban, kick, mute, warn, tempban, tempmute, promote, demote, trust
- **Federation System** - Cross-group ban management with federated admin networks
- **Captcha Verification** - Challenge new members with built-in or custom captcha
- **Anti-Spam** - Rate limiting, word filters, link filtering, auto-delete
- **100+ Plugins** - Weather, translate, search, currency, Wikipedia, AI chat, and more
- **Async HTTP** - Non-blocking HTTP client for plugin API calls via copas
- **Stored Procedures** - All database operations use PostgreSQL stored procedures
- **Forum Topics** - Full support for forum topic management and slow mode
- **Reaction Karma** - Track karma via message reactions
- **RSS Feeds** - Subscribe to and monitor RSS/Atom feeds
- **Scheduled Messages** - Queue messages for future delivery
- **Inline Queries** - Inline search and sharing across chats
- **QR Codes** - Generate QR codes from text
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

## Upgrading from v1.5

If you are upgrading from mattata v1.5, the migration is automatic. On first boot, mattata v2 detects v1.5 data and imports it into the new schema.

### What gets migrated

- **Chat settings** (antilink, welcome, captcha, max warnings, etc.)
- **Welcome messages**
- **Rules**
- **Warnings** (per-user warning counts)
- **Disabled plugins** (with name mapping to v2 plugin names)
- **Filters** (word filters with actions)
- **Triggers** (auto-responses)
- **Bans** (group blocklist entries)
- **Configuration** (`configuration.lua` converted to `.env` format)

### How it works

1. On startup, mattata scans Redis for v1-era key patterns and checks for `configuration.lua`
2. If v1 data is found, it imports everything into PostgreSQL via a single transaction
3. The migration is recorded in `schema_migrations` so it only runs once
4. After success, v1 Redis keys are cleaned up and `configuration.lua` is renamed to `configuration.lua.v1.bak`

### Prerequisites

- Your v1.5 Redis instance must still be accessible (same host/port/db)
- PostgreSQL must be running and configured in `.env` (or the migration will create `.env` from `configuration.lua`)

### Config mapping reference

| v1 (`configuration.lua`) | v2 (`.env`) |
|---------------------------|-------------|
| `bot_token` | `BOT_TOKEN` |
| `admins` | `BOT_ADMINS` |
| `redis.host` | `REDIS_HOST` |
| `redis.port` | `REDIS_PORT` |
| `redis.password` | `REDIS_PASSWORD` |
| `keys.lastfm` | `LASTFM_API_KEY` |
| `keys.youtube` | `YOUTUBE_API_KEY` |
| `keys.weather` | `OPENWEATHERMAP_API_KEY` |
| `keys.spotify_client_id` | `SPOTIFY_CLIENT_ID` |
| `keys.spotify_client_secret` | `SPOTIFY_CLIENT_SECRET` |
| `keys.spamwatch` | `SPAMWATCH_TOKEN` |
| `log_channel` / `log_chat` | `LOG_CHAT` |

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
│   │   ├── http.lua            # Async HTTP client (copas)
│   │   ├── permissions.lua     # Admin/mod/trusted checks
│   │   ├── session.lua         # Redis session/cache management
│   │   ├── i18n.lua            # Language manager
│   │   └── logger.lua          # Structured logging
│   ├── middleware/              # Middleware chain
│   ├── plugins/                # Plugin categories
│   │   ├── admin/              # Group management (35+ plugins)
│   │   ├── utility/            # Tools & info (33+ plugins)
│   │   ├── fun/                # Entertainment (16 plugins)
│   │   ├── media/              # Media search (7 plugins)
│   │   └── ai/                 # LLM integration
│   ├── db/migrations/          # PostgreSQL schema migrations
│   ├── languages/              # 10 language packs
│   └── data/                   # Static data (slaps, join messages)
├── docker-compose.yml
├── docker-compose.matticate.yml
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
