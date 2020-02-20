RealTimeClient = require "./helpers/RealTimeClient"
FixturesManager = require "./helpers/FixturesManager"

expect = require("chai").expect

async = require "async"
request = require "request"

Settings = require "settings-sharelatex"

drain = (rate, callback) ->
	request.post {
		url: "http://localhost:3026/drain?rate=#{rate}"
		auth: {
			user: Settings.internal.realTime.user,
			pass: Settings.internal.realTime.pass
		}
	}, (error, response, data) ->
		callback error, data
	return null

describe "DrainManagerTests", ->
	before (done) ->
		FixturesManager.setUpProject {
			privilegeLevel: "owner"
			project: {
				name: "Test Project"
			}
		}, (e, {@project_id, @user_id}) => done()

	describe "with two clients in the project", ->
		beforeEach (done) ->
			async.series [
				(cb) =>
					@clientA = RealTimeClient.connect()
					@clientA.on "connectionAccepted", cb

				(cb) =>
					@clientB = RealTimeClient.connect()
					@clientB.on "connectionAccepted", cb

				(cb) =>
					@clientA.emit "joinProject", project_id: @project_id, (error, @project, @privilegeLevel, @protocolVersion) =>
						cb(error)

				(cb) =>
					@clientB.emit "joinProject", project_id: @project_id, (error, @project, @privilegeLevel, @protocolVersion) =>
						cb(error)
			], done

		describe "starting to drain", () ->
			beforeEach (done) ->
				async.parallel [
					(cb) =>
						@clientA.on "reconnectGracefully", cb
					(cb) =>
						@clientB.on "reconnectGracefully", cb

					(cb) -> drain(2, cb)
				], done

			afterEach (done) ->
				# reset drain
				drain(0, done)

			it "should not timeout", ->
				expect(true).to.equal(true)

			it "should not have disconnected", ->
				expect(@clientA.connected).to.equal true
				expect(@clientB.connected).to.equal true
