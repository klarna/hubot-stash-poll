expect = require('chai').expect

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



  # =========================================================================
  #  INTERNAL TEST HELPERS
  # =========================================================================
  whenRemoving = (api_url, expectCallback) ->
    message = "stash-poll rm #{api_url}"
    helpers.onRobotReply context.robot, context.user, message, (replyData) ->
      replyData.referencedRepo = context.robot.brain.data['stash-poll']?[api_url]
      expectCallback(replyData)



  # =========================================================================
  #  LISTENER
  # =========================================================================
  it 'should register a listener', ->
    expect(context.robot.respond.withArgs(/stash-poll rm (.*)/i).calledOnce).to.equal true



  # =========================================================================
  #  NON-EMPTY BRAIN
  # =========================================================================
  describe 'given a non-empty brain', ->
    it 'should unsubscribe the room from the given repo', () ->
      # given
      context.robot.brain.data['stash-poll'] =
        'http://mocha.com/':
          api_url: 'http://mocha.com/'
          rooms: ['#mocha', '#abc']

      # then
      whenRemoving 'http://mocha.com/', ({referencedRepo, envelope, strings}) ->
        expect(referencedRepo.rooms).to.eql ['#abc']
        expect(strings[0]).to.equal "#{envelope.room} is no longer subscribing to PR changes in repo http://mocha.com/"
