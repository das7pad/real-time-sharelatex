logger = require "logger-sharelatex"

module.exports =
	startDrain: (io, rate) ->
		# Clear out any old interval
		clearInterval @interval
		if rate == 0
			return
		@interval = setInterval () =>
			@reconnectNClients(io, rate)
		, 1000

	RECONNECTED_CLIENTS: {}
	reconnectNClients: (io, N) ->
		drainedCount = 0
		for client in Object.values(io.sockets.connected)
			if !@RECONNECTED_CLIENTS[client.id]
				@RECONNECTED_CLIENTS[client.id] = true
				logger.log {client_id: client.id}, "Asking client to reconnect gracefully"
				client.emit "reconnectGracefully"
				drainedCount++
			haveDrainedNClients = (drainedCount == N)
			if haveDrainedNClients
				break
		if drainedCount < N
			logger.log "All clients have been told to reconnectGracefully"