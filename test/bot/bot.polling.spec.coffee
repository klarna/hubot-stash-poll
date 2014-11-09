# test framework
expect = require('chai').expect
rewire = require('rewire')

# dependencies/helpers
TextMessage = require('hubot/src/message').TextMessage
helpers = require('../helpers')
testContext = require('../test_context')

# test target
bot = rewire('../../src/scripts/bot')



describe 'bot | polling', ->
  context = {}

  beforeEach (done) ->
    testContext (testContext) ->
      context.robot = testContext.robot
      context.sandbox = testContext.sandbox
      context.user = testContext.user
      bot(context.robot)
      context.poller = bot.__get__('utils').poller
      done()


  afterEach ->
    context.sandbox.restore()



  # =========================================================================
  #  STARTUP
  # =========================================================================
  it 'should start the Poller on startup', ->
    expect(context.poller.intervalId?).to.equal true



  # =========================================================================
  #  MESSAGES
  # =========================================================================
  it 'should send a group message on opened PR', (done) ->
    # given
    context.robot.brain.data['stash-poll'] =
      'http://test_repo1.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests':
        api_url: 'http://test_repo1.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests'
        rooms: ['#mocha']

    context.robot.adapter.on 'send', (envelope, strings) ->
      helpers.asyncAssert done, ->
        # then
        expect(envelope.room).to.equal '#mocha'
        expect(strings[0]).to.equal "#103 (Pr 103, Repo 1, Project 1) opened: " +
          "http://test_repo1.com/projects/proj1/repos/repo1/pull-requests/103"

    # when
    context.poller.events.emit 'pr:open',
      api_url: 'http://test_repo1.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests'
      pr_id: 103
      pr_url: 'http://test_repo1.com/projects/proj1/repos/repo1/pull-requests/103'
      pr_title: 'Pr 103, Repo 1, Project 1'



  it 'should send a group message on merged PR', (done) ->
    # given
    context.robot.brain.data['stash-poll'] =
      'http://test_repo1.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests':
        api_url: 'http://test_repo1.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests'
        rooms: ['#mocha']

    context.robot.adapter.on 'send', (envelope, strings) ->
      helpers.asyncAssert done, ->
        # then
        expect(envelope.room).to.equal '#mocha'
        expect(strings[0]).to.equal "#103 (Pr 103, Repo 1, Project 1) merged: " +
          "http://test_repo1.com/projects/proj1/repos/repo1/pull-requests/103"

    # when
    context.poller.events.emit 'pr:merge',
      api_url: 'http://test_repo1.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests'
      pr_id: 103
      pr_url: 'http://test_repo1.com/projects/proj1/repos/repo1/pull-requests/103'
      pr_title: 'Pr 103, Repo 1, Project 1'


  it 'should send a group message on declined PR', (done) ->
    # given
    context.robot.brain.data['stash-poll'] =
      'http://test_repo1.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests':
        api_url: 'http://test_repo1.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests'
        rooms: ['#mocha']

    context.robot.adapter.on 'send', (envelope, strings) ->
      helpers.asyncAssert done, ->
        # then
        expect(envelope.room).to.equal '#mocha'
        expect(strings[0]).to.equal "#103 (Pr 103, Repo 1, Project 1) declined: " +
          "http://test_repo1.com/projects/proj1/repos/repo1/pull-requests/103"

    # when
    context.poller.events.emit 'pr:decline',
      api_url: 'http://test_repo1.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests'
      pr_id: 103
      pr_url: 'http://test_repo1.com/projects/proj1/repos/repo1/pull-requests/103'
      pr_title: 'Pr 103, Repo 1, Project 1'