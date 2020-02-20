SandboxedModule = require('sandboxed-module')
sinon = require('sinon')
require('chai').should()
modulePath = require('path').join __dirname, '../../../app/js/WebsocketLoadBalancer'

fakeGet = (restricted) ->
	(field) ->
		if field != 'is_restricted_user'
			throw new Error('not set')
		return restricted

describe "WebsocketLoadBalancer", ->
	beforeEach ->
		@rclient = {}
		@RoomEvents = {on: sinon.stub()}
		@WebsocketLoadBalancer = SandboxedModule.require modulePath, requires:
			"./RedisClientManager":
				createClientList: () => []
			"logger-sharelatex": @logger = { log: sinon.stub(), error: sinon.stub(), err: sinon.stub() }
			"./SafeJsonParse": @SafeJsonParse =
				parse: (data, cb) => cb null, JSON.parse(data)
			"./EventLogger": {checkEventOrder: sinon.stub()}
			"./HealthCheckManager": {check: sinon.stub()}
			"./RoomManager" : @RoomManager = {eventSource: sinon.stub().returns @RoomEvents}
			"./ChannelManager": @ChannelManager = {publish: sinon.stub()}
			"./ConnectedUsersManager": @ConnectedUsersManager = {refreshClient: sinon.stub()}
		@io = {}
		@WebsocketLoadBalancer.rclientPubList = [{publish: sinon.stub()}]
		@WebsocketLoadBalancer.rclientSubList = [{
			subscribe: sinon.stub()
			on: sinon.stub()
		}]

		@room_id = "room-id"
		@message = "otUpdateApplied"
		@payload = ["argument one", 42]

	afterEach ->
		@logger.err.called.should.equal.false
		@logger.error.called.should.equal.false

	describe "emitToRoom", ->
		beforeEach ->
			@WebsocketLoadBalancer.emitToRoom(@room_id, @message, @payload...)

		it "should publish the message to redis", ->
			@ChannelManager.publish
				.calledWith(@WebsocketLoadBalancer.rclientPubList[0], "editor-events", @room_id, JSON.stringify(
					room_id: @room_id,
					message: @message
					payload: @payload
				))
				.should.equal true

	describe "emitToAll", ->
		beforeEach ->
			@WebsocketLoadBalancer.emitToRoom = sinon.stub()
			@WebsocketLoadBalancer.emitToAll @message, @payload...

		it "should emit to the room 'all'", ->
			@WebsocketLoadBalancer.emitToRoom
				.calledWith("all", @message, @payload...)
				.should.equal true

	describe "listenForEditorEvents", ->
		beforeEach ->
			@WebsocketLoadBalancer._processEditorEvent = sinon.stub()
			@WebsocketLoadBalancer.listenForEditorEvents()

		it "should subscribe to the editor-events channel", ->
			@WebsocketLoadBalancer.rclientSubList[0].subscribe
				.calledWith("editor-events")
				.should.equal true

		it "should process the events with _processEditorEvent", ->
			@WebsocketLoadBalancer.rclientSubList[0].on
				.calledWith("message", sinon.match.func)
				.should.equal true

	describe "_processEditorEvent", ->
		describe "with bad JSON", ->
			beforeEach ->
				@isRestrictedUser = false
				@SafeJsonParse.parse = sinon.stub().callsArgWith 1, new Error("oops")
				@WebsocketLoadBalancer._processEditorEvent(@io, "editor-events", "blah")

			it "should log an error", ->
				@logger.error.called.should.equal true

		describe "with a designated room", ->
			beforeEach ->
				@io.sockets = {connected:
					'client-id-1': {id: 'client-id-1', emit: @emit1 = sinon.stub(), get: fakeGet()}
					'client-id-2': {id: 'client-id-2', emit: @emit2 = sinon.stub(), get: fakeGet()}
				}
				@io.to = sinon.stub().returns(
					clients: sinon.stub().yields(null, ['client-id-1', 'client-id-2'])
				)
				data = JSON.stringify
					room_id: @room_id
					message: @message
					payload: @payload
				@WebsocketLoadBalancer._processEditorEvent(@io, "editor-events", data)

			it "should send the message to all (unique) clients in the room", ->
				@io.to
					.calledWith(@room_id)
					.should.equal true
				@emit1.calledWith(@message, @payload...).should.equal true
				@emit2.calledWith(@message, @payload...).should.equal true

		describe "with a designated room, and restricted clients, not restricted message", ->
			beforeEach ->
				@io.sockets = {connected:
					'client-id-1': {id: 'client-id-1', emit: @emit1 = sinon.stub(), get: fakeGet()}
					'client-id-2': {id: 'client-id-2', emit: @emit2 = sinon.stub(), get: fakeGet()}
					'client-id-4': {id: 'client-id-4', emit: @emit4 = sinon.stub(), get: fakeGet(true)}
				}
				@io.to = sinon.stub().returns(
					clients: sinon.stub().yields(null, ['client-id-1', 'client-id-2', 'client-id-4'])
				)
				data = JSON.stringify
					room_id: @room_id
					message: @message
					payload: @payload
				@WebsocketLoadBalancer._processEditorEvent(@io, "editor-events", data)

			it "should send the message to all (unique) clients in the room", ->
				@io.to
					.calledWith(@room_id)
					.should.equal true
				@emit1.calledWith(@message, @payload...).should.equal true
				@emit2.calledWith(@message, @payload...).should.equal true
				@emit4.called.should.equal true  # restricted client, but should be called

		describe "with a designated room, and restricted clients, restricted message", ->
			beforeEach ->
				@io.sockets = {connected:
					'client-id-1': {id: 'client-id-1', emit: @emit1 = sinon.stub(), get: fakeGet()}
					'client-id-2': {id: 'client-id-2', emit: @emit2 = sinon.stub(), get: fakeGet()}
					'client-id-4': {id: 'client-id-4', emit: @emit4 = sinon.stub(), get: fakeGet(true)}
				}
				@io.to = sinon.stub().returns(
					clients: sinon.stub().yields(null, ['client-id-1', 'client-id-2', 'client-id-4'])
				)
				data = JSON.stringify
					room_id: @room_id
					message: @restrictedMessage = 'new-comment'
					payload: @payload
				@WebsocketLoadBalancer._processEditorEvent(@io, "editor-events", data)

			it "should send the message to all (unique) clients in the room, who are not restricted", ->
				@io.to
					.calledWith(@room_id)
					.should.equal true
				@emit1.calledWith(@restrictedMessage, @payload...).should.equal true
				@emit2.calledWith(@restrictedMessage, @payload...).should.equal true
				@emit4.called.should.equal false # restricted client, should not be called

		describe "when emitting to all", ->
			beforeEach ->
				@io.sockets =
					emit: @emit = sinon.stub()
				data = JSON.stringify
					room_id: "all"
					message: @message
					payload: @payload
				@WebsocketLoadBalancer._processEditorEvent(@io, "editor-events", data)

			it "should send the message to all clients", ->
				@emit.calledWith(@message, @payload...).should.equal true
