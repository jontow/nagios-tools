class NagiosLogPoller
	def initialize(cfg, irchandle, host='localhost')
		@cfg = cfg
		@irch = irchandle
		@lastseen = Time.now.to_i - 60
	end

	def strip_ts(event)
		(rawts, rawevent) = event.split(' ', 2)
		return rawts.gsub(/\[/, '').gsub(/\]/, '')
	end

	def cycle
		File.open(@cfg.naglog, 'r').each do |nl|
			# Here's where you would add lines to ignore..
			next if nl =~ /Auto-save/

			ah = parse_event(nl)

			next if strip_ts(ah['ts']).to_i <= @lastseen

			@lastseen = strip_ts(ah['ts']).to_i

			cookedevent = "#{Time.at(strip_ts(ah['ts']).to_i).strftime("%Y-%m-%d %H:%M:%S")} :: #{ah['host']}: #{ah['testname']} #{ah['status']}(#{ah['testnum']}): #{ah['alerttext']}"
			puts "DEBUG: #{cookedevent}"
			@irch.publish_event(cookedevent)
		end
	end

	def parse_event(event=nil)
		if event.nil?
			return "No event passed"
		end

		ahash = {}

		(ahash['ts'], ahash['alerttype'], alertuseless, alertblob) = event.split(' ', 4)
		# Note: unrecognized/unparseable log lines get silently ignored, but not discarded.
		if alertblob =~ /\;.*\;/
			(ahash['host'], ahash['testname'], ahash['status'], ahash['hardness'], ahash['testnum'], ahash['alerttext']) = alertblob.split(';', 6)
		end

		return ahash
	end
end
