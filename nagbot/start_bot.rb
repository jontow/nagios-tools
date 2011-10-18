require 'main'

bot = IRCBot.new
bot.open('irc.example.com', ['nagbot', 'Nagios Bot'], 'nagbot')
bot.thread.join
