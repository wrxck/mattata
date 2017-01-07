# mattata

##### What is mattata?
mattata's a bot. Not just any bot but a user-friendly [Telegram bot](https://telegram.org/blog/bot-revolution) with a mind of its own.

The idea behind mattata is that it can be used and loved by users of any age; from children to adults, noobies to developers. There's something for everyone and I think you're going to love it.

The name came from a mashup of my name, Matthew, and a (somewhat annoying) Pokémon, rattata. It originated as a fork of [otouto](http://otou.to), although it's now a project of its own. After re-writing most of the code (not once, but twice), I decided to dedicate a lot of my spare time (inbetween coursework for Sixth Form and socialising) to improving mattata. To this date, there are over 100 unique features - all capable of a lot. Notable features include a Cleverbot binding (which gives mattata the "ability to talk to you"), and a robust plugin system which can be adjusted per chat to suit the user's needs. That's just the tip of the iceberg, mattata also features an extensive selection of administrative commands, adjustable locales, an inline mode, and tons more!

mattata is written in Lua, and made with love. It's designed to work with Ubuntu systems (ideally Ubuntu 16.04 or later). Other OSes may still work, but there are no guarantees everything will be as smooth as expected.

Now you've learned a bit about mattata, let's move on to getting you your own copy up and running!

### Setup
Installing mattata is a really simple process. Firstly, you need to clone the repository. To do this, you need to open Terminal, navigate to the directory you'd like to run mattata from, and execute `git clone https://github.com/wrxck/mattata`. If you haven't got `git` installed, you can install it using `sudo apt-get install git`.

After you've done this, you need to install the dependencies required for mattata to do its thing. If you've not already gone inside of the `mattata` directory, just do `cd mattata/`. Then, run `./install.sh`. This script requires you to have root access, commonly known as sudo.

Assuming everything went okay, you're now ready to start configuring your copy of mattata. mattata is quite a large project; with a robust plugin system and endless features, it's no wonder there's a seperate configuration file. With the editor of your choice, you need to modify certain values of `configuration.lua`. Let's start with the bot API token.

The bot API token is a unique string of characters you receive when you initially create a bot via Telegram's [@BotFather](https://t.me/BotFather). This is what identifies your bot when you're making requests and receiving updates from Telegram's bot API. This token needs to be inserted into `configuration.lua` as the `bot_token`.

Then, you need to specify your Telegram user ID. This is the numerical value that most clients don't show; so if you're having trouble finding it, send `/id` to [@mattatabot](https://t.me/mattatabot). This ID needs to go inside the `admins` table in `configuration.lua` - you may list multiple IDs, if you're planning on allowing friends or family complete control over your copy of mattata, and server access with commands such as `/lua` and `/bash`. If you do choose to enter multiple user IDs, make sure it's a comma separated array.

Then, there are 3 more logging-related values you'll need to fill in. These are the `log_chat`, `log_channel` and `bug_reports_chat` parts of `configuration.lua`. These all need to contain numerical IDs, either of yourself or a designated group you've created for logging errors and bug reports into. `log_chat` is where the errors will be sent to, `log_channel` is where any administrative actions will be logged to, and `bug_reports_chat` is where bug reports sent using `/bugreport` will end up. If you'd rather not log administrative actions, feel free to change the boolean value of the `log_admin_actions` part of `configuration.lua`. Your instance of mattata needs to be present in all of the listed chats; unless the given ID is that of a user, in which case you just need to make sure you haven't blocked the bot.

Configured plugins are listed in the `plugins` table of `configuration.lua`. If you want to prevent your copy of mattata from loading a specific plugin, you need to comment it out (with a preceding `--`) or remove it. This also applies to the administrative plugins listed in the similar, yet somewhat smaller, table - `administration`.

If you're an advanced user, you can customise the way your copy of mattata will communicate with the redis database on your system by modifying the values in the `redis` table of `configuration.lua`. It is important that you **only modify these values if you know what you are doing**.

The `keys` table of `configuration.lua` is where you'll need to insert API keys for various web APIs mattata uses. The links to most of the API key applications for these are commented out next to the corresponding service.

# Donate
As well as feedback and suggestions, you can contribute to the mattata project in the form of a monetary donation. This makes the biggest impact since it helps pay for things such as server hosting, domain registration, educational resources and snacks (all programmers get peckish). A donation of any sum is appreciated and, if you wish, you can donate [here](https://paypal.me/wrxck). I'd like to take a moment to thank the following people for their donation:
* Joshua ([@j0shu4](https://telegram.me/j0shu4))
* Para ([@para949](https://telegram.me/para949))
* Flo ([@aRandomStranger](https://telegram.me/aRandomStranger))
* mochi ([@mochicon](https://telegram.me/mochicon))
* Barend ([@xenial](https://telegram.me/xenial))

*Disclaimer: this README file is still being extended and may lack information*