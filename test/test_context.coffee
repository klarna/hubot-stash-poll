fs = require('fs')
nock = require('nock')
path = require('path')
sinon = require('sinon')
Robot = require('hubot/src/robot')


module.exports = (done) ->
  context =
    sandbox: sinon.sandbox.create()
    robot: undefined
    adapter: undefined
    user: undefined

  # to avoid "possible EventEmitter memory leak detected" warning
  context.sandbox.stub process, 'on', -> null

  # stop all requests by default
  nock.activate() if not nock.isActive()
  nock.disableNetConnect()
  nock.enableNetConnect('localhost')

  context.robot = new Robot(null, 'mock-adapter', false, 'MOCKBOT')

  context.sandbox.spy context.robot, 'respond'
  context.sandbox.spy context.robot, 'hear'

  context.robot.adapter.on 'connected', ->
    context.user = context.robot.brain.userForId '1',
      name: 'mocha'
      room: '#mocha'

    done(context)

  context.robot.run()
