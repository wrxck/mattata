# mattata

[@mattatabot](http://telegram.me/mattatabot) | [Official Channel](http://telegram.me/mattata) | [Official Group](http://telegram.me/geeksOffTopic)

mattata is a plugin-based bot for Telegram, written in Lua and regularly updated. mattata started off as an otouto-based bot but, over time, has grown to become more independent and has a re-written framework.

mattata (including all of the plugins and the documentation) is free software; you are free to redistribute it and/or modify it under the terms of the GNU Affero General Public License, version 3. See **LICENSE** for details. This license remains present due to some fundamental code mattata uses, which was taken from otouto.

**The Manual**

| For Users                                     | For Developers                      |
|:----------------------------------------------|:------------------------------------|
| [Setup](#setup)                               | [Plugins](#plugins)                 |
| [Configuration](#configuration)               | [Telegram API](#bindings)           |
| [Control plugins](#control-plugins)           | [Database](#database)               |
| [Output style](#output-style)                 | [List of plugins](#list-of-plugins) |

## Setup
To get your copy of mattata running as soon as possible, check out the [Quick start](#quick-start) section.

mattata uses Lua (5.3 is recommended, however it will work with 5.2) and the following Lua libraries: luasocket, luasec, multipart-post, dkjson, lpeg, redis, lua-utf8 and lua-serpent. It is recommended you install these with Luarocks. Luarocks can be installed on Ubuntu by using `sudo apt-get install luarocks`.

To get started, fork and/or clone the repository, and insert the following values into `configuration.lua`:

 - `bot_api_key` as your bot authentication token from the BotFather.
 - `owner_id` as your Telegram ID.
 - `admin_group` as the ID of the group you wish to log errors in.

If you decide you don;t want all of the plugins which mattata offers, you can disable them by removing the corresponding name(s) from the `plugins` table in `configuration.lua`.

When you are ready to start mattata, run the `launch.sh` script. This script will automatically restart the bot three seconds after being stopped.

To stop the bot, send "/shutdown" through Telegram. You can exit with Ctrl-C (or two Ctrl-C if using `launch.sh`), but this is not recommended as you risk losing data.

Please note that certain plugins, such as `messaging.lua`, will require privacy mode to be disabled, if you want it to be useable in any group it isn't an administrator. Additionally, some plugins may require or make use of various API keys and/or other configuration values not set by default. See [Configuration](#configuration) for details.

### Quick start
1. Clone the repository. `git clone http://github.com/matthewhesketh/mattata mattata`
2. Install the dependencies: Lua, and the following Lua libraries: luasocket, luasec, multipart-post, dkjson, lpeg, redis, lua-utf8 and lua-serpent.
3. Insert your bot token, Telegram ID and any other information needed into `configuration.lua`.
4. Start mattata with `./launch.sh`.

## Configuration
mattata's configurable settings are stored in `configuration.lua`. Here you will find any variables necessary for mattata to work as expected, such as API keys, custom error messages, and enabled plugins.

This section includes an exhaustive list of possible configuration values for mattata and its plugins.

### mattata's configuration values

| Name             | Default | Description                                            |
|:-----------------|:--------|:-------------------------------------------------------|
| `bot_api_key`    | nil     | Telegram bot API token.                                |
| `owner_id`       | nil     | Telegram ID of the bot owner.                          |
| `admin_group`    | nil     | Telegram ID of the recipient group for error messages. |
| `command_prefix` | `"/"`   | Character (or string) to be used for bot commands.     |
| `language`       | `"en"`  | Two-letter ISO 639-1 language code.                    |

#### Error messages
These are the generic error messages used by most plugins. These belong in a table named `errors`.

| Name         | Default                                                                                              |
|:-------------|:-----------------------------------------------------------------------------------------------------|
| `generic`    | `'WELP. I'm afraid an error has occured!'`                                                           |
| `connection` | `'I\'m sorry, but there was an error whilst I was processing your request, please try again later.'` |
| `results`    | `'I'm sorry, but I couldn't find any results for that.'`                                             |
| `argument`   | `'I'm sorry, but the arguments you gave were either invalid or non-existent. Please try again.'`     |
| `syntax`     | `'Syntax error. Please try again.'`                                                                  |

#### Plugins table
This table is an array of the names of enabled plugins. To enable a plugin, add its name to the list.

## Control plugins
Some plugins are designed to be used by the bot's owner. Here are some examples, how they're used, and what they do.

| Plugin          | Command    | Function                                           |
|:----------------|:-----------|:---------------------------------------------------|
| `control.lua`   | /reboot    | Reloads all plugins and configuration.             |
|                 | /shutdown  | Shuts down the bot after saving the database.      |
|                 | /script    | Runs a list a bot commands, separated by newlines. |
| `lua.lua`       | /lua       | Executes Lua commands in the bot's environment.    |

## Plugins
mattata uses a robust plugin system, similar to topkecleon's [otouto](http://github.com/topkecleon/otouto).

Most plugins are intended for public use, but a few are for other purposes, like those for [use by the bot's owner](#control-plugins).

There are five standard plugin components.

| Component   | Description                                                    |
|:------------|:---------------------------------------------------------------|
| `action`    | Main function. Expects `msg` table as an argument.             |
| `triggers`  | Table of triggers for the plugin. Uses Lua patterns.           |
| `init`      | Optional function run when the plugin is loaded.               |
| `cron`      | Optional function to be called every minute.                   |
| `command`   | Basic command and syntax. Listed in the help text.             |
| `doc`       | Usage for the plugin. Returned by "/help $command".            |
| `error`     | Plugin-specific error message; false for no message.           |
| `help_word` | Keyword for command-specific help. Generated if absent.        |


No component is required, but some depend on others. For example, `action` will never be run if there's no `triggers`, and `doc` will never be seen if there's no `command`.

If a plugin's `action` returns `true`, `on_msg_receive` will continue its loop.

When an action or cron function fails, the exception is caught and passed to the `handle_exception` utilty and is either printed to the console or send to the chat/channel defined in `admin_group` in `configuration.lua`.

Several functions used in multiple plugins are defined in `functions.lua`. Refer to that file for usage and documentation.

## Database
Technically speaking, mattata doesn't use one. This isn't because of dedication to lightweightedness or some clever design choice. Interfacing with databases through Lua is never a simple, easy-to-learn process. As one of the goals of mattata is that it should be a bot which is easy to write plugins for, our approach to storing data is to treat our datastore like any ordinary Lua data structure. The "database" is a table accessible in the `database` value of the bot instance (usually `self.database`), and is saved as a JSON-encoded plaintext file each hour, or when the bot is told to halt. This way, keeping and interacting with persistent data is no different than interacting with a Lua table -- with one exception: Keys in tables used as associative arrays must not be numbers. If the index keys are too sparse, the JSON encoder/decoder will either change them to keys or throw an error.

`database.users` will store user information (usernames, IDs, etc) when the bot sees the user. Each table's key is the user's ID as a string.

`database.userdata` is meant to store miscellaneous from various plugins.

`database.version` stores the last bot version that used it. This is to simplify migration to the next version of the bot an easy, automatic process.

### Links
Always name your links. Even then, use them with discretion. Excessive links make a post look messy. Links are reasonable when a user may want to learn more about something, but should be avoided when all desirable information is provided. One appropriate use of linking is to provide a preview of an image, as `xkcd.lua` and `apod.lua` do.

### Other Stuff
User IDs should appear within brackets, monospaced (`(123456789)`). Descriptions and information should be in plain text, but "flavour" text should be in italics. The standard size for arbitrary lists (such as search results) is eight within a private conversation and four elsewhere. This is a trivial pair of numbers, but consistency is noticeable and desirable.

## Contributors
Everybody is free to contribute to mattata. If you are interested, you are invited to [fork the repo](http://github.com/matthewhesketh/mattata/fork) and start making pull requests. If you have an idea and you are not sure how to implement it, open an issue or bring it up in the [Official Group](http://telegram.me/geeksOffTopic).

The creator and maintainer of mattata is me, [Matt](http://www.matthewhesketh.com). I can be contacted via [Telegram](http://telegram.me/wrxck), or [email](mailto:matthew@matthewhesketh.com).
