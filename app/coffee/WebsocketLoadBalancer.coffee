Settings = require 'settings-sharelatex'
logger = require 'logger-sharelatex'
RedisClientManager = require "./RedisClientManager"
SafeJsonParse = require "./SafeJsonParse"
EventLogger = require "./EventLogger"
HealthCheckManager = require "./HealthCheckManager"
RoomManager = require "./RoomManager"
ChannelManager = require "./ChannelManager"
ConnectedUsersManager = require "./ConnectedUsersManager"

RESTRICTED_USER_MESSAGE_TYPE_PASS_LIST = [
	'connectionAccepted',
	'otUpdateApplied',
	'otUpdateError',
	'joinDoc',
	'reciveNewDoc',
	'reciveNewFile',
	'reciveNewFolder',
	'removeEntity'
]

module.exports = WebsocketLoadBalancer =
	rclientPubList: RedisClientManager.createClientList(Settings.redis.pubsub)
	rclientSubList: RedisClientManager.createClientList(Settings.redis.pubsub)

	emitToRoom: (room_id, message, payload...) ->
		if !room_id?
			logger.warn {message, payload}, "no room_id provided, ignoring emitToRoom"
			return
		data = JSON.stringify
			room_id: room_id
			message: message
			payload: payload
		logger.log {room_id, message, payload, length: data.length}, "emitting to room"

		for rclientPub in @rclientPubList
			ChannelManager.publish rclientPub, "editor-events", room_id, data

	emitToAll: (message, payload...) ->
		@emitToRoom "all", message, payload...

	listenForEditorEvents: (io) ->
		logger.log {rclients: @rclientPubList.length}, "publishing editor events"
		logger.log {rclients: @rclientSubList.length}, "listening for editor events"
		for rclientSub in @rclientSubList
			rclientSub.subscribe "editor-events"
			rclientSub.on "message", (channel, message) ->
				EventLogger.debugEvent(channel, message) if Settings.debugEvents > 0
				WebsocketLoadBalancer._processEditorEvent io, channel, message
		@handleRoomUpdates(@rclientSubList)

	handleRoomUpdates: (rclientSubList) ->
		roomEvents = RoomManager.eventSource()
		roomEvents.on 'project-active', (project_id) ->
			subscribePromises = for rclient in rclientSubList
				ChannelManager.subscribe rclient, "editor-events", project_id
			RoomManager.emitOnCompletion(subscribePromises, "project-subscribed-#{project_id}")
		roomEvents.on 'project-empty', (project_id) ->
			for rclient in rclientSubList
				ChannelManager.unsubscribe rclient, "editor-events", project_id

	_processEditorEvent: (io, channel, message) ->
		SafeJsonParse.parse message, (error, message) ->
			if error?
				logger.error {err: error, channel}, "error parsing JSON"
				return
			if message.room_id == "all"
				io.sockets.emit(message.message, message.payload...)
			else if message.message is 'clientTracking.refresh' && message.room_id?
				io.to(message.room_id).clients (err, clientIds) ->
					if err?
						return logger.err {room: message.room_id, err}, "failed to get room clients"
					logger.log {channel:channel, message: message.message, room_id: message.room_id, message_id: message._id, socketIoClients: clientIds}, "refreshing client list"
					for clientId in clientIds when io.sockets.connected[clientId] # filter disconnected clients
						ConnectedUsersManager.refreshClient(message.room_id, clientId)
			else if message.room_id?
				if message._id? && Settings.checkEventOrder
					status = EventLogger.checkEventOrder("editor-events", message._id, message)
					if status is "duplicate"
						return # skip duplicate events
				io.to(message.room_id).clients (err, clientIds) ->
					if err?
						return logger.err {room: message.room_id, err}, "failed to get room clients"

					is_restricted_message = message.message not in RESTRICTED_USER_MESSAGE_TYPE_PASS_LIST

					clientList = clientIds
					.map((id) -> io.sockets.connected[id])
					.filter(Boolean) # filter disconnected clients
					.filter((client) ->
						!(is_restricted_message && client.ol_context['is_restricted_user'])
					)

					# avoid unnecessary work if no clients are connected
					return if clientList.length is 0
					logger.log {
						channel: channel,
						message: message.message,
						room_id: message.room_id,
						message_id: message._id,
						socketIoClients: clientIds
					}, "distributing event to clients"
					for client in clientList
								client.emit(message.message, message.payload...)
			else if message.health_check?
				logger.debug {message}, "got health check message in editor events channel"
				HealthCheckManager.check channel, message.key
