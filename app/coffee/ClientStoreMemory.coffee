module.exports = ClientStoreMemory =
	init: (client) ->
		client.data = new Map()

	clear: (client) ->
		client.data.clear()

	set: (key, value, callback = (error) ->) ->
		this.data[key] = value
		callback()

	setMulti: (data, callback = (error) ->) ->
		for key, value of data
			this.data[key] = value
		callback(null)

	get: (key, callback = (error, value) ->) ->
		callback(null, this.data[key])

	getMulti: (keys, callback = (error, values) ->) ->
		values = {}
		for key in keys
			values[key] = this.data[key]
		callback(null, values)

	del: (client, key, callback = (error) ->) ->
		delete this.data[key]
		callback(null)

	delMulti: (client, keys, callback = (error) ->) ->
		for key in keys
			delete this.data[key]
		callback(null)
