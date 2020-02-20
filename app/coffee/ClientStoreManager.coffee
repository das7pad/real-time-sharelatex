ClientStore = {}

ClientStore.wrap = (client) ->
	client.data = data = new Map()
	client.get = data.get.bind(data)
	client.set = data.set.bind(data)
	client.del = data.delete.bind(data)
	client.getMulti = (keys) ->
		out = {}
		for key in keys
			out[key] = data.get(key)
		return out

ClientStore.unwrap = (client) ->
	client.data.clear()

module.exports = ClientStore
