/* eslint-disable
    camelcase,
    no-return-assign,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const RealTimeClient = require('./helpers/RealTimeClient')
const MockDocUpdaterServer = require('./helpers/MockDocUpdaterServer')
const FixturesManager = require('./helpers/FixturesManager')

const async = require('async')

const settings = require('settings-sharelatex')
const redis = require('@overleaf/redis-wrapper')
const rclient = redis.createClient(settings.redis.pubsub)

describe('PubSubRace', function () {
  before(function startMockDocUpdaterServer(done) {
    MockDocUpdaterServer.run(done)
  })

  describe('when the client leaves a doc before joinDoc completes', function () {
    before(function (done) {
      return async.series(
        [
          (cb) => {
            return FixturesManager.setUpProject(
              {
                privilegeLevel: 'owner',
                project: {
                  name: 'Test Project'
                }
              },
              (e, { project_id, user_id }) => {
                this.project_id = project_id
                this.user_id = user_id
                return cb()
              }
            )
          },

          (cb) => {
            this.clientA = RealTimeClient.connect()
            return this.clientA.on('connectionAccepted', cb)
          },

          (cb) => {
            return this.clientA.emit(
              'joinProject',
              { project_id: this.project_id },
              (error, project, privilegeLevel, protocolVersion) => {
                this.project = project
                this.privilegeLevel = privilegeLevel
                this.protocolVersion = protocolVersion
                return cb(error)
              }
            )
          },

          (cb) => {
            return FixturesManager.setUpDoc(
              this.project_id,
              { lines: this.lines, version: this.version, ops: this.ops },
              (e, { doc_id }) => {
                this.doc_id = doc_id
                return cb(e)
              }
            )
          },

          (cb) => {
            this.clientA.emit('joinDoc', this.doc_id, () => {})
            // leave before joinDoc completes
            return this.clientA.emit('leaveDoc', this.doc_id, cb)
          },

          (cb) => {
            // wait for subscribe and unsubscribe
            return setTimeout(cb, 100)
          }
        ],
        done
      )
    })

    return it('should not subscribe to the applied-ops channels anymore', function (done) {
      rclient.pubsub('CHANNELS', (err, resp) => {
        if (err) {
          return done(err)
        }
        resp.should.not.include(`applied-ops:${this.doc_id}`)
        return done()
      })
      return null
    })
  })

  describe('when the client emits joinDoc and leaveDoc requests frequently and leaves eventually', function () {
    before(function (done) {
      return async.series(
        [
          (cb) => {
            return FixturesManager.setUpProject(
              {
                privilegeLevel: 'owner',
                project: {
                  name: 'Test Project'
                }
              },
              (e, { project_id, user_id }) => {
                this.project_id = project_id
                this.user_id = user_id
                return cb()
              }
            )
          },

          (cb) => {
            this.clientA = RealTimeClient.connect()
            return this.clientA.on('connectionAccepted', cb)
          },

          (cb) => {
            return this.clientA.emit(
              'joinProject',
              { project_id: this.project_id },
              (error, project, privilegeLevel, protocolVersion) => {
                this.project = project
                this.privilegeLevel = privilegeLevel
                this.protocolVersion = protocolVersion
                return cb(error)
              }
            )
          },

          (cb) => {
            return FixturesManager.setUpDoc(
              this.project_id,
              { lines: this.lines, version: this.version, ops: this.ops },
              (e, { doc_id }) => {
                this.doc_id = doc_id
                return cb(e)
              }
            )
          },

          (cb) => {
            this.clientA.emit('joinDoc', this.doc_id, () => {})
            this.clientA.emit('leaveDoc', this.doc_id, () => {})
            this.clientA.emit('joinDoc', this.doc_id, () => {})
            this.clientA.emit('leaveDoc', this.doc_id, () => {})
            this.clientA.emit('joinDoc', this.doc_id, () => {})
            this.clientA.emit('leaveDoc', this.doc_id, () => {})
            this.clientA.emit('joinDoc', this.doc_id, () => {})
            this.clientA.emit('leaveDoc', this.doc_id, () => {})
            this.clientA.emit('joinDoc', this.doc_id, () => {})
            return this.clientA.emit('leaveDoc', this.doc_id, cb)
          },

          (cb) => {
            // wait for subscribe and unsubscribe
            return setTimeout(cb, 100)
          }
        ],
        done
      )
    })

    return it('should not subscribe to the applied-ops channels anymore', function (done) {
      rclient.pubsub('CHANNELS', (err, resp) => {
        if (err) {
          return done(err)
        }
        resp.should.not.include(`applied-ops:${this.doc_id}`)
        return done()
      })
      return null
    })
  })

  describe('when the client emits joinDoc and leaveDoc requests frequently and remains in the doc', function () {
    let projectId, docId, clientA
    before(function setUpEditorSession(done) {
      FixturesManager.setUpEditorSession(
        {
          privilegeLevel: 'owner',
          project: {
            name: 'Test Project'
          }
        },
        (error, { project_id, doc_id }) => {
          projectId = project_id
          docId = doc_id
          done(error)
        }
      )
    })
    before(function connect(done) {
      clientA = RealTimeClient.connect()
      clientA.on('connectionAccepted', done)
    })
    before(function joinProjectRPC(done) {
      clientA.emit('joinProject', { project_id: projectId }, done)
    })

    before(function setUpProject(done) {
      clientA.emit('joinDoc', docId, () => {})
      clientA.emit('leaveDoc', docId, () => {})
      clientA.emit('joinDoc', docId, () => {})
      clientA.emit('leaveDoc', docId, () => {})
      clientA.emit('joinDoc', docId, () => {})
      clientA.emit('leaveDoc', docId, () => {})
      clientA.emit('joinDoc', docId, () => {})
      clientA.emit('leaveDoc', docId, () => {})
      clientA.emit('joinDoc', docId, done)
    })
    before(function waitForSubscribeAndUnsubscribe(done) {
      setTimeout(done, 100)
    })

    return it('should subscribe to the applied-ops channels', function (done) {
      rclient.pubsub('CHANNELS', (err, resp) => {
        if (err) {
          return done(err)
        }
        resp.should.include(`applied-ops:${docId}`)
        return done()
      })
      return null
    })
  })

  return describe('when the client disconnects before joinDoc completes', function () {
    before(function setUpProject(done) {
      FixturesManager.setUpProject(
        {
          privilegeLevel: 'owner',
          project: {
            name: 'Test Project'
          }
        },
        (e, { project_id, user_id }) => {
          this.project_id = project_id
          this.user_id = user_id
          done()
        }
      )
    })

    before(function setupClient(done) {
      this.clientA = RealTimeClient.connect()
      this.clientA.on('connectionAccepted', done)
    })

    before(function joinProject(done) {
      this.clientA.emit(
        'joinProject',
        { project_id: this.project_id },
        (error, project, privilegeLevel, protocolVersion) => {
          this.project = project
          this.privilegeLevel = privilegeLevel
          this.protocolVersion = protocolVersion
          done(error)
        }
      )
    })

    before(function setupDoc(done) {
      FixturesManager.setUpDoc(
        this.project_id,
        { lines: this.lines, version: this.version, ops: this.ops },
        (e, { doc_id }) => {
          this.doc_id = doc_id
          done(e)
        }
      )
    })

    before(function joinDoc(done) {
      let joinDocCompleted = false
      this.clientA.emit('joinDoc', this.doc_id, () => (joinDocCompleted = true))
      // leave before joinDoc completes
      setTimeout(
        () => {
          if (joinDocCompleted) {
            return done(new Error('joinDocCompleted -- lower timeout'))
          }
          this.clientA.on('disconnect', () => done())
          this.clientA.disconnect()
        },
        // socket.io processes joinDoc and disconnect with different delays:
        //  - joinDoc goes through two process.nextTick
        //  - disconnect goes through one process.nextTick
        // We have to inject the disconnect event into a different event loop
        //  cycle.
        3
      )
    })

    before(function (done) {
      // wait for subscribe and unsubscribe
      setTimeout(done, 100)
    })

    it('should not subscribe to the editor-events channels anymore', function (done) {
      rclient.pubsub('CHANNELS', (err, resp) => {
        if (err) {
          return done(err)
        }
        resp.should.not.include(`editor-events:${this.project_id}`)
        return done()
      })
      return null
    })

    return it('should not subscribe to the applied-ops channels anymore', function (done) {
      rclient.pubsub('CHANNELS', (err, resp) => {
        if (err) {
          return done(err)
        }
        resp.should.not.include(`applied-ops:${this.doc_id}`)
        return done()
      })
      return null
    })
  })
})
