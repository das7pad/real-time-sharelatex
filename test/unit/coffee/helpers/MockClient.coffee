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
	set : (key, value) ->
		@attributes[key] = value
	get : (key) ->
		return @attributes[key]
	disconnect: () ->
