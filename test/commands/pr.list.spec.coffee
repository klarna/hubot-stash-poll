expect = require('chai').expect
TextMessage = require('hubot/src/message').TextMessage

testContext = require('../test_context')
bot = require('../../src/scripts/bot')
helpers = require('../helpers')


describe 'commands | pr | list', ->
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
    expect(context.robot.respond.withArgs(/stash-poll$/i).calledOnce).to.equal true


  it 'should list all repos that the room is subscribed to', (done) ->
    context.robot.brain.data['stash-poll'] =
      'http://mocha.com/':
        api_url: 'http://mocha.com/'
        rooms: ['#mocha']
        pull_requests:
          '123':
            id: '123'
            title: 'Foo request'
            url: 'http://mocha.com/pr/123'
          '8':
            id: '8'
            title: 'Bar request'
            url: 'http://mocha.com/pr/8'
      'http://abc.com/':
        api_url: 'http://abc.com/'
        rooms: ['#mocha', '#abc']

    expectedOutput =
      """
      #mocha is subscribing to PR changes from 2 repo(s):
        - http://mocha.com/
          - #8 (Bar request): http://mocha.com/pr/8
          - #123 (Foo request): http://mocha.com/pr/123
        - http://abc.com/
      """

    context.robot.adapter.on 'reply', (envelope, strings) ->
      helpers.asyncAssert done, ->
        expect(strings[0]).to.equal expectedOutput

    context.robot.adapter.receive new TextMessage(context.user, "#{context.robot.name} stash-poll")

