expect = require('chai').expect
TextMessage = require('hubot/src/message').TextMessage

testContext = require('../test_context')
bot = require('../../src/scripts/bot')
helpers = require('../helpers')



describe 'commands | pr | unsubscribe', ->
  context = {}


  beforeEach (done) ->
    testContext (testContext) ->
      context.robot = testContext.robot
      context.sandbox = testContext.sandbox
      context.user = testContext.user
      bot(context.robot)
      done()


  afterEach ->
    context.sandbox.restore()



  it 'should register a listener', ->
    expect(context.robot.respond.withArgs(/stash-poll rm (.*)/i).calledOnce).to.equal true


  it 'should unsubscribe the room from the given repo', (done) ->
    context.robot.brain.data.stashPr ||=
      repos: {}
    context.robot.brain.data.stashPr.repos['http://mocha.com/'] =
      api_url: 'http://mocha.com/'
      rooms: ['#mocha', '#abc']

    context.robot.adapter.on 'reply', (envelope, strings) ->
      helpers.asyncAssert done, ->
        expect(context.robot.brain.data.stashPr.repos['http://mocha.com/'].rooms).to.eql ['#abc']
        expect(strings[0]).to.equal "#mocha is no longer subscribing to PR changes in repo http://mocha.com/"

    context.robot.adapter.receive new TextMessage(context.user, "#{context.robot.name} stash-poll rm http://mocha.com/")
