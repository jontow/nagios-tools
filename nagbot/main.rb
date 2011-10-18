require 'socket'
require 'rica'
require 'thread'

require 'nlog'

Thread.abort_on_exception = true

class IRCBot < Rica::MessageProcessor
	attr_reader :channel

	def initialize
		super()
		@c=[]
		@nlog=nil
		@s = nil
		@channel = "#nagios"
		
		@nlog = NagiosLogPoller.new(self)

		Thread.new do
			sleep 15

			loop do
				@nlog.cycle
				sleep 1
			end
		end
	end

	def default_action(msg)
		p msg.origin
	end

	def on_recv_rpl_motd(msg)
		if @c.empty?
			cmnd_join(msg.server, @channel)
		end
	end

	def on_recv_cmnd_join(msg)
		if msg.isSelfMessage?
			@c << msg.to
			@s = msg.server
		end
	end

	def on_recv_cmnd_privmsg(msg)
		if(!msg.isSelfMessage? and @c.include?(msg.to) and msg.args[0][0...1] == '!')
			command, args = msg.args[0][1..-1].split(' ', 2)
			hostmask = msg.from.split('!', 2)[0]

			c = msg.to

			case command
			when 'reload'
				cmnd_notice(@s, c, 'attempting a reload...')
				begin
					load(__FILE__)
				rescue LoadError => e
					cmnd_notice(@s, c, 'encountered a load error when reloading. details follow:')
					p e.message
				rescue SyntaxError => e
					cmnd_notice(@s, c, 'encountered a syntax error')
					p e.message
				else
					cmnd_notice(@s, c, 'reload successful!')
				end
			when 'fortune'
				if args.nil? or args.strip.empty?
					cmnd_notice(@s, c, `fortune -a`)
				else
					fortunes = `fortune -a -m "#{args}"`.split('%%')
					if fortunes.empty?
						cmnd_notice(@s, c, "can't help ya on that one")
					else
						fortunes[rand(fortunes.length)].split("\n").each do |x|
							cmnd_notice(@s, c, x)
						end
					end
				end
			when 'wtf'
				if !args.nil? and args.strip.empty?
					cmnd_notice(@s, c, "WTF do you want?")
				else
					cmnd_notice(@s, c, `wtf "#{args}"`)
				end
			when 'excuse'
				begin
					excuses = File.read('excuses').split("\n")
					excuse = excuses[rand(excuses.length)]
					cmnd_notice(@s, c, "The problem is caused by: #{excuse}")
				rescue
				end
			when 'help'
				cmnd_notice(@s, c, "There's no help for you here")
			when 'test'
				p args
			when 'conf'
				if args.nil? or args.strip.empty?
					cmnd_notice(@s, c, "general protection fault.")
				else
					(argcmd, args) = args.split(' ', 2)

					case argcmd
					when "help"
						cmnd_notice(@s, c, "There's no help for you here")
					#when argcmd.integer?
						# for now, we don't do anything with it, just parse it..
					#	conf = argcmd.to_s
					#	@es.output("api conference #{args}\r\n\r\n")
					else
					#	@es.output("api conference #{argcmd} #{args}\r\n\r\n")
					end
				end
			end
		end
	end

	def publish_event(event, channel)
		# Notice to channel
		#cmnd_notice(@s, channel, event)

		# Say in channel
		cmnd_privmsg(@s, channel, event)
	end
end
