logger = require "logger-sharelatex"
Settings = require("settings-sharelatex")

if Settings.clientStoreBackend == "memory"
	ClientStore = require("./ClientStoreMemory")
else
	logger.info {
		backend: Settings.clientStoreBackend
	}, "unknown client store backend, using memory as fallback"
	ClientStore = require("./ClientStoreMemory")

ClientStore.wrap = (client) ->
	logger.info("wrap #{client.id}")
	ClientStore.init(client)
	client.get = ClientStore.get.bind(client)
	client.set = ClientStore.set.bind(client)
	client.del = ClientStore.del.bind(client)
	client.getMulti = ClientStore.getMulti.bind(client)
	client.setMulti = ClientStore.setMulti.bind(client)

ClientStore.unwrap = (client) ->
		logger.info("unwrap #{client.id}")
		ClientStore.clear client

module.exports = ClientStore
