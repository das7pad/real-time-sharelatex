async = require "async"

module.exports = Utils =
	getClientAttributes: (client, keys, callback = (error, attributes) ->) ->
		client.getMulti(keys, callback)
