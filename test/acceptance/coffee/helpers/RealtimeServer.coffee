app = require('../../../../app')
logger = require("logger-sharelatex")
Settings = require("settings-sharelatex")

request = require("request")

module.exports =
	running: false
	initing: false
	callbacks: []
	ensureRunning: (callback = (error) ->) ->
		if @running
			return callback()
		else if @initing
			@callbacks.push callback
		else
			@initing = true
			@callbacks.push callback
			request.get "http://localhost:3026/", (error) =>
				throw error if error?
				@running = true
				logger.log("clsi running in dev mode")

				for callback in @callbacks
					callback()
			return null
