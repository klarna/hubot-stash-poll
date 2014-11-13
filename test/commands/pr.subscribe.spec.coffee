expect = require('chai').expect

testContext = require('../test_context')
bot = require('../../src/scripts/bot')
helpers = require('../helpers')



describe 'commands | pr | subscribe', ->
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
  whenAdding = (api_url, expectCallback) ->
    message = "stash-poll add #{api_url}"
    helpers.onRobotReply context.robot, context.user, message, (replyData) ->
      replyData.referencedRepo = context.robot.brain.data['stash-poll']?[api_url]
      expectCallback(replyData)



  # =========================================================================
  #  LISTENER
  # =========================================================================
  describe 'listener', ->
    it 'should register', ->
      expect(context.robot.respond.withArgs(/stash-poll add (.*)/i).calledOnce).to.equal true


    it 'should send an error message when uri is invalid', ->
      whenAdding '!@£$%', ({envelope, strings})->
        expect(strings[0]).to.equal "Sorry, !@£$% doesn't look like a valid URI to me"


    it 'should acknowledge a repo subscription with friendly name if possible', ->
      whenAdding 'http://a.com/api/projects/asdf/repos/f00', ({envelope, strings})->
        expect(strings[0]).to.equal "#{envelope.room} is now subscribing to PR changes from asdf/f00"


    it 'should acknowledge a repo subscription with api url if friendly name not possible', ->
      whenAdding 'http://gogogo.com/', ({envelope, strings})->
        expect(strings[0]).to.equal "#{envelope.room} is now subscribing to PR changes from http://gogogo.com/"



  # =========================================================================
  #  EMPTY BRAIN
  # =========================================================================
  describe 'given an empty brain', ->
    it 'should save a new repo subscription to the brain', ->
      whenAdding 'http://gogogo.com/', ({referencedRepo, envelope})->
        expect(referencedRepo.api_url).to.eql 'http://gogogo.com/'
        expect(referencedRepo.rooms).to.eql [envelope.room]



  # =========================================================================
  #  NON-EMPTY BRAIN
  # =========================================================================
  describe 'given a non-empty brain', ->
    beforeEach ->
      helpers.brainFor(context.robot)
        .repo('http://abc.com/', ['#abc'])
        .repo('http://mocha.com/', ['#mocha'])


    it 'should push the room to a repo if it doesn\'t already exist', ->
      whenAdding 'http://abc.com/', ({referencedRepo})->
        expect(referencedRepo.rooms).to.eql ['#abc','#mocha']


    it 'should not push the room to a repo if it already exists', ->
      whenAdding 'http://mocha.com/', ({referencedRepo})->
        expect(referencedRepo.rooms).to.eql ['#mocha']
