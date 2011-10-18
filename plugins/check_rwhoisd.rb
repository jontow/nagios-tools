#!/usr/bin/env ruby
#
# 2010-07-15 -- jontow@zenbsd.net
#
# Nagios plugin to monitor rwhoisd.
#
################################################################################

require 'socket'

@host = nil
@port = 4321
@debug = false

if ARGV.nil? or ARGV[0].nil? or ARGV[0].empty?
	puts "Usage: rwhoisd.rb <hostname> [port]"
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

begin
	sock = TCPSocket.new(@host, @port)

	banner = sock.gets
	p banner if @debug

	sock.puts "-status"

	loop do
		line = sock.gets

		p line if @debug

		if line =~ /\%status\ objects:(\d+)/
			puts "OBJECTS: #{$1}"
		end

		if line.chomp == "%ok"
			sock.puts "-quit"
			break
		end
	end
rescue => err
	p err.message
	exit 2
end

exit 0
