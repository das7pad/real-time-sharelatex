sinon = require('sinon')

idCounter = 0

module.exports = class MockClient
	constructor: () ->
		@attributes = {}
		@join = sinon.stub()
		@emit = sinon.stub()
		@to = sinon.stub().returns({emit: @emit_to = sinon.stub()})
		@disconnect = sinon.stub()
		@id = idCounter++
	set : (key, value, callback) ->
		@attributes[key] = value
		callback() if callback?
	setMulti: (values, callback=()->) ->
		for key, value of values
			@attributes[key] = value
			callback()
	get : (key, callback) ->
		callback null, @attributes[key]
	disconnect: () ->
