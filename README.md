# mattata

## What is mattata?
mattata's a bot. Not just any bot but a user-friendly [Telegram bot](https://telegram.org/blog/bot-revolution) with a mind of its own.

The idea behind mattata is that it can be used and loved by users of any age; from children to adults, noobies to developers. There's something for everyone and I think you're going to love it.

The name came from a mashup of my name, Matthew, and a (somewhat annoying) Pokémon, rattata. It originated as a fork of [otouto](http://otou.to), although it's now a project of its own. After re-writing most of the code (not once, but twice), I decided to dedicate a lot of my spare time (inbetween coursework for Sixth Form and socialising) to improving mattata. To this date, there are over 100 unique features - all capable of a lot. Notable features include a Cleverbot binding (which gives mattata the "ability to talk to you"), and a robust plugin system which can be adjusted per chat to suit the user's needs. That's just the tip of the iceberg, mattata also features an extensive selection of administrative commands, adjustable locales, an inline mode, and tons more!

mattata is written in Lua, and made with love. It's designed to work with Ubuntu systems (ideally Ubuntu 16.04 or later). Other OSes may still work, but there are no guarantees everything will be as smooth as expected.

Now you've learned a bit about mattata, let's move on to getting you your own copy up and running!

## Setup
Installing mattata is a really simple process. Firstly, you need to clone the repository. To do this, you need to open Terminal, navigate to the directory you'd like to run mattata from, and execute `git clone https://github.com/wrxck/mattata`. If you haven't got `git` installed, you can install it using `sudo apt-get install git`.

After you've done this, you need to install the dependencies required for mattata to do its thing. If you've not already gone inside of the `mattata` directory, just do `cd mattata/`. Then, run `./install.sh`. This script requires you to have root access, commonly known as sudo.

Assuming everything went okay, you're now ready to start configuring your copy of mattata. mattata is quite a large project; with a robust plugin system and endless features, it's no wonder there's a seperate configuration file. With the editor of your choice, you need to modify certain values of `configuration.lua`. Let's start with the bot API token.

The bot API token is a unique string of characters you receive when you initially create a bot via Telegram's [@BotFather](https://t.me/BotFather). This is what identifies your bot when you're making requests and receiving updates from Telegram's bot API. This token needs to be inserted into `configuration.lua` as the `bot_token`.

Then, you need to specify your Telegram user ID. This is the numerical value that most clients don't show; so if you're having trouble finding it, send `/id` to [@mattatabot](https://t.me/mattatabot). This ID needs to go inside the `admins` table in `configuration.lua` - you may list multiple IDs, if you're planning on allowing friends or family complete control over your copy of mattata, and server access with commands such as `/lua` and `/bash`. If you do choose to enter multiple user IDs, make sure it's a comma separated array.

Then, there are 3 more logging-related values you'll need to fill in. These are the `log_chat`, `log_channel` and `bug_reports_chat` parts of `configuration.lua`. These all need to contain numerical IDs, either of yourself or a designated group you've created for logging errors and bug reports into. `log_chat` is where the errors will be sent to, `log_channel` is where any administrative actions will be logged to, and `bug_reports_chat` is where bug reports sent using `/bugreport` will end up. If you'd rather not log administrative actions, feel free to change the boolean value of the `log_admin_actions` part of `configuration.lua`. Your instance of mattata needs to be present in all of the listed chats; unless the given ID is that of a user, in which case you just need to make sure you haven't blocked the bot.

Configured plugins are listed in the `plugins` table of `configuration.lua`. If you want to prevent your copy of mattata from loading a specific plugin, you need to comment it out (with a preceding `--`) or remove it. This also applies to the administrative plugins listed in the similar, yet somewhat smaller, table - `administration`.

If you're an advanced user, you can customise the way your copy of mattata will communicate with the redis database on your system by modifying the values in the `redis` table of `configuration.lua`. It is important that you **only modify these values if you know what you are doing**.

The `keys` table of `configuration.lua` is where you'll need to insert API keys for various web APIs mattata uses. The links to most of the API key applications for these are commented out next to the corresponding service.

After you've done this then you're ready to launch your instance of mattata. Execute `./launch.sh` in the Terminal and mattata will attempt to connect to the Telegram bot API. You'll see more bot information appear, including the username and ID of your bot. If you don't see this then you need to check you still have internet connection.

Having issues with `./install.sh` or `./launch.sh`? Try using `sudo chmod +x <file>` to make it executable.

## API

If you're looking to contribute to the development of mattata, a good beginning is to write a new plugin. This refers to another one of mattata's toggleable functions, and I'm willing to consider implementing any new ideas you may have.

Using mattata is easy. Each Telegram bot API method has a corresponding function in `mattata.lua`. Below are some common method-binding functions you can into your code.

```
function mattata.send_message(chat_id, text, parse_mode, disable_web_page_preview, disable_notification, reply_to_message_id, reply_markup)
    return mattata.request(
        'sendMessage',
        {
            ['chat_id'] = chat_id,
            ['text'] = text,
            ['parse_mode'] = parse_mode or nil,
            ['disable_web_page_preview'] = disable_web_page_preview or true,
            ['disable_notification'] = disable_notification or false,
            ['reply_to_message_id'] = reply_to_message_id or nil,
            ['reply_markup'] = reply_markup or nil
        }
    )
end
```

The above function is taken from `mattata.lua` and is used to send a message through the `sendMessage` method of the Telegram bot API. As you can see from the first line, there are 7 different arguments you can pass to the function - however only the first two are required. `chat_id` needs to be the numerical ID of the chat you want to send the message to. If this is a public group or channel it can be specified by it's [username](https://t.me/username). If you're specifying the chat by its numerical ID then this can be a numerical value or a string. The mattata API will automatically make all passed arguments strings before making the request to the Telegram bot API. If you're specifying the chat by ID then it must be a string with a preceding @ (e.g. `'@mattata'`). The second argument `text`, and also last of the required arguments, must be a string of text with a length no more than 4096. Before I continue, it is important to note that all arguments up to the one you're not specifying must be given. Therefore, if you're specifying a JSON-encoded table for the `reply_markup` argument, you must also give a value for the previous argument, `reply_to_message_id`; and, assuming you don't intend to assign this argument a value, you could just pass `nil`.

The `parse_mode` argument, if needed, should be a choice of two strings - `'markdown'` or `'html'`. The next two arguments, which are also optional, require a boolean value (either `true` or `false`, although these can also be given as a string value). If set to `false`, the `disable_web_page_preview` argument will make the message send with a link preview (that's assuming the text passed contains a URL to start with, otherwise you won't notice a difference) - this value is set to `true` by default. The `disable_notification` argument is set to `false` by default, meaning the user will be notified when sent a message by the bot. If this is set to `true`, the message will be sent silently - which is useful if you're sending a regular message to a channel or group, since a user could get annoyed if you're always notifying them. The next argument, `reply_to_message_id`, should be a numerical value (or an integer-containing string). This is set to `nil` by default. The final argument is necessary if you want to send a [keyboard object](https://core.telegram.org/bots/api#replykeyboardmarkup). This must be JSON-encoded, and it is recommended you create it using Lua tables before encoding it to JSON. Below is an example of a JSON-encoded keyboard object, which will display an inline button labelled 'mattata', which will send the user to 'http://mattata.pw' when clicked.

```
local keyboard = json.encode(
	{
		['inline_keyboard'] = {
			{
				{
					['text'] = 'mattata',
					['url'] = 'http://mattata.pw'
				}
			}
		}
	}
)
```

To save time typing arguments, a function for sending a message as a reply can be used.

```
function mattata.send_reply(message, text, parse_mode, disable_web_page_preview, reply_markup)
    return mattata.request(
        'sendMessage',
        {
            ['chat_id'] = message.chat.id,
            ['text'] = text,
            ['parse_mode'] = parse_mode or nil,
            ['disable_web_page_preview'] = disable_web_page_preview or true,
            ['disable_notification'] = false,
            ['reply_to_message_id'] = message.message_id,
            ['reply_markup'] = reply_markup or nil
        }
    )
end
```

As with `mattata.send_message`, there are only two required arguments. However there are some differences. The first argument is the entire `message` object **not** the chat ID. This is because the function is intended to be used to send a message as a reply, and gives the `reply_to_message_id` argument a value of `message.message_id` - and by passing the entire object as an argument you're reducing the amount of arguments you need to pass since it contains multiple required values. The `text` argument is the same as before - a string value with a length of no more than 4096. That's it for the required arguments.


## Donate
As well as feedback and suggestions, you can contribute to the mattata project in the form of a monetary donation. This makes the biggest impact since it helps pay for things such as server hosting and domain registration. A donation of any sum is appreciated and, if you wish, you can donate [here](https://paypal.me/wrxck). I'd like to take a moment to thank the following people for their donation:
* Joshua ([@j0shu4](https://t.me/j0shu4))
* Para ([@para949](https://t.me/para949))
* Flo ([@aRandomStranger](https://t.me/aRandomStranger))
* mochi ([@mochicon](https://t.me/mochicon))
* Barend ([@xenial](https://t.me/xenial))
* Robert ([@fizdog](https://t.me/fizdog))

*Disclaimer: this README file is still being extended and may lack information*
