# Mattata

Mattata is a extensible Lua powered engine to control your telegram bot based on plugins.
And this is a fork willing to keep the project alive. No idea what happened with the original author =T.

## Getting started

Follow the instructions [here](https://core.telegram.org/bots) to create a telegram bot with BotFather.
Get yourself a host with docker and docker-compose installed and do the following:

```
> git clone git@github.com:italomaia/mattata.git
> cp mattata/configuration.example.lua mattata/configuration.lua
> # `bot_token` is the only required configuration
> cd mattata && docker-compose up
```

This will start a redis and your Mattata processes. Try interacting with your bot now.
You also have the possibility to run your bot under `docker swarm`. How to do that is
not covered here.

## Configuring your bot

`configuration.example.lua` explains most options very well. In general, be sure, `bot_token`
and `admins` are the most important configurations there. Be sure those are properly setup
and work your way up from there.

## How to help

Mattata is plugin based so, sending a pull request with a plugin you cooked up is a very
effective way to help.

Adding support for a new leanguage is also very helpful. Take a look at `languages/*` to
see how it is done.

## FAQ

* Why lua?
    - Why not?
* How do I find out my user id?
    - Start your bot with the `id` plugin enabled and send the `/id` command.