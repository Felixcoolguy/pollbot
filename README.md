# A simple discordrb based poll bot

This is a small bot that enables users to start polls.

## Syntax

### Start a poll

`!poll [Question]`  
This will start a poll with the default `Yes` and `No` answers.

`!poll [Question], [Answer 1], [Answer 2], etc`  
This will start a poll with the specified answers.

### Display the current poll
`!poll`  
If there is a poll running it will display the current poll, otherwise it will tell you there is no poll running.

### Vote for an answer
`!vote [index of answer]`  
This will vote for an answer, when a poll is shown it will display a number for each answer. If the user has already voted, it's vote will change to the new answer.

### Closing the poll

`!close_poll`  
When a poll is active, the poll can only be closed by the user who opened it, or the owner of the bot (see `Environment variables` below).

### Shut down the bot
`!close_polls`  
This will stop the running poll bot.

## Environment variables
This bot depends on 3 environment veriables to function properly

| NAME | Description |
| ---- | ----------- |
| TOKEN | Your bot token, this can be found in your [Discord applications page](https://discordapp.com/developers/applications/me) |
| CLIENT_ID | You client ID, found in the [Discord applications page](https://discordapp.com/developers/applications/me) |
| OWNER_ID | The user ID of the person running the bot, this ID is needed to shut down the bot with a command |

## Dependencies
Poll bot depends on 2 dependencies

* [DOTENV](https://github.com/bkeepers/dotenv)
* [discordrb](https://github.com/meew0/discordrb)

These are included in the `Gemfile` in the repository
