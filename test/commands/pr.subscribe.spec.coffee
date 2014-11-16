# test framework
expect = require('chai').expect

# dependencies/helpers
Q = require('q')
url = require('url')
nock = require 'nock'
helpers = require('../helpers')
testContext = require('../test_context')

# test target
bot = require('../../src/scripts/bot')


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
    nock.restore()
    context.sandbox.restore()


  # =========================================================================
  #  INTERNAL TEST HELPERS
  # =========================================================================
  whenAdding = (api_url, httpStatus = 200) ->
    deferred = Q.defer()

    if /http*/.test api_url
      mock = { brain: data: {} }
      helpers.brainFor(mock).repo(api_url)
      helpers.nocksFor(mock, httpStatus)

    message = "stash-poll add #{api_url}"
    helpers.onRobotReply context.robot, context.user, message, (replyData) ->
      replyData.referencedRepo = context.robot.brain.data['stash-poll']?[api_url]
      deferred.resolve(replyData)

    deferred.promise


  # =========================================================================
  #  LISTENER
  # =========================================================================
  describe 'listener', ->
    it 'should register', ->
      expect(context.robot.respond.withArgs(/stash-poll add (.*)/i).calledOnce).to.equal true


    it 'should send an error message when uri is invalid', ->
      whenAdding('!@£$%').then ({envelope, strings})->
        expect(strings[0]).to.equal "Sorry, !@£$% doesn't look like a valid URI to me"


    it 'should acknowledge a repo subscription with friendly name if possible', ->
      # given
      mock = { brain: data: {} }
      repo = helpers.brainFor(mock)
        .repo('http://a.com/api/projects/asdf/repos/f00')
        .repo()

      helpers.nocksFor(mock)

      # then
      whenAdding(repo.api_url).then ({envelope, strings})->
        expect(strings[0]).to.equal "#{envelope.room} is now subscribing to PR changes from asdf/f00"


    it 'should acknowledge a repo subscription with api url if friendly name not possible', ->
      # given
      mock = { brain: data: {} }
      repo = helpers.brainFor(mock)
        .repo('http://a.com/foo')
        .repo()

      helpers.nocksFor(mock)

      whenAdding(repo.api_url).then ({envelope, strings})->
        expect(strings[0]).to.equal "#{envelope.room} is now subscribing to PR changes from http://a.com/foo"


    it 'should send an error message when subscribing to an invalid repo', ->
      # given
      whenAdding('http://fail.whale/foo', 404).then ({envelope, strings})->
        expect(strings[0]).to.equal "http://fail.whale/foo does not appear to be a valid repo (or, I lack access)"



  # =========================================================================
  #  EMPTY BRAIN
  # =========================================================================
  describe 'given an empty brain', ->
    it 'should save a new repo subscription to the brain', ->
      whenAdding('http://a.com/bar').then ({referencedRepo, envelope})->
        expect(referencedRepo.api_url).to.eql 'http://a.com/bar'
        expect(referencedRepo.rooms).to.eql [envelope.room]


  # =========================================================================
  #  NON-EMPTY BRAIN
  # =========================================================================
  describe 'given a non-empty brain', ->
    beforeEach ->
      helpers.brainFor(context.robot)
        .repo('http://b.com/', ['#abc'])
        .repo('http://a.com/', ['#mocha'])


    it 'should push the room to a repo if it doesn\'t already exist', ->
      whenAdding('http://b.com/').then ({referencedRepo})->
        expect(referencedRepo.rooms).to.eql ['#abc','#mocha']


    it 'should not push the room to a repo if it already exists', ->
      whenAdding('http://a.com/').then ({referencedRepo})->
        expect(referencedRepo.rooms).to.eql ['#mocha']
