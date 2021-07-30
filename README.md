# Mattata

Mattata is a extensible Lua powered engine to control your telegram bot based on plugins.

## Getting started

Follow the instructions [here](https://core.telegram.org/bots) to create a telegram bot with BotFather.
Get yourself a host with docker and docker-compose installed and do the following:

```
> git clone git@github.com:italomaia/mattata.git
> cd mattata
> # be sure to update variables
> cp configuration.example.lua configuration.lua
> docker-compose up
```

This will start a redis and your Mattata processes. Try interacting with your bot now.
You also have the possibility to run your bot under `docker swarm`. How to do that is
not covered here.

## How to help

Mattata is plugin based so, sending a pull request with a plugin you cooked up is a very
effective way to help.

Adding support for a new leanguage is also very helpful. Take a look at `languages/*` to
see how it is done.

## FAQ

* Why lua?
    - Why not?
