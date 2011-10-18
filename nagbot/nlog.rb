class NagiosLogPoller
	NAGIOSLOG = "/var/log/nagios/nagios.log"

	def initialize(irchandle, host='localhost', port=8021, password='ClueCon')
		@irch = irchandle
		@lastseen = Time.now.to_i - 60
	end

	def strip_ts(event)
		(rawts, rawevent) = event.split(' ', 2)
		return rawts.gsub(/\[/, '').gsub(/\]/, '')
	end

	def cycle
		File.open(NAGIOSLOG, 'r').each do |nl|
			next if nl =~ /Auto-save/

			ah = parse_event(nl)

			next if strip_ts(ah['ts']).to_i <= @lastseen

			@lastseen = strip_ts(ah['ts']).to_i

			cookedevent = "#{Time.at(strip_ts(ah['ts']).to_i).strftime("%Y-%m-%d %H:%M:%S")} :: #{ah['host']}: #{ah['testname']} #{ah['status']}(#{ah['testnum']}): #{ah['alerttext']}"
			puts "DEBUG: #{cookedevent}"
			@irch.publish_event(cookedevent, @irch.channel)
		end
	end

	def parse_event(event=nil)
		if event.nil?
			return "No event passed"
		end

		ahash = {}

		(ahash['ts'], ahash['alerttype'], alertuseless, alertblob) = event.split(' ', 4)
		(ahash['host'], ahash['testname'], ahash['status'], ahash['hardness'], ahash['testnum'], ahash['alerttext']) = alertblob.split(';', 6)
		#puts "NLOG: #{ts} #{host} -- #{alerttype} -- #{alerttext}"

		return ahash
	end
end
