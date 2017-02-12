# mattata

mattata is a powerful, plugin-based Telegram bot similar to [topkecleon's](https://github.com/topkecleon/otouto). mattata boasts many nifty features such as a fully-fledged administration plugin, AI (native Cleverbot implementation, which utilises my [mattata-ai](https://github.com/wrxck/mattata-ai) library) and much more.

## Setup

Installing & configuring mattata is very simple.

Clone the repository using:

```Bash
git clone https://github.com/wrxck/mattata
```

in Terminal. Then, run the following:

```Bash
cd mattata/
chmod +x ./install.sh
./install.sh
chmod +x ./launch.sh
```

You'll need sudo access to be able to install the dependencies required. Then, you need to fill in the values in `configuration.lua`. After you've done that, use:

```Bash
./launch.sh
```

to run your bot.

## Plugins

mattata features an extensive, robust plugin system, similar to [topkecleon's](https://github.com/topkecleon/otouto). Below is a table containing a list of currently-documented plugins and their corresponding usage information.

| Name            | Usage                                                                                                                                                                                                                                                                                                                                                                                      |
|-----------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| apod            | /apod \<DD/MM/YYYY\> - Sends the Astronomy Picture of the Day.                                                                                                                                                                                                                                                                                                                             |
| appstore        | /appstore \<query\> - Returns the first app that iTunes returns for the given search query. Alias: /app.                                                                                                                                                                                                                                                                                   |
| avatar          | /avatar \<user\> - Sends the profile photos of the given user, of which can be specified by username or numerical ID. If a number is given after the username, then the nth profile photo is sent (if available).                                                                                                                                                                          |
| base64          | /base64 \<string\> - Converts the given string to base64. Alias: /b64.                                                                                                                                                                                                                                                                                                                     |
| binary          | /binary \<number\> - Converts the given number to binary. Alias: /bin.                                                                                                                                                                                                                                                                                                                     |
| bing            | /bing \<query\> - Returns Bing's top search results for the given query.                                                                                                                                                                                                                                                                                                                   |
| bugreport       | /bugreport \<message\> - Report a bug to the developer. Aliases: /bug, /br.                                                                                                                                                                                                                                                                                                                |
| calc            | /calc \<expression\> - Calculates solutions to mathematical expressions. The results are provided by mathjs.org.                                                                                                                                                                                                                                                                           |
| canitrust       | /canitrust \<url\> - Tells you of any known security issues with a website.                                                                                                                                                                                                                                                                                                                |
| catfact         | /catfact - Sends a random cat-related fact!                                                                                                                                                                                                                                                                                                                                                |
| cats            | /cat - A random picture of a cat!                                                                                                                                                                                                                                                                                                                                                          |
| channel         | /ch \<channel\> \<message\> - Sends a message to a Telegram channel/group. The channel/group can be specified via ID or username. Messages can be formatted with Markdown. Users can only send messages to channels/groups they own and/or administrate.                                                                                                                                   |
| chuck           | /chuck - Generates a Chuck Norris joke!                                                                                                                                                                                                                                                                                                                                                    |
| coinflip        | /coinflip \<guess\> - Flips a coin and returns the result! If no arguments are given, the result of a random coin flip is returned; if, however, an argument is given, the result of the random coin flip tests against your guess and returns the result and whether your guess was correct. Alias: /cf.                                                                                  |
| copypasta       | /copypasta - Riddles the replied-to message with cancerous emoji. Alias: /😂.                                                                                                                                                                                                                                                                                                              |
| currency        | /currency \<amount\> \<from\> TO \<to\> - Converts exchange rates for various currencies. Source: Google Finance. Aliases: /convert, /cash.                                                                                                                                                                                                                                                |
| dice            | /dice \<number of dice to roll\> \<range of numbers on the dice\> - Rolls a die a given amount of times, with a given range.                                                                                                                                                                                                                                                               |
| dictionary      | /dictionary \<word\> - Searches the Oxford Dictionary for the given word and returns the definition. Alias: /define.                                                                                                                                                                                                                                                                       |
| dns             | /dns \<url\> \<type\> - Sends DNS records of the given type for the given url. The types currently supported are AAAA, A, CERT, CNAME, DLV, IPSECKEY, MX, NS, PTR, SIG, SRV and TXT. doge                                                                                                                                                                                                  |
| doggo           | /doggo - Sends a cute lil' doggo!                                                                                                                                                                                                                                                                                                                                                          |
| echo            | /echo \<text\> - Repeats a string of text. /bigtext \<text\> - Converts standard text into large letters.                                                                                                                                                                                                                                                                                  |
| eightball       | /eightball - Returns your destined decision through mattata's sixth sense. Alias: /8ball.                                                                                                                                                                                                                                                                                                  |
| emoji           | /emoji \<emoji\> - Sends information about the given emoji.                                                                                                                                                                                                                                                                                                                                |
| facebook        | /facebook \<username\> - Sends the profile picture of the given Facebook user. Alias: /fb.                                                                                                                                                                                                                                                                                                 |
| fact            | /fact - Returns a random fact, which probably isn't even going to be factual but what the heck!                                                                                                                                                                                                                                                                                            |
| flickr          | /flickr \<query\> - Sends the first result for the given query from Flickr.                                                                                                                                                                                                                                                                                                                |
| fortune         | /fortune - Send your fortune.                                                                                                                                                                                                                                                                                                                                                              |
| game            | /game - Challenge somebody to a game of Tic Tac Toe! Use /game stats to view your game statistics.                                                                                                                                                                                                                                                                                         |
| gif             | /gif \<query\> - Searches Giphy for the given query and returns a random result. Alias: /giphy.                                                                                                                                                                                                                                                                                            |
| github          | /github \<username\> \<repository\> - Returns information about the specified GitHub repository.                                                                                                                                                                                                                                                                                           |
| gsearch         | /google \<query\> - Displays the top results from Google for the given search query.                                                                                                                                                                                                                                                                                                       |
| hackernews      | /hackernews - Sends the top stories from Hacker News. Alias: /hn.                                                                                                                                                                                                                                                                                                                          |
| help            | /help \<plugin\> - Usage information for the given plugin.                                                                                                                                                                                                                                                                                                                                 |
| hexadecimal     | /hexadecimal \<string\> - Converts the given string to hexadecimal. Alias: /hex.                                                                                                                                                                                                                                                                                                           |
| hextorgb        | /hextorgb \<colour hex\> - Converts the given colour hex to its RGB format.                                                                                                                                                                                                                                                                                                                |
| id              | /id \<user\> - Sends the name, ID, and (if applicable) username for the given user, group, channel or bot. Input is also accepted via reply. Alias: /whois.                                                                                                                                                                                                                                |
| identicon       | /identicon \<string\> - Converts the given string of text to an identicon.                                                                                                                                                                                                                                                                                                                 |
| imdb            | /imdb \<query\> - Returns an IMDb entry.                                                                                                                                                                                                                                                                                                                                                   |
| instagram       | /instagram \<user\> - Sends the profile picture of the given Instagram user. Alias: /ig.                                                                                                                                                                                                                                                                                                   |
| insult          | /insult - Sends a random insult.                                                                                                                                                                                                                                                                                                                                                           |
| isp             | /isp \<url\> - Sends information about the given url's ISP.                                                                                                                                                                                                                                                                                                                                |
| ispwned         | /ispwned \<username/email\> - Tells you if the given username/email has been identified in any data leaks.                                                                                                                                                                                                                                                                                 |
| isup            | /isup \<url\> - Check if the specified url is down for everyone or just for you.                                                                                                                                                                                                                                                                                                           |
| itunes          | /itunes \<song\> - Returns information about the given song, from iTunes.                                                                                                                                                                                                                                                                                                                  |
| jsondump        | /jsondump - Returns the raw json of your message.                                                                                                                                                                                                                                                                                                                                          |
| lastfm          | /np \<username\> - Returns what you are or were last listening to. If you specify a username, info will be returned for that username./fmset <username> - Sets your last.fm username. Use /fmset -del to delete your current username.                                                                                                                                                     |
| lmgtfy          | /lmgtfy \<query\> - Sends a LMGTFY link for the given search query.                                                                                                                                                                                                                                                                                                                        |
| location        | /location \<query\> - Sends your location, or a location from Google Maps. Alias: /loc.                                                                                                                                                                                                                                                                                                    |
| loremipsum      | /loremipsum - Generates a few Lorem Ipsum sentences!                                                                                                                                                                                                                                                                                                                                       |
| lyrics          | /lyrics \<query\> - Find the lyrics to the specified song.                                                                                                                                                                                                                                                                                                                                 |
| me              | /me \<emote message\> - Allows you to emote.                                                                                                                                                                                                                                                                                                                                               |
| minecraft       | /minecraft \<username\> - Get information about the given Minecraft player.                                                                                                                                                                                                                                                                                                                |
| msglink         | /msglink - Gets the link to the replied-to message.                                                                                                                                                                                                                                                                                                                                        |
| netflix         | /netflix \<query\> - Search Netflix for the given query.                                                                                                                                                                                                                                                                                                                                   |
| news            | /news \<source\> - Sends the current top story from the given news source. Use /nsources to view a list of available sources.                                                                                                                                                                                                                                                              |
| ninegag         | /ninegag - Returns a random image from the latest 9gag posts.                                                                                                                                                                                                                                                                                                                              |
| paste           | /paste \<text\> - Uploads the given text to a pasting service and returns the result URL.                                                                                                                                                                                                                                                                                                  |
| pay             | /pay \<amount\> - Sends the replied-to user the given amount of mattacoins. Use /balance (or /bal) to view your current balance.                                                                                                                                                                                                                                                           |
| plugins         | /plugins - Toggle the plugins you want to use in your chat with a slick inline keyboard, paginated and neatly formatted.                                                                                                                                                                                                                                                                   |
| pokedex         | /pokedex \<query\> - Returns a Pokedex entry from pokeapi.co. Alias: /dex.                                                                                                                                                                                                                                                                                                                 |
| prime           | /prime \<number\> - Tells you if a number is prime or not.                                                                                                                                                                                                                                                                                                                                 |
| pun             | /pun - Generates a random pun.                                                                                                                                                                                                                                                                                                                                                             |
| qr              | /qr \<string\> - Converts the given string to an QR code. Alias: /qrcode.                                                                                                                                                                                                                                                                                                                  |
| randomword      | /randomword - Generates a random word. Alias: /rw.                                                                                                                                                                                                                                                                                                                                         |
| reddit          | /reddit \<r/subreddit \| query\> Returns the top posts or results for a given subreddit or query. If no argument is given, the top posts from reddit's /r/all board are returned. Aliases: /r, /r/subreddit.                                                                                                                                                                               |
| rimg            | /rimg \<width\> \<height\> - Sends a random image which matches the dimensions provided, in pixels. If only 1 dimension is given, the other is assumed to be the same. Append -g to the end of your message to return a grayscale photo, or append -b to the end of your message to return a blurred photo. The maximum value for each dimension is 5000, and the minimum for each is 250. |
| rss             | /rss \<sub \| del\> \<url\> - Subscribe or unsubscribe from the given RSS feed.                                                                                                                                                                                                                                                                                                            |
| sed             | s/\<pattern\>/\<substitution\> - Replaces all occurences, of text matching a given Lua pattern, with the given substitution.                                                                                                                                                                                                                                                               |
| setlang         | /setlang - Set your language.                                                                                                                                                                                                                                                                                                                                                              |
| setloc          | /setloc \<location\> - Sets your location to the given value.                                                                                                                                                                                                                                                                                                                              |
| shorten         | /shorten \<url\> - Shortens the given URL using a choice of multiple URL shorteners.                                                                                                                                                                                                                                                                                                       |
| shout           | /shout \<text\> - Shout something in multiple directions.                                                                                                                                                                                                                                                                                                                                  |
| slap            | /slap \<target\> - Slap someone!                                                                                                                                                                                                                                                                                                                                                           |
| snapchat        | /snapchat \<username\> - Sends the Snap code for the given Snapchat username. Aliases: /snap, /sc.                                                                                                                                                                                                                                                                                         |
| spotify         | /spotify \<query\> - Shows information about the top result for the given search query on Spotify.                                                                                                                                                                                                                                                                                         |
| statistics      | /statistics - View statistics about the chat you are in. Only the top 10, most-talkative users are listed.                                                                                                                                                                                                                                                                                 |
| steam           | /steam \<username\> - Display information about the given Steam user. If no username is specified then information about your Steam account (if applicable) is sent. Use /setsteam \<username\> to set your username.                                                                                                                                                                      |
| synonym         | /synonym \<word\> - Sends a synonym of the given word.                                                                                                                                                                                                                                                                                                                                     |
| time            | /time \<query\> - Returns the time, date, and timezone for your location, if you've set one with '/setloc \<query\>'. If an argument is given, the time for the given place will be sent.                                                                                                                                                                                                  |
| translate       | /translate \<language\> \<text\> - Translates input into the given language (if arguments are given), else the replied-to message is translated into mattata's language. Alias: /tl.                                                                                                                                                                                                       |
| twitch          | /twitch \<query\> - Searches Twitch for streams matching the given query.                                                                                                                                                                                                                                                                                                                  |
| unicode         | /unicode \<text\> - Returns the given text as a json-encoded table of Unicode (UTF-32) values.                                                                                                                                                                                                                                                                                             |
| urbandictionary | /urbandictionary \<query\> - Returns the Urban Dictionary's definition for the given word. Aliases: /urban, /ud.                                                                                                                                                                                                                                                                           |
| uuid            | /uuid - Generates a random UUID.                                                                                                                                                                                                                                                                                                                                                           |
| weather         | /weather \<location\> - Sends the current weather for the given location.                                                                                                                                                                                                                                                                                                                  |
| whois           | /whois \<IP address\> - Displays the WHOIS look-up result for the given IP address.                                                                                                                                                                                                                                                                                                        |
| wikipedia       | /wikipedia \<query\> - Returns an article from Wikipedia. Aliases: /wiki, /w.                                                                                                                                                                                                                                                                                                              |
| xkcd            | /xkcd \<i\> - Returns the latest xkcd strip and its alt text. If a number is given, returns that number strip. If 'r' is passed in place of a number, returns a random strip.                                                                                                                                                                                                              |
| yify            | /yify \<query\> - Searches Yify torrents for the given query.                                                                                                                                                                                                                                                                                                                              |
| yomama          | /yomama - Tells a Yo' Mama joke!                                                                                                                                                                                                                                                                                                                                                           |
| youtube         | /youtube \<query\> - Sends the top results from YouTube for the given search query. Alias: /yt.                                                                                                                                                                                                                                                                                            |

## Telegram API

Below you will find each currently-documented method and its corresponding function and information.

### sendMessage

Use this function to send text messages using Telegram's `sendMessage` method.

```Lua
mattata.send_message(
    chat_id,
    text,
    parse_mode,
    disable_web_page_preview,
    disable_notification,
    reply_to_message_id,
    reply_markup
)
```

| Parameters                  | Type                                                                             | Required | Description                                                                                                                                                                    |
|-----------------------------|----------------------------------------------------------------------------------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| chat\_id                    | Integer or String                                                                | Yes      | Unique identifier for the target chat or username of the target channel (in the format @channelusername)                                                                       |
| text                        | String                                                                           | Yes      | Text of the message to be sent                                                                                                                                                 |
| parse\_mode                 | String                                                                           | Optional | Send `Markdown` or `HTML`, if you want Telegram apps to show bold, italic, fixed-width text or inline URLs in your bot's message.                                              |
| disable\_web\_page\_preview | Boolean                                                                          | Optional | Disables link previews for links in this message                                                                                                                               |
| disable\_notification       | Boolean                                                                          | Optional | Sends the message silently. iOS users will not receive a notification, Android users will receive a notification with no sound.                                                |
| reply\_to\_message\_id      | Integer                                                                          | Optional | If the message is a reply, ID of the original message                                                                                                                          |
| reply\_markup               | InlineKeyboardMarkup or ReplyKeyboardMarkup or ReplyKeyboardRemove or ForceReply | Optional | Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user. |

### forwardMessage

Use this function to forward messages of any kind using Telegram's `forwardMessage` method.

```Lua
mattata.forward_message(
    chat_id,
    from_chat_id,
    disable_notification,
    message_id
)
```

| Parameters            | Type              | Required | Description                                                                                                                     |
|-----------------------|-------------------|----------|---------------------------------------------------------------------------------------------------------------------------------|
| chat\_id              | Integer or String | Yes      | Unique identifier for the target chat or username of the target channel (in the format @channelusername)                        |
| from\_chat\_id        | Integer or String | Yes      | Unique identifier for the chat where the original message was sent (or channel username in the format @channelusername)         |
| disable\_notification | Boolean           | Optional | Sends the message silently. iOS users will not receive a notification, Android users will receive a notification with no sound. |
| message\_id           | Integer           | Yes      | Message identifier in the chat specified in *from\_chat\_id*                                                                    |

### sendPhoto

Use this function to send photos using Telegram's `sendPhoto` method.

```Lua
mattata.send_photo(
    chat_id,
    photo,
    caption,
    disable_notification,
    reply_to_message_id,
    reply_markup
)
```

| Parameters             | Type                                                                             | Required | Description                                                                                                                                                                                                                              |
|------------------------|----------------------------------------------------------------------------------|----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| chat\_id               | Integer or String                                                                | Yes      | Unique identifier for the target chat or username of the target channel (in the format @channelusername)                                                                                                                                 |
| photo                  | InputFile or String                                                              | Yes      | Photo to send. Pass a file\_id as String to send a photo that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get a photo from the Internet, or upload a new photo using multipart/form-data. |
| caption                | String                                                                           | Optional | Photo caption (may also be used when resending photos by *file\_id*), 0-200 characters                                                                                                                                                   |
| disable\_notification  | Boolean                                                                          | Optional | Sends the message silently. iOS users will not receive a notification, Android users will receive a notification with no sound.                                                                                                          |
| reply\_to\_message\_id | Integer                                                                          | Optional | If the message is a reply, ID of the original message                                                                                                                                                                                    |
| reply\_markup          | InlineKeyboardMarkup or ReplyKeyboardMarkup or ReplyKeyboardRemove or ForceReply | Optional | Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.                                                           |

### sendAudio

Use this function to send audio files using Telegram's `sendAudio` method, if you want Telegram clients to display them in the music player. Your audio must be in the `.mp3` format. Bots can currently send audio files of up to 50 MB in size, this limit may be changed in the future.

```Lua
mattata.send_audio(
    chat_id,
    audio,
    caption,
    duration,
    performer,
    title,
    disable_notification,
    reply_to_message_id,
    reply_markup
)
```

| Parameters             | Type                                                                             | Required | Description                                                                                                                                                                                                                                             |
|------------------------|----------------------------------------------------------------------------------|----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| chat\_id               | Integer or String                                                                | Yes      | Unique identifier for the target chat or username of the target channel (in the format @channelusername)                                                                                                                                                |
| audio                  | InputFile or String                                                              | Yes      | Audio file to send. Pass a file\_id as String to send an audio file that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get an audio file from the Internet, or upload a new one using multipart/form-data. |
| caption                | String                                                                           | Optional | Audio caption, 0-200 characters                                                                                                                                                                                                                         |
| duration               | Integer                                                                          | Optional | Duration of the audio in seconds                                                                                                                                                                                                                        |
| performer              | String                                                                           | Optional | Performer                                                                                                                                                                                                                                               |
| title                  | String                                                                           | Optional | Track name                                                                                                                                                                                                                                              |
| disable\_notification  | Boolean                                                                          | Optional | Sends the message silently. iOS users will not receive a notification, Android users will receive a notification with no sound.                                                                                                                         |
| reply\_to\_message\_id | Integer                                                                          | Optional | If the message is a reply, ID of the original message                                                                                                                                                                                                   |
| reply\_markup          | InlineKeyboardMarkup or ReplyKeyboardMarkup or ReplyKeyboardRemove or ForceReply | Optional | Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.                                                                          |                                                                        |

### sendDocument

Use this function to send general files using Telegram's `sendDocument` method. Bots can currently send files of any type of up to 50 MB in size, this limit may be changed in the future.

```Lua
mattata.send_document(
    chat_id,
    document,
    caption,
    disable_notification,
    reply_to_message_id,
    reply_markup
)
```

| Parameters             | Type                                                                             | Required | Description                                                                                                                                                                                                                         |
|------------------------|----------------------------------------------------------------------------------|----------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| chat\_id               | Integer or String                                                                | Yes      | Unique identifier for the target chat or username of the target channel (in the format @channelusername)                                                                                                                            |
| document               | InputFile or String                                                              | Yes      | File to send. Pass a file\_id as String to send a file that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get a file from the Internet, or upload a new one using multipart/form-data. |
| caption                | String                                                                           | Optional | Document caption (may also be used when resending documents by *file\_id*), 0-200 characters                                                                                                                                        |
| disable\_notification  | Boolean                                                                          | Optional | Sends the message silently. iOS users will not receive a notification, Android users will receive a notification with no sound.                                                                                                     |
| reply\_to\_message\_id | Integer                                                                          | Optional | If the message is a reply, ID of the original message                                                                                                                                                                               |
| reply\_markup          | InlineKeyboardMarkup or ReplyKeyboardMarkup or ReplyKeyboardRemove or ForceReply | Optional | Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.                                                      |

### sendSticker

Use this function to send `.webp` stickers using Telegram's `sendSticker` method.

```Lua
mattata.send_sticker(
    chat_id,
    sticker,
    disable_notification,
    reply_to_message_id,
    reply_markup
)
```

| Parameters             | Type                                                                             | Required | Description                                                                                                                                                                                                                                    |
|------------------------|----------------------------------------------------------------------------------|----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| chat\_id               | Integer or String                                                                | Yes      | Unique identifier for the target chat or username of the target channel (in the format @channelusername)                                                                                                                                       |
| sticker                | InputFile or String                                                              | Yes      | Sticker to send. Pass a file\_id as String to send a file that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get a `.webp` file from the Internet, or upload a new one using multipart/form-data. |
| disable\_notification  | Boolean                                                                          | Optional | Sends the message silently. iOS users will not receive a notification, Android users will receive a notification with no sound.                                                                                                                |
| reply\_to\_message\_id | Integer                                                                          | Optional | If the message is a reply, ID of the original message                                                                                                                                                                                          |
| reply\_markup          | InlineKeyboardMarkup or ReplyKeyboardMarkup or ReplyKeyboardRemove or ForceReply | Optional | Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.                                                                 |

### sendVideo

Use this function to send video files using Telegram's `sendVideo` method. Telegram clients support `.mp4` videos (other formats may be sent using `sendDocument`). Bots can currently send video files of up to 50 MB in size, this limit may be changed in the future.

```Lua
mattata.send_video(
    chat_id,
    video,
    duration,
    width,
    height,
    caption,
    disable_notification,
    reply_to_message_id,
    reply_markup
)
```

| Parameters             | Type                                                                             | Required | Description                                                                                                                                                                                                                              |
|------------------------|----------------------------------------------------------------------------------|----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| chat\_id               | Integer or String                                                                | Yes      | Unique identifier for the target chat or username of the target channel (in the format @channelusername)                                                                                                                                 |
| video                  | InputFile or String                                                              | Yes      | Video to send. Pass a file\_id as String to send a video that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get a video from the Internet, or upload a new video using multipart/form-data. |
| duration               | Integer                                                                          | Optional | Duration of sent video in seconds                                                                                                                                                                                                        |
| width                  | Integer                                                                          | Optional | Video width                                                                                                                                                                                                                              |
| height                 | Integer                                                                          | Optional | Video height                                                                                                                                                                                                                             |
| caption                | String                                                                           | Optional | Video caption (may also be used when resending videos by *file\_id*), 0-200 characters                                                                                                                                                   |
| disable\_notification  | Boolean                                                                          | Optional | Sends the message silently. iOS users will not receive a notification, Android users will receive a notification with no sound.                                                                                                          |
| reply\_to\_message\_id | Integer                                                                          | Optional | If the message is a reply, ID of the original message                                                                                                                                                                                    |
| reply\_markup          | InlineKeyboardMarkup or ReplyKeyboardMarkup or ReplyKeyboardRemove or ForceReply | Optional | Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.                                                           |

### sendVoice

Use this function to send audio files using Telegram's `sendVoice` method, if you want Telegram clients to display the file as a playable voice message. For this to work, your audio must be in an `.ogg` file encoded with `OPUS` (other formats may be sent as Audio or Document). Bots can currently send voice messages of up to 50 MB in size, this limit may be changed in the future.

```Lua
mattata.send_voice(
    chat_id,
    voice,
    caption,
    duration,
    disable_notification,
    reply_to_message_id,
    reply_markup
)
```

| Parameters             | Type                                                                             | Required | Description                                                                                                                                                                                                                               |
|------------------------|----------------------------------------------------------------------------------|----------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| chat\_id               | Integer or String                                                                | Yes      | Unique identifier for the target chat or username of the target channel (in the format @channelusername)                                                                                                                                  |
| voice                  | InputFile or String                                                              | Yes      | Audio file to send. Pass a file\_id as String to send a file that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get a file from the Internet, or upload a new one using multipart/form-data. |
| caption                | String                                                                           | Optional | Voice message caption, 0-200 characters                                                                                                                                                                                                   |
| duration               | Integer                                                                          | Optional | Duration of the voice message in seconds                                                                                                                                                                                                  |
| disable\_notification  | Boolean                                                                          | Optional | Sends the message silently. iOS users will not receive a notification, Android users will receive a notification with no sound.                                                                                                           |
| reply\_to\_message\_id | Integer                                                                          | Optional | If the message is a reply, ID of the original message                                                                                                                                                                                     |
| reply\_markup          | InlineKeyboardMarkup or ReplyKeyboardMarkup or ReplyKeyboardRemove or ForceReply | Optional | Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.                                                            |

### sendLocation

Use this function to send a location on a map using Telegram's `sendLocation` method.

```Lua
mattata.send_location(
    chat_id,
    latitude,
    longitude,
    disable_notification,
    reply_to_message_id,
    reply_markup
)
```

| Parameters             | Type                                                                             | Required | Description                                                                                                                                                                    |
|------------------------|----------------------------------------------------------------------------------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| chat\_id               | Integer or String                                                                | Yes      | Unique identifier for the target chat or username of the target channel (in the format @channelusername)                                                                       |
| latitude               | Float number                                                                     | Yes      | Latitude of location                                                                                                                                                           |
| longitude              | Float number                                                                     | Yes      | Longitude of location                                                                                                                                                          |
| disable\_notification  | Boolean                                                                          | Optional | Sends the message silently. iOS users will not receive a notification, Android users will receive a notification with no sound.                                                |
| reply\_to\_message\_id | Integer                                                                          | Optional | If the message is a reply, ID of the original message                                                                                                                          |
| reply\_markup          | InlineKeyboardMarkup or ReplyKeyboardMarkup or ReplyKeyboardRemove or ForceReply | Optional | Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user. |

## External Usage

You can use the mattata API without initialising the entire library (i.e. no plugin system etc.) by referencing the library in your code. This can be done in the following way:

```Lua
local mattata = require('mattata')
-- Blah, blah; your code goes here
```

Now, if you wish to make a request to the Telegram API, you need to use the `mattata.request()` function; which takes 4 parameters. Below is a table containing each parameter, the type of value it takes and a brief description of what it's for.

| Parameters | Type                | Required | Description                                                                                                                                                                                                               |
|------------|---------------------|----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| endpoint   | String              | Yes      | The API URL (with the token and method) which you'd like to make the request to (e.g. `https://api.telegram.org/bot123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11/sendMessage`)                                                |
| parameters | Table               | Yes      | A key-value table of parameters and their respective values (if you're using the official Telegram bot API, check out the documented examples above)                                                                      |
| file       | InputFile or String | Optional | A table of a single key/value pair, where the key is the name of the parameter and the value is the filename (if these are included in parameters instead, mattata will attempt to send the filename as a file ID or URL) |
| timeout    | Boolean             | Optional | If set to true, the request will timeout after 1 second                                                                                                                                                                   |

Here's an example script which, when executed, will send the message `Hello, World!` to the chat ID `-100123456789` using the `sendMessage` method via the default API endpoint, `https://api.telegram.org/bot`, using the token `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`:

```Lua
local mattata = require('mattata') -- Load the library

local request, code =  mattata.request( -- Make the request to the Telegram bot API
    'https://api.telegram.org/bot123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11/sendMessage',
    {
        ['chat_id'] = -100123456789,
        ['text'] = 'Hello, World!'
    }
)

if not request then
    print('The Telegram bot API returned the following error: ' .. code)
    return false
end

return true
```

It is easier to make requests if you're using mattata for its intended purpose (a plugin-based bot), however it really is that easy to make a request to the bot API - in any snippet of Lua!

Here's an example bot which uses long-polling to get updates, and responds to `/ping` with `PONG`:

```Lua
api = require('mattata')
token = '' -- Enter your token here
last = last or 0
while true do
    local request = api.get_updates(
        5,
        last + 1,
        token
    )
    if request then
        for _, update in ipairs(request.result) do
            last = update.update_id
            if update.message and update.message.text and update.message.text == '/ping' then
                api.request(
                    string.format(
                        'https://api.telegram.org/bot%s/sendMessage',
                        token
                    ),
                    {
                        ['chat_id'] = update.message.chat.id,
                        ['text'] = 'PONG'
                    }
                )
            end
        end
    else
        print('Error')
    end
end
```

## Contribute

As well as feedback and suggestions, you can contribute to the mattata project in the form of a monetary donation. This makes the biggest impact since it helps pay for things such as server hosting and domain registration. A donation of any sum is appreciated and, if you so wish, you can donate [here](https://paypal.me/wrxck).

I'd like to take a moment to thank the following people for their donation:

* j0shu4
* para949
* aRandomStranger
* mochicon
* xenial
* fizdog
* caidens
