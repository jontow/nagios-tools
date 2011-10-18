#!/usr/bin/env ruby
#
# 2010-07-15 -- jontow@zenbsd.net
#
# Nagios plugin to monitor freeswitch via mod_event_socket.
#
################################################################################

require 'socket'

@host = nil
@port = 8021
@password = "ClueCon"
@debug = false
@status = {}

if ARGV.nil? or ARGV[0].nil? or ARGV[0].empty?
	puts "Usage: check_freeswitch.rb <hostname> [port] [password]"
	exit 3
elsif ARGV[0] == "-v" and !ARGV[1].nil? and !ARGV[1].empty?
	@debug = true
	ARGV.shift
	@host = ARGV[0].chomp
else
	@host = ARGV[0].chomp
end

if !ARGV[1].nil? and !ARGV[1].empty?
	@port = ARGV[1].chomp.to_i
end

if !ARGV[2].nil? and !ARGV[2].empty?
	@password = ARGV[2].chomp
end

begin
	sock = TCPSocket.new(@host, @port)

	banner = sock.gets
	p banner if @debug

	if banner =~ /auth\/request/
		puts "Sending: auth #{@password}" if @debug
		sock.puts "auth #{@password}\n\n"

		loop do
			reply = sock.gets.chomp
			if reply =~ /Reply-Text: \-ERR/
				puts "REPLY: x#{$1}x" if @debug
				puts "Authentication Failed"
				sock.puts "exit\n\n"
				exit 2
			elsif reply =~ /Reply-Text: \+OK/
				puts "REPLY: x#{$1}x" if @debug
				puts "Authentication Succeeded" if @debug
				break
			else
				puts "DEBUG: #{reply}" if @debug and !reply.nil?
			end
		end
	end

	# Event socket is valid from here on.. do whatever you need to
	puts "Sending 'api status'.." if @debug
	sock.puts "api status\n\n"

	loop do
		line = sock.gets

		p line if @debug and !line.nil?

		if md = /^UP (\d+) years, (\d+) days, (\d+) hours, (\d+) minutes, (\d+) seconds, (\d+) milliseconds, (\d+) microseconds/.match(line)
			@status['uptime'] = [md[1].to_i, md[2].to_i, md[3].to_i, md[4].to_i, md[5].to_i, md[6].to_i, md[7].to_i]
		elsif md = /^(\d+) session\(s\) since startup/.match(line)
			@status['sessions-since-start'] = md[1].to_i
		elsif md = /^(\d+) session\(s\) (\d+)\/(\d+)/.match(line)
			@status['sessions'] = md[1].to_i
			@status['sessions-per-second-interval'] = md[2].to_i
			@status['sessions-per-second-maximum'] = md[3].to_i
		elsif md = /^(\d+) session\(s\) max/.match(line)
			@status['sessions-maximum'] = md[1].to_i
		elsif md = /^min idle cpu (\d+\.\d+)\/(\d+\.\d+)/.match(line)
			@status['min-cpu-idle'] = md[1]
			@status['max-cpu-idle'] = md[1]

			# Here's the end of 'api status', so we can throw a break here..
			break
		end
	end
rescue => err
	puts err.message
	exit 2
end

p @status if @debug

sock.puts "exit\n\n"

puts "#{@status['sessions']} sessions, #{@status['sessions-per-second-interval']} sps"

# WARNING if sps is 50% or more
if @status['sessions-per-second-interval'] >= (@status['sessions-per-second-maximum'] * 0.50)
	exit 1
# CRITICAL if sps is 90% or more
elsif @status['sessions-per-second-interval'] >= (@status['sessions-per-second-maximum'] * 0.90)
	exit 2
else
	exit 0
end
