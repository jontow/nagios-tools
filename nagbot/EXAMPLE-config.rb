# 2011-10-18 -- jontow@zenbsd.net
#
# Configuration for nagbot!
#

class NagbotConfig
	attr_accessor :verbose, :nickname, :username, :realname, :server, :channels, :naglog
	def initialize
		# Enable this for more info
		@verbose = true

		# IRC related configuration
		@nickname = "nagbot"
		@username = "nagbot"
		@realname = "Nagios"
		@server   = "irc.example.com"
		@channels = ["#nagios"]

		# Location of nagios logfile
		@naglog = "/var/log/nagios/nagios.log"
	end
end
