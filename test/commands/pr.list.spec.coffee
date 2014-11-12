expect = require('chai').expect

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



  # =========================================================================
  #  INTERNAL TEST HELPERS
  # =========================================================================
  whenListing = (expectCallback) ->
    message = "stash-poll"
    helpers.onRobotReply context.robot, context.user, message, expectCallback



  # =========================================================================
  #  LISTENER
  # =========================================================================
  it 'should register a listener', ->
    expect(context.robot.respond.withArgs(/stash-poll$/i).calledOnce).to.equal true



  # =========================================================================
  #  NON-EMPTY BRAIN
  # =========================================================================
  describe 'given a non-empty brain', ->
    it 'should list all repos that the room is subscribed to', ->
      # given
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

      expected = """
                 #mocha is subscribing to PR changes from 2 repo(s):
                   - http://mocha.com/
                     - #8 (Bar request): http://mocha.com/pr/8
                     - #123 (Foo request): http://mocha.com/pr/123
                   - http://abc.com/
                 """

      # when/then
      whenListing ({strings, envelope}) ->
        expect(strings[0]).to.equal expected
