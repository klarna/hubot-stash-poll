# test framework
expect = require('chai').expect
rewire = require('rewire')

# dependencies/helpers
format = require('../../src/utils/format')
helpers = require('../helpers')
testContext = require('../test_context')

# test target
bot = rewire('../../src/scripts/bot')


describe 'bot | polling', ->
  context =
    api_url: 'http://a.test/rest/api/1.0/projects/p1/repos/r1/pull-requests'


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
    pr = helpers.brainFor(context.robot)
      .repo(context.api_url, ['#mocha'], ['@pingme'])
      .pr('103', 'OPEN')
      .pr()

    emitted = helpers.asEmittedPR(pr)

    context.robot.adapter.on 'send', (envelope, strings) ->
      helpers.asyncAssert done, ->
        # then
        expect(envelope.room).to.equal '#mocha'
        expect(strings[0]).to.equal format.pr.opened(emitted)

    # when
    context.poller.events.emit 'pr:open', emitted


  it 'should send a group message on merged PR', (done) ->
    # given
    pr = helpers.brainFor(context.robot)
      .repo(context.api_url, ['#mocha'])
      .pr('103', 'MERGED')
      .pr()

    emitted = helpers.asEmittedPR(pr)

    context.robot.adapter.on 'send', (envelope, strings) ->
      helpers.asyncAssert done, ->
        # then
        expect(envelope.room).to.equal '#mocha'
        expect(strings[0]).to.equal format.pr.merged(emitted)

    # when
    context.poller.events.emit 'pr:merge', emitted


  it 'should send a group message on declined PR', (done) ->
    # given
    pr = helpers.brainFor(context.robot)
      .repo(context.api_url, ['#mocha'])
      .pr('103', 'DECLINED')
      .pr()

    emitted = helpers.asEmittedPR(pr)

    context.robot.adapter.on 'send', (envelope, strings) ->
      helpers.asyncAssert done, ->
        # then
        expect(envelope.room).to.equal '#mocha'
        expect(strings[0]).to.equal format.pr.declined(emitted)

    # when
    context.poller.events.emit 'pr:decline', emitted


  it 'should send a group message on failed repo', (done) ->
    # given
    repo = helpers.brainFor(context.robot)
      .repo('http://fail.whale', ['#mocha'])
      .repo()

    repo.failCount = 5

    context.robot.adapter.on 'send', (envelope, strings) ->
      helpers.asyncAssert done, ->
        # then
        expect(envelope.room).to.equal '#mocha'
        expect(strings[0]).to.equal format.repo.failed(repo)

    # when
    context.poller.events.emit 'repo:failed', repo
