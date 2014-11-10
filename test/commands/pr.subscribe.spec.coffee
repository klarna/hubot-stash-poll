expect = require('chai').expect
TextMessage = require('hubot/src/message').TextMessage

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
  #  LISTENER
  # =========================================================================
  describe 'listener', ->
    it 'should register', ->
      expect(context.robot.respond.withArgs(/stash-poll add (.*)/i).calledOnce).to.equal true


    it 'should send an error message when uri is invalid', (done) ->
      context.robot.adapter.on 'reply', (envelope, strings) ->
        helpers.asyncAssert done, ->
          expect(strings[0]).to.equal "Sorry, !@£$% doesn't look like a valid URI to me"

      context.robot.adapter.receive new TextMessage(context.user, "#{context.robot.name} stash-poll add !@£$%")


    it 'should acknowledge a repo subscription with friendly name if possible', (done) ->
      url = 'http://a.com/api/projects/asdf/repos/f00'
      context.robot.adapter.on 'reply', (envelope, strings) ->
        helpers.asyncAssert done, ->
          expect(strings[0]).to.equal "#{envelope.room} is now subscribing to PR changes from asdf/f00"

      context.robot.adapter.receive new TextMessage(context.user, "#{context.robot.name} stash-poll add #{url}")


    it 'should acknowledge a repo subscription with api url if friendly name not possible', (done) ->
      context.robot.adapter.on 'reply', (envelope, strings) ->
        helpers.asyncAssert done, ->
          expect(strings[0]).to.equal "#{envelope.room} is now subscribing to PR changes from http://gogogo.com/"

      context.robot.adapter.receive new TextMessage(context.user, "#{context.robot.name} stash-poll add http://gogogo.com/")



  # =========================================================================
  #  EMPTY BRAIN
  # =========================================================================
  describe 'given an empty brain', ->
    it 'should save a new repo subscription to the brain', (done) ->
      context.robot.adapter.on 'reply', (envelope, strings) ->
        helpers.asyncAssert done, ->
          expect(context.robot.brain.data['stash-poll']['http://gogogo.com/'].api_url).to.eql 'http://gogogo.com/'
          expect(context.robot.brain.data['stash-poll']['http://gogogo.com/'].rooms).to.eql [envelope.room]

      context.robot.adapter.receive new TextMessage(context.user, "#{context.robot.name} stash-poll add http://gogogo.com/")



  # =========================================================================
  #  NON-EMPTY BRAIN
  # =========================================================================
  describe 'given a non-empty brain', ->
    beforeEach ->
      context.robot.brain.data['stash-poll'] =
        'http://abc.com/':
          api_url: 'http://abc.com/'
          rooms: ['#abc']
        'http://mocha.com/':
          api_url: 'http://mocha.com/'
          rooms: ['#mocha']


    it 'should push the room to a repo if it doesn\'t already exist', (done) ->
      context.robot.adapter.on 'reply', (envelope, strings) ->
        helpers.asyncAssert done, ->
          expect(context.robot.brain.data['stash-poll']['http://abc.com/'].rooms).to.eql ['#abc','#mocha']

      context.robot.adapter.receive new TextMessage(context.user, "#{context.robot.name} stash-poll add http://abc.com/")


    it 'should not push the room to a repo if it already exists', (done) ->
      context.robot.adapter.on 'reply', (envelope, strings) ->
        helpers.asyncAssert done, ->
          expect(context.robot.brain.data['stash-poll']['http://mocha.com/'].rooms).to.eql ['#mocha']

      context.robot.adapter.receive new TextMessage(context.user, "#{context.robot.name} stash-poll add http://mocha.com/")
