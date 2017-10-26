![mattata](https://raw.githubusercontent.com/wrxck/mattata/master/assets/logo.png)

mattata is a powerful, plugin-based Telegram bot similar to [topkecleon's](https://github.com/topkecleon/otouto). mattata boasts many nifty features such as a fully-fledged administration plugin, AI (native Cleverbot implementation, which utilises my [mattata-ai](https://github.com/wrxck/mattata-ai) library) and much more.

![Setup](https://raw.githubusercontent.com/wrxck/mattata/master/assets/setup.png)

Installing & configuring mattata is very simple. Clone the repository using `git clone git://github.com/wrxck/mattata.git`. Then, run the appropriate installation script located inside mattata/install/.
You'll need sudo access to be able to install the dependencies required. Then, you need to fill in the values in configuration.example.lua. After you've done that, rename configuration.example.lua to configuration.lua, and use ./launch.sh to start your bot.

![Plugins](https://raw.githubusercontent.com/wrxck/mattata/master/assets/plugins.png)

mattata features an extensive, robust plugin system, similar to [topkecleon's](https://github.com/topkecleon/otouto). Below is a table containing a list of currently-documented plugins and their corresponding usage information.

| Command| Description| Aliases| Flag |
|--------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------|------|
| /administration | Configure the administration settings for your chat through an interactive menu sent via private message. | | 2 |
| /admins | Lists information about the current supergroups staff. | /staff | 1 |
| /whitelistlink \<link> | Allows for the given link to be used in the current chat. | | 2 |
| /afk [note] | Inform Mattata and others when you're Away From Keyboard. An optional note can be given. | | 1 |
| /antispam | Shortcut to the anti-spam settings in administration. | | 2 |
| /appstore \<query> | Displays information about the first app returned by iTunes for the given search query. | /app | 1 |
| /authspotify \<token> | Allows you to authenticate your Spotify account with Mattata when a token is supplied. | | 1 |
| /avatar \<user> [offset] | Sends the profile photos of the given user, of which can be specified by username or numerical ID. If an offset is given after the username (which must be a numerical value), then the nth profile photo is sent (if available). | | 1 |
| /ban [user] | Bans a user from the group. The user must be specified by username/ID, or by reply. | | 1 |
| /bash \<snippet> | Executes a snippet of Bash on the host server, and returns the result. | | 4 |
| /bing \<query> | Searches Bing for the given search query and returns the top results. | | 1 |
| /blacklistchat \<chat> | Prevents the bot being used in the specified chat. | | 4 |
| /blacklist [user] | Prevents a user from using the bot in the chat. The user must be specified by username/ID, or by reply. | | 2 |
| /bugreport \<text> | Reports a bug to the configured developer. | /ops /bug /br | 1 |
| /calc \<expression> | Solves the given mathematical expression using mathjs.org. | | 1 |
| /cat | Sends a random photo of a cat. | /sarah | 1 |
| /commandstats | Returns statistics of the most commonly used commands in the current group. | /cmdstats | 1 |
| /reload | Reloads the bot. | /reboot /icanhasreboot | 4 |
| /copypasta |  Riddles the replied-to message with cancerous emoji. | /😂 | 1 |
| /counter | Adds a view count to the replied-to message. | /count | 1 |
| /currency \<amount> \<from> to \<to> | Converts exchange rates for various currencies via Google Finance. | /convert /cash | 1 |
| /custom \<new \| del \|list> [#trigger][value] | Define your own response to a #hashtag trigger. | /hashtag /trigger | 1 |
| /delete [message ID] | Deletes the specified (or replied-to) message. | | 2 |
| /demote [user] | Strip a user of their moderator status. The user must be specified by username, ID, or by reply. | /demod | 3 |
| /developer | Connect with the developer through his social media. | /dev | 1 |
| /dictionary \<word> | Looks up the given word in the Oxford Dictionary and returns the relevant definition(s). | /define | 1 |
| /doge | Doge-ifies the given text. Sentences are separated using slashes. Example: /doge hello world/this is a test sentence/make sure you type like this/else it won't work! | /dogify | 1 |
| /donate | Make an optional monetary contribution to the mattata project. | | 1 |
| /drawtext \<text> | Returns an image with your supplied text. | | 1 |
| /exec \<language> \<code> |  Executes the specified code in the given language and returns the output. | | 1 |
| /facebook \<username> | Sends the profile picture of the given Facebook user. | /fb | 1 |
| /fact | Returns a random (and somewhat-false!) fact. | | 1 |
| /filter \<words> | Add to the list of words that users will be kicked upon for saying. | | 2 |
| /flickr \<query> | Searches Flickr for a photo matching the given search query and returns the most relevant result. | | 1 |
| /game | A fun little Tic-Tac-Toe game you can play with your friends. | | 1 |
| /gblacklist [user] | Globally blacklists the replied to or specified user. | | 4 |
| /gif \<query> | Searches GIPHY for the given search query and returns a random, relevant result. | /giphy | 1 |
| /github \<user> \<repository>  | Returns information about the specified GitHub repository. | /gh | 1 |
| /google \<query> | Searches Google for the given search query and returns the most relevant result(s). | /g | 1 |
| /groups \<query> | Lists Mattata supported groups. |  | 1 |
| /gwhitelist [user] | Globally white-lists the replied to or specified user | | 4 |
| /hackernews | Sends the top stories from Hacker News. | /hn | 1 |
| /help | A help-orientated menu with a sleep in-line keyboard for navigation. | /start | 1 |
| /id [chat] | Sends information about the given chat. Input is also accepted via reply. | /whoami | 1 |
| /imdb \<query> | Searches IMDb for the given search query and returns the most relevant result(s). | | 1 |
| /imgur | Uploads the replied-to image to imgur. | | 1 |
| /import \<group ID> | Import administrative settings & toggled plugins from another mattata-administrated group. | | 4 |
| /info | View system information & statistics about the bot. | | 1 |
| /instagram \<username> | Sends the profile picture of the given Instagram user. | /ig | 1 |
| /ipsw | A Telegram interface for ipsw.me | | 1 |
| /ispwned \<account> | Returns the existence of the given account in any major data leaks. | | 1 |
| /itunes [query] | Searches Itunes for the given query and returns the top result. | | 1 |
| /jsondump | sends the JSON object of the replied to message. | /json | 1 |
| /kick [user] | Bans, then unbans, a user from the chat (also known as a "soft-ban"). The user must be specified by username/ID, or by reply. | | 2 |
| /languages | Shows information about languages Mattata needs support for. | | 1 |
| /lastfm | Gives information about how to link your last.fm account and receive information about your last played track. | | 1 |
| /np [username] | Returns what you or the given username had last listened to on Last.fm  | | 1 |
| /fmset \<username> [-del] | Sets your last.fm username. Use /fmset -del to delete your current username. | | 1 |
| /link | Returns the link to the current group. | | 1 |
| /location [query] | Sends your location, or a location from Google Maps. | /loc | 1 |
| /logchat [chat username/ID] | Specify the chat in which to log all administrative actions. | | 4 |
| /lua \<snippet> | Executes a snippet of Lua on the host server, and returns the result. | | 4 |
| /lyrics \<query> | Finds the lyrics to the given track. | | 1 |
| /meme \<query> | Generates an image macro with the given text, on your choice of the available selection of templates. This command can only be used in-line. | /memegen | 1 |
| /minecraft \<username> | returns the UUID and avatar of the given MineCraft username. | /mc | 1 |
| /mute [username] | Prevents the supplied user from speaking in this chat. | | 2 |
| /myspotify | Returns a user interface to control Spotify. | | 1 |
| /name \<text> | Change the name the bot responds to. | | 4 |
| /netflix \<query> |  Searches Netflix for the given search query and returns the most relevant result. | /nf | 1 |
| /newchat \<chat>| Adds the given chat to the list that'll be shown in /groups | | 4 |
| /news \<news source> | Sends the current top story from the given news source. | | 1 |
| /nsources | Lists available news sources for the /news command. | | 1 |
| /setnews \<source> | Sets your preferred news source. | | 1 |
| /nick \<nickname> [-del] | Set your nickname. -del will remove any set nickname. | | 1 |
| /nodelete [add \| del] <plugins> | Allows the given plugins to retain the commands they were executed with by white listing them from the "delete commands" administrative setting. Multiple plugins can be specified. | | 2 |
| /optout | Opt out of data collection. | | 1 |
| /optin | Opt in for data collection. | | 1 |
| /paste | Uploads the given text to a pasting service and returns the result URL. | | 1 |
| /ping | Returns a "PONG" sticker. | | 1 |
| /pin | Pins the replied to message. | | 2 |
| /plugins | Sends you a private message containing an interface to enable and disable plugins for this chat. | | 2 |
| /pokedex \<query> | Returns a Pokedex entry from pokeapi.co. | /dex | 1 |
| /promote [user] | Promotes a user to a moderator of the current chat. This command can only be used by administrators of a supergroup. | /mod | 3 |
| /pun | Returns a pun. | | 1 |
| /purge \<1-25> | Deletes the last X messages. Where X is the number specified between 1 and 25.| | 2 |
| /quote [user] | Returns a random quote. Optionally reply to a user or specify their username to get one of their quotes. | | 1 |
| /quotes | Returns a UI allowing you to view and delete your quotes. | | 1 |
| /r | Reddit... | | 1 |
| /remind \<duration> \<message> | Repeats a message after a duration of time, in the format 2d3h. The maximum number of reminders at one time is 4 per chat, and each reminder must be between 1 hour and 182 days in duration. Reminders cannot be any more than 256 characters in length. Use /reminders to view your current reminders. An example use of this command would be: /remind 21d3h test, which would remind you in 21 days and 3 hours. | | 1 |
| /reminders | Returns a list of your current reminders. | | 1 |
| /report | Reports the replied to message to the chat moderators/administrators. | | 1 |
| /rules | Sends you the chat rules via private message. | | 1 |
| /runescape \<player name> | Displays skill-related information about the given RuneScape player. | | 1 |
| /save | Stores the replied-to message in mattata's database - of which a randomly-selected, saved message from the said user can be retrieved using /quote. | | 1 |
| /setdescription \<text> | Sets the group's description to the given text. The given text must be between 1 and 255 characters in length | | 2 |
| /setgrouplang | Displays a UI allowing you to choose a common language for this group. | | 2 |
| /setlang | Displays a UI allowing you to choose what language you'd like Mattata to use for you. | | 1 |
| /setloc [location] | Allows you to specify your location | | 1 |
| /setrules | Specify the current chat rules. | | 2 |
| /settings | Sends you a message suggesting what settings you may wish to change. | | 1 |
| /settitle | Sets the title of the current group. | | 2 |
| /setwelcome | Sets the welcome message for the current group. | | 2 |
| /share \<url> \<text> | Shares the given URL through an in-line button with the specified text as a caption. | | 1 |
| /shorten \<url> | Shortens the given URL. | | 1 |
| /shsh \<ecid> | Returns a list of all available SHSH blobs for the given device. | | 1 |
| /slap [user] | Slaps the given user. | | 1 |
| /spotify \<query> | Searches spotify for a track matching the given query and returns the most relevant result. | | 1 |
| /statistics | Message statistics for the current chat. | /stats | 1 |
| /steam [username] | Displays information about the given Steam user. If no username is specified then information about your Steam account (if applicable) is sent. | | 1 |
| /setsteam \<username> | Sets your steam username. | | 1 |
| /tempban [user] | Temporarily ban a user from the chat. The user may be specified by username, ID or by replying to one of their messages. | | 2 |
| /time [location] | Returns the time for the given location. If no location is given, it will attempt to use your location (if set) | | 1 |
| /translate [locale] \<text> | If a locale is given, the given text is translated into the said locale's language. If no locale is given then the given text is translated into the bot's configured language. If the command is used in reply to a message containing text, then the replied-to text is translated and the translation is returned. | /tl | 1 |
| /trust [user] | Promotes a user to a trusted user of the current chat. This command can only be used by administrators of a supergroup. | | 3 |
| /twitch \<query> | Searches Twitch for the given search query and returns the most relevant result(s). | | 1 |
| /twitter [text] | Sends a Tweet from your linked Twitter account with the given text as the contents. If the command is used in reply, without any arguments, the replied-to message text is Tweeted instead. Use /authtwitter to authorize your Twitter account. | /tweet | 1 |
| /authtwitter | Authenticates your twitter account within the bot. | | 1 |
| /unban [user] | Unbans the specified user from this chat. | | 2 |
| /unfilter \<words> | Removes the given words from the filter list. | | 2 |
| /unmute [user] | Unmutes the specified user. | | 2 |
| /untrust [user] | Untrusts the specified user. | | 3 |
| /upload | Uploads the replied-to file to the bots server. | | 1 |
| /urbandictionary [query] | Searches the Urban Dictionary for the given query and returns the top results.  | /urban /ud | 1 |
| /user [user] | Returns information about the given user. | /warns /bans /kicks /unbans /warnings /status | 1 |
| /voteban [user] | Elect a user to be vote banned. | | 1 |
| /warn [user] | warn the given user. | | 2 |
| /weather [location] | Gives you a rundown of the weather in the specified location. If no location is given, it will attempt to use your location (if set) | | 1 |
| /whitelist [user] | Whitelists the given user in this chat. | | 2 |
| /wikipedia \<query> | Searches Wikipedia for the given search query and returns the most relevant article. | /wiki /w | 1 |
| /wordfilter | Lists word filters in this chat. | | 1 |
| /xkcd [query] | Returns a random XKCD comic. If a query is given, it will attempt to find a related comic. | | 1 |
| /yify \<query> | Searches Yify Torrents for the given search query and returns the most relevant result(s). | | 1 |
| /youtube \<query> | Searches YouTube for the given search query and returns the most relevant result(s). | /yt | 1 |

Arguments enclosed in [square brackets] are optional, and arguments enclosed in are required.

You will notice there is a "Flag" column. This is a number which indicated what rights the user must have in order to use the corresponding command(s). Below is a table which explains what each number means:

| Flag | Name          | Description                                                                                                                                                                                                                                                                                       |
|------|---------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1    | User          | All users are in this flag by default. It simply means they exist. This is the lowest flag.                                                                                                                                                                                                       |
| 2    | Moderator     | This flag contains all people of the moderator rank and higher. Moderators are non-official admins who have access to administrative commands, such as /ban, /kick and /unban. Moderators are granted this rank when an administrator replies to their message with /mod or /promote.             |
| 3    | Administrator | This flag contains all of the official group administrators. These are all of the people who have been promoted to an administrator by the creator of the group/channel. These people will have a star displayed next to their name in the member list on your client.                            |
| 4    | Owner         | This is a small category containing only the users who are in the admins array of the configuration.lua file. This rank means that the user has access to owner commands such as /bash and /lua, and can control the bot using /reload. This is the highest flag.                               |

All permissions levels are hereditary - meaning a user in flag 3 is also in flags 1 & 2.

![Contribute](https://raw.githubusercontent.com/wrxck/mattata/master/assets/contribute.png)

As well as feedback and suggestions, you can contribute to the mattata project in the form of a monetary donation. This makes the biggest impact since it helps pay for things such as server hosting and domain registration. A donation of any sum is appreciated and, if you so wish, you can donate [here](https://paypal.me/wrxck).

I'd like to take a moment to thank the following people for their donation(s):

* j0shu4
* para949
* aRandomStranger
* mochicon
* xenial
* fizdog
* caidens
* LKD70
* xxdamage
