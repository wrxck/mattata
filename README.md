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

## Contribute

As well as feedback and suggestions, you can contribute to the mattata project in the form of a monetary donation. This makes the biggest impact since it helps pay for things such as server hosting and domain registration. A donation of any sum is appreciated and, if you so wish, you can donate [here](https://paypal.me/wrxck).

I'd like to take a moment to thank the following people for their donation:

* j0shu4
* para949
* aRandomStranger
* mochicon
* xenial
* fizdog
