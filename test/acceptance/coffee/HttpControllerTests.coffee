async = require('async')
expect = require('chai').expect
request = require('request').defaults({
	baseUrl: 'http://localhost:3026'
})

RealTimeClient = require "./helpers/RealTimeClient"
FixturesManager = require "./helpers/FixturesManager"

describe 'HttpControllerTests', ->
	describe 'without a user', ->
		it 'should return 404 for the client view', (done) ->
			client_id = 'not-existing'
			request.get {
				url: "/clients/#{client_id}"
				json: true
			}, (error, response, data) ->
				return done(error) if error
				expect(response.statusCode).to.equal(404)
				done()

	describe 'with a user', ->
		before (done) ->
			async.series [
				(cb) =>
					FixturesManager.setUpProject {
						privilegeLevel: "owner"
					}, (e, {@project_id, @user_id}) =>
						cb(e)

				(cb) =>
					FixturesManager.setUpDoc @project_id, {@lines, @version, @ops, @ranges}, (e, {@doc_id}) =>
						cb(e)

				(cb) =>
					@client = RealTimeClient.connect()
					@client.on "connectionAccepted", cb

				(cb) =>
					@client.emit "joinProject", project_id: @project_id, cb

				(cb) =>
					@client.emit "joinDoc", @doc_id, (error, @returnedArgs...) => cb(error)
			], done

		it 'should send a client view', (done) ->
			request.get {
				url: "/clients/#{@client.id}"
				json: true
			}, (error, response, data) =>
				return done(error) if error
				expect(response.statusCode).to.equal(200)
				expect(data.connected_time).to.exist
				delete data.connected_time
				expect(data).to.deep.equal({
					client_id: @client.id,
					first_name: 'Joe',
					last_name: 'Bloggs',
					project_id: @project_id,
					user_id: @user_id,
					rooms: [
						@client.id,
						@project_id,
						@doc_id,
					]
				})
				done()
