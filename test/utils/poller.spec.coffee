# test framework
expect = require('chai').expect

# dependencies/helpers
nock = require 'nock'
helpers = require('../helpers')
testContext = require('../test_context')

# test target
Poller = require('../../src/utils/poller')


describe 'utils | poller', ->
  context = {}

  beforeEach (done) ->
    # event listeners
    context.listeners = []

    context.api_urls =
      a: 'http://a.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests'
      b: 'http://b.com/rest/api/1.0/projects/proj2/repos/repo2/pull-requests'

    testContext (testContext) ->
      context.robot = testContext.robot
      context.sandbox = testContext.sandbox
      context.user = testContext.user

      context.poller = new Poller(robot: context.robot)

      context.fetch = (httpStatus = 200) ->
        context.nocks = helpers.nocksFor context.robot, httpStatus
        context.poller.fetchRepositories()

      done()


  afterEach ->
    context.robot.shutdown()
    context.sandbox.restore()
    nock.restore()
    for listener in context.listeners
      context.poller.events.removeListener listener.eventName, listener.callback


  onEmit = (eventName, callback) ->
    context.poller.events.on eventName, callback
    context.listeners.push
      eventName: eventName
      callback: callback


  # =========================================================================
  #  .fetchRepositories()
  # =========================================================================
  describe '.fetchRepositories()', ->
    it 'should create a HTTP request for each repo', ->
      # given
      helpers.brainFor(context.robot)
        .repo(context.api_urls.a)
        .repo(context.api_urls.b)

      # when
      promise = context.fetch()

      # then
      promise.then ->
        for n in context.nocks
          expect(n.isDone()).to.equal true


    it 'should emit an event for an unseen PR that is open', (done) ->
      # given
      helpers.brainFor(context.robot)
        .repo(context.api_urls.a)
          .pr('101', 'OPEN')
          .pr('102', 'MERGED')
          .pr('103', 'DECLINED')

      unseen =
        pr_id: 104
        pr_url: 'http://a.com/projects/proj1/repos/repo1/pull-requests/104'
        api_url: context.api_urls.a
        pr_title: 'Pr 104, Repo 1, Project 1'

      spy = context.sandbox.spy()
      onEmit 'pr:open', spy

      onEmit 'poll:end', ->
        # then
        helpers.asyncAssert done, ->
          expect(spy.calledWithExactly unseen).to.equal true

      # when
      context.fetch()


    it 'should emit an event for an existing PR that has been merged', (done) ->
      # given
      pr = helpers.brainFor(context.robot)
        .repo(context.api_urls.a)
          .pr('102', 'OPEN')
          .pr()

      expectedPr = helpers.asEmittedPR pr
      expectedPr.pr_title = 'Pr 102, Repo 1, Project 1'

      spy = context.sandbox.spy()
      onEmit 'pr:merge', spy

      onEmit 'poll:end', ->
        # then
        helpers.asyncAssert done, ->
          expect(spy.calledWithExactly expectedPr).to.equal true

      # when
      context.fetch()


    it 'should emit an event for an existing PR that was declined', (done) ->
      # given
      pr = helpers.brainFor(context.robot)
        .repo(context.api_urls.a)
          .pr('103', 'OPEN')
          .pr()

      expectedPr = helpers.asEmittedPR pr
      expectedPr.pr_title = 'Pr 103, Repo 1, Project 1'

      spy = context.sandbox.spy()
      onEmit 'pr:decline', spy

      onEmit 'poll:end', ->
        # then
        helpers.asyncAssert done, ->
          expect(spy.calledWithExactly expectedPr).to.equal true

      # when
      context.fetch()


    it 'should not emit an event for an unseen PR that is merged', (done) ->
      # given
      helpers.brainFor(context.robot)
        .repo(context.api_urls.a)
          .pr('105', 'MERGED')
          .pr()

      spy = context.sandbox.spy()
      onEmit 'pr:merge', spy

      onEmit 'poll:end', ->
        # then
        helpers.asyncAssert done, ->
          expect(spy.called).to.equal false

      # when
      context.fetch()


    it 'should not emit an event for an unseen PR that is declined', (done) ->
      # given
      helpers.brainFor(context.robot)
        .repo(context.api_urls.a)
          .pr('106', 'DECLINED')

      spy = context.sandbox.spy()
      onEmit 'pr:decline', spy

      onEmit 'poll:end', ->
        # then
        helpers.asyncAssert done, ->
          expect(spy.called).to.equal false

      # when
      context.fetch()


    it 'should not emit an event for an existing, unchanged PR', (done) ->
      # given
      brainCtx = helpers.brainFor(context.robot)
        .repo(context.api_urls.a)

      pr101 = brainCtx.pr('101', 'OPEN').pr()
      pr102 = brainCtx.pr('101', 'MERGED').pr()
      pr103 = brainCtx.pr('101', 'DECLINED').pr()

      forbiddenArgs = [
        helpers.asEmittedPR(pr101),
        helpers.asEmittedPR(pr102),
        helpers.asEmittedPR(pr103)
      ]

      spy = context.sandbox.spy()
      onEmit 'pr:open', spy
      onEmit 'pr:merge', spy
      onEmit 'pr:decline', spy

      onEmit 'poll:end', ->
        # then
        helpers.asyncAssert done, ->
          for arg in forbiddenArgs
            expect(spy.calledWithExactly arg).to.equal false

      # when
      context.fetch()


    it 'should persist PR state after poll', (done) ->
      # given
      pr = helpers.brainFor(context.robot)
        .repo(context.api_urls.a)
          .pr('103', 'OPEN')
          .pr()

      onEmit 'poll:end', ->
        # then
        helpers.asyncAssert done, ->
          expect(pr.state).to.equal 'DECLINED'

      # when
      context.fetch()



  # =========================================================================
  #  .fetchRepository()
  # =========================================================================
  describe '.fetchRepository()', ->
    it 'should reject the promise when fetch fails', ->
      # given
      repo = helpers.brainFor(context.robot)
        .repo('http://fail.whale')
        .repo()

      helpers.nocksFor context.robot, 404

      # when
      promise = context.poller.fetchRepository(repo)

      # then
      promise.fail ->


    it 'should reject the promise when response is invalid', ->
      # given
      repo = helpers.brainFor(context.robot)
        .repo('http://invalid.org')

      helpers.nocksFor context.robot, 200

      # when
      promise = context.poller.fetchRepository(repo)

      # then
      promise.fail ->


    it 'should update failCount when fetch fails', ->
      # given
      repo = helpers.brainFor(context.robot)
        .repo('http://fail.whale')
        .repo()

      repo.failCount = 0
      helpers.nocksFor context.robot, 404

      # when
      promise = context.poller.fetchRepository(repo)

      # then
      promise.fail ->
        expect(repo.failCount).to.equal 1


    it 'should emit an event when failcount reaches 3 fails', ->
      # given
      repo = helpers.brainFor(context.robot)
        .repo('http://fail.whale')
        .repo()

      helpers.nocksFor context.robot, 404
      repo.failCount = 2
      spy = context.sandbox.spy()
      onEmit 'repo:failed', spy

      # when
      promise = context.poller.fetchRepository(repo)

      # then
      promise.fail ->
        expect(repo.failCount).to.equal 3
        expect(repo).to.eql spy.firstCall.args[0]


    it 'should not emit an event when failcount exceeds 3 fails', ->
      # given
      repo = helpers.brainFor(context.robot)
        .repo('http://fail.whale')
        .repo()

      helpers.nocksFor context.robot, 404
      repo.failCount = 3
      spy = context.sandbox.spy()
      onEmit 'repo:failed', spy

      # when
      promise = context.poller.fetchRepository(repo)

      # then
      promise.fail ->
        expect(repo.failCount).to.equal 4
        expect(spy.called).to.equal false


    it 'should reset failcount on a successful fetch', ->
      # given
      repo = helpers.brainFor(context.robot)
        .repo(context.api_urls.a)
        .repo()

      helpers.nocksFor context.robot
      repo.failCount = 3

      # when
      promise = context.poller.fetchRepository(repo)

      # then
      promise.then ->
        expect(repo.failCount).to.equal 0


  # =========================================================================
  #  START/STOP POLLING
  # =========================================================================
  describe '.start()', ->
    it 'should start an interval and store the id', ->
      # given
      stub = context.sandbox.stub global, 'setInterval', -> '12345'

      # when
      context.poller.intervalId = undefined
      context.poller.start()

      # then
      expect(stub.callCount).to.equal 1
      expect(context.poller.intervalId).to.equal '12345'


  describe '.stop()', ->
    it 'should clear the intervalId', ->
      # given
      stub = context.sandbox.stub global, 'clearInterval'

      # when
      context.poller.intervalId = '12345'
      context.poller.stop()

      # then
      expect(stub.callCount).to.equal 1
      expect(context.poller.intervalId?).to.equal false
