require 'main'

begin
require 'config'
rescue
	puts "Couldn't load config file!"
	exit
end


cfg = NagbotConfig.new
bot = IRCBot.new(cfg)
puts "Server:   #{cfg.server}\nNickname: #{cfg.nickname}\n" if cfg.verbose
bot.open(cfg.server, [cfg.username, cfg.realname], cfg.nickname)
bot.thread.join
