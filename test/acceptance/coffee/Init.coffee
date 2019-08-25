RealTimeServer = require "./helpers/RealtimeServer"

before (done) ->
	RealTimeServer.ensureRunning(done)
