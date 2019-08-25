module.exports = ClientStoreMemory =
	init: (client) ->
		client.data = {}

	clear: (client) ->
		delete client.data

	set: (key, value, callback = (error) ->) ->
		this.data[key] = value
		callback()

	get: (key, callback = (error, value) ->) ->
		callback(null, this.data[key])

	del: (client, key, callback = (error) ->) ->
		delete this.data[key]
		callback(null)
