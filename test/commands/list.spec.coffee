# test framework
expect = require('chai').expect

# dependencies/helpers
helpers = require('../helpers')
testContext = require('../test_context')

# test target
bot = require('../../src/scripts/bot')


describe 'bot | commands | list', ->
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
      helpers.brainFor(context.robot)
        .repo('http://a.com', ['#mocha'])
          .pr('1', 'MERGED')
          .pr('2', 'OPEN')
        .repo('http://b.com', ['#abc','#mocha'])
          .pr('3', 'DECLINED')
        .repo('http://c.com', ['#abc'])

      expected = """
                 #mocha is subscribing to PR changes from 2 repo(s):
                   - http://a.com
                     - #2 (#2 @ http://a.com/2): http://a.com/2
                   - http://b.com
                 """

      # when/then
      whenListing ({strings, envelope}) ->
        expect(strings[0]).to.equal expected
