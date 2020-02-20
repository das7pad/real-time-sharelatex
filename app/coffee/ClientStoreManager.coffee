ClientStore = {}

ClientStore.wrap = (client) ->
	client.ol_context = {}

ClientStore.unwrap = (client) ->
	delete client.ol_context

module.exports = ClientStore
