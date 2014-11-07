fs = require('fs')
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

  context.robot = new Robot(null, 'mock-adapter', false, 'MOCKBOT')

  context.robot.brain.data.stashPr =
    repos: {}

  context.sandbox.spy context.robot, 'respond'
  context.sandbox.spy context.robot, 'hear'

  context.robot.adapter.on 'connected', ->
    # only load scripts we absolutely need, like auth.coffee
    process.env.HUBOT_AUTH_ADMIN = '1'
    scriptsPath = path.resolve(path.join("node_modules/hubot/src/scripts"))
    context.robot.loadFile scriptsPath, "auth.coffee"

    # create a user
    context.user = context.robot.brain.userForId('1',
      name: 'mocha'
      room: '#mocha'
    )

    context.adapter = context.robot.adapter

    done(context)

  context.robot.run()
