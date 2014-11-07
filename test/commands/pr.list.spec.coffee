expect = require('chai').expect
TextMessage = require('hubot/src/message').TextMessage

testContext = require('../test_context')
stashbot = require('../../src/scripts/stashbot')
helpers = require('../helpers')



describe 'commands | pr | list', ->
  context = {}


  beforeEach (done) ->
    testContext (testContext) ->
      context.robot = testContext.robot
      context.sandbox = testContext.sandbox
      context.user = testContext.user
      stashbot(context.robot)
      done()


  afterEach ->
    context.sandbox.restore()



  it 'should register a listener', ->
    expect(context.robot.respond.withArgs(/stash pr$/i).calledOnce).to.equal true


  it 'should list all repos that the room is subscribed to', (done) ->
    context.robot.brain.data.stashPr ||=
      repos: {}
    context.robot.brain.data.stashPr.repos['http://mocha.com/'] =
      api_url: 'http://mocha.com/'
      rooms: ['#mocha']
    context.robot.brain.data.stashPr.repos['http://abc.com/'] =
      api_url: 'http://abc.com/'
      rooms: ['#mocha', '#abc']

    context.robot.adapter.on 'reply', (envelope, strings) ->
      helpers.asyncAssert done, ->
        expect(strings[0]).to.equal "#mocha is subscribing to PR changes from the 2 repo(s): http://mocha.com/, http://abc.com/"

    context.robot.adapter.receive new TextMessage(context.user, "#{context.robot.name} stash pr")

