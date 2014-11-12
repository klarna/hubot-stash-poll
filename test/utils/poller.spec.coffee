fs = require 'fs'
url = require 'url'
path = require 'path'
expect = require('chai').expect
nock = require 'nock'

testContext = require('../test_context')
helpers = require('../helpers')
Poller = require('../../src/utils/poller')


describe 'utils | poller', ->
  context = {}

  beforeEach (done) ->
    # event listeners
    context.listeners = []

    # mock the Stash requests
    nock.activate() if not nock.isActive()
    nock.disableNetConnect()
    nock.enableNetConnect('localhost')

    testContext (testContext) ->
      context.robot = testContext.robot
      context.sandbox = testContext.sandbox
      context.user = testContext.user

      context.poller = new Poller(robot: context.robot)

      context.fetch = ->
        context.nocks = helpers.nocksFor context.robot
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
        .repo('http://a.com')
        .repo('http://b.com')

      # when
      context.fetch()

      # then
      for n in context.nocks
        expect(n.isDone()).to.equal true


    it 'should emit an event for an unseen PR that is open', (done) ->
      # given
      helpers.brainFor(context.robot)
        .repo('http://a.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests')
          .pr('101', 'OPEN')
          .pr('102', 'MERGED')
          .pr('103', 'DECLINED')

      unseen =
        pr_id: 104
        pr_url: 'http://a.com/projects/proj1/repos/repo1/pull-requests/104'
        api_url: 'http://a.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests'
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
        .repo('http://a.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests')
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


    it 'should emit an event for an existing PR that has been declined', (done) ->
      # given
      pr = helpers.brainFor(context.robot)
        .repo('http://a.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests')
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
        .repo('http://a.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests')
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
        .repo('http://a.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests')
          .pr('106', 'DECLINED')

      spy = context.sandbox.spy()
      onEmit 'pr:decline', spy

      onEmit 'poll:end', ->
        # then
        helpers.asyncAssert done, ->
          expect(spy.called).to.equal false

      # when
      context.fetch()


    it 'should not emit an event for an existing PR if state is unchanged', (done) ->
      # given
      brainCtx = helpers.brainFor(context.robot)
        .repo('http://a.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests')

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
          expect(spy.calledWithExactly arg).to.equal false for arg in forbiddenArgs

      # when
      context.fetch()


    it 'should persist PR state after poll', (done) ->
      # given
      pr = helpers.brainFor(context.robot)
        .repo('http://a.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests')
          .pr('103', 'OPEN')
          .pr()

      onEmit 'poll:end', ->
        # then
        helpers.asyncAssert done, ->
          expect(pr.state).to.equal 'DECLINED'

      # when
      context.fetch()



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
