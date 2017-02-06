# mattata

mattata is a powerful, plugin-based Telegram bot similar to [topkecleon's](https://github.com/topkecleon/otouto). mattata boasts many nifty features such as a fully-fledged administration plugin, AI (native Cleverbot implementation, which utilises my [mattata-ai](https://github.com/wrxck/mattata-ai) library) and much more.

# Setup

Installing & configuring mattata is very simple.

Clone the repository using `git clone https://github.com/wrxck/mattata` in Terminal. Then, run `cd mattata/; chmod +x ./install.sh; ./install.sh; chmod +x ./launch.sh`. You'll need sudo access to be able to install the dependencies required.

Then, you need to fill in the values in `configuration.lua`. After you've done that, use `./launch.sh` to run your bot.

## API

Using mattata in your code is easy. Each Telegram bot API method has a corresponding function in `mattata.lua`. Below are some common method-binding functions you can into your code.

```Lua
mattata.send_message( -- sendMessage
    chat_id,
    text,
    parse_mode,
    disable_web_page_preview,
    disable_notification,
    reply_to_message_id,
    reply_markup
)
```

## Contribute

As well as feedback and suggestions, you can contribute to the mattata project in the form of a monetary donation. This makes the biggest impact since it helps pay for things such as server hosting and domain registration. A donation of any sum is appreciated and, if you so wish, you can donate [here](https://paypal.me/wrxck).

I'd like to take a moment to thank the following people for their donation:

* Joshua ([@j0shu4](https://t.me/j0shu4))
* Para ([@para949](https://t.me/para949))
* Flo ([@aRandomStranger](https://t.me/aRandomStranger))
* mochi ([@mochicon](https://t.me/mochicon))
* Barend ([@xenial](https://t.me/xenial))
* Robert ([@fizdog](https://t.me/fizdog))
