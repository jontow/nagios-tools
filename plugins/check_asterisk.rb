#!/usr/bin/env ruby
#
# 2010-12-21 -- jontow@zenbsd.net
#
# Nagios plugin to monitor asterisk via AMI
#
################################################################################

require 'socket'

@host = nil
@port = 5038
@username = "nagios"
@password = "password"
@debug = false

if ARGV.nil? or ARGV[2].nil? or ARGV[2].empty?
	puts "Usage: check_asterisk.rb <hostname> <username> <password>"
	exit 3
end

@host = ARGV[0]
@username = ARGV[1]
@password = ARGV[2]

begin
	sock = TCPSocket.new(@host, @port)

	banner = sock.gets
	p banner if @debug

	if banner =~ /^Asterisk\ Call\ Manager/
		puts "Sending Event::\n  Action: Login\n  Username: #{@username}\n  Secret: #{@password}" if @debug
		sock.puts "Action: Login\nUsername: #{@username}\nSecret: #{@password}\n\n"

		loop do
			reply = sock.gets.chomp
			if reply =~ /Response: Success/
				puts "REPLY: x#{$1}x" if @debug
				puts "Authentication Succeeded"
				sock.puts "Action: Logoff\n\n"
				exit 0
			else
				puts "Authentication Failed"
				puts "DEBUG: #{reply}" if @debug and !reply.nil?
				sock.puts "Action: Logoff\n\n"
				exit 2
			end
		end
	end
rescue => err
	puts err.message
	exit 2
end

sock.puts "Action: Logoff\n\n"
exit
