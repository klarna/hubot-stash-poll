fs = require 'fs'
url = require 'url'
path = require 'path'
expect = require('chai').expect
nock = require 'nock'

testContext = require('../test_context')
Poller = require('../../src/utils/poller')


asyncAssert = (done, assert) ->
  try
    assert()
    done()
  catch e
    done(e)


describe 'utils | poller', ->
  context = {}

  beforeEach (done) ->
    # event listeners
    context.listeners = []

    # repos available to stub Brain data
    context.repos = [
      api_url: 'http://test_repo1.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests'
      rooms: ['#mocha']
      pull_requests:
        '101':
          state: 'OPEN'
          url: 'http://test_repo1.com/projects/proj1/repos/repo1/pull-requests/101'
          title: 'Pr 101, Repo 1, Project 1'
        '102':
          state: 'MERGED'
          url: 'http://test_repo1.com/projects/proj1/repos/repo1/pull-requests/102'
          title: 'Pr 102, Repo 1, Project 1'
        '103':
          state: 'DECLINED'
          url: 'http://test_repo1.com/projects/proj1/repos/repo1/pull-requests/103'
          title: 'Pr 103, Repo 1, Project 1'
    ,
      api_url: 'http://test_repo2.com/rest/api/1.0/projects/proj2/repos/repo2/pull-requests'
      rooms: ['#mocha']
      pull_requests:
        '201':
          state: 'OPEN'
          url: 'http://test_repo2.com/projects/proj2/repos/repo2/pull-requests/201'
    ]

    # mock the Stash requests
    nock.activate() if not nock.isActive()
    nock.disableNetConnect()
    nock.enableNetConnect('localhost')

    context.nocks = for repo in context.repos
      u = url.parse repo.api_url
      do (u) -> nock("#{u.protocol}//#{u.host}").get("#{u.path}?state=ALL").reply 200, ->
        fs.createReadStream(path.resolve "test/fixture/#{u.hostname}_pull-requests.json")

    testContext (testContext) ->
      context.robot = testContext.robot
      context.sandbox = testContext.sandbox
      context.user = testContext.user

      context.poller = new Poller(robot: context.robot)
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
      for repo in context.repos
        context.robot.brain.data['stash-poll'][repo.api_url] = repo

      # when
      context.poller.fetchRepositories()

      # then
      for n in context.nocks
        expect(n.isDone()).to.equal true


    it 'should emit an event for an unseen PR that is open', (done) ->
      # given
      context.robot.brain.data['stash-poll'][context.repos[0].api_url] = context.repos[0]

      expectedPr =
        api_url: 'http://test_repo1.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests'
        pr_id: 104
        pr_url: 'http://test_repo1.com/projects/proj1/repos/repo1/pull-requests/104'
        pr_title: 'Pr 104, Repo 1, Project 1'

      spy = context.sandbox.spy()
      onEmit 'pr:open', spy

      onEmit 'poll:end', ->
        # then
        asyncAssert done, ->
          expect(spy.calledWithExactly expectedPr).to.equal true

      # when
      context.poller.fetchRepositories()


    it 'should emit an event for an existing PR that has been merged', (done) ->
      # given
      context.repos[0].pull_requests['102'].state = 'OPEN'
      context.robot.brain.data['stash-poll'][context.repos[0].api_url] = context.repos[0]

      expectedPr =
        api_url: 'http://test_repo1.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests'
        pr_id: 102
        pr_url: 'http://test_repo1.com/projects/proj1/repos/repo1/pull-requests/102'
        pr_title: 'Pr 102, Repo 1, Project 1'

      spy = context.sandbox.spy()
      onEmit 'pr:merge', spy

      onEmit 'poll:end', ->
        # then
        asyncAssert done, ->
          expect(spy.calledWithExactly expectedPr).to.equal true

      # when
      context.poller.fetchRepositories()


    it 'should emit an event for an existing PR that has been declined', (done) ->
      # given
      context.repos[0].pull_requests['103'].state = 'OPEN'
      context.robot.brain.data['stash-poll'][context.repos[0].api_url] = context.repos[0]

      expectedPr =
        api_url: 'http://test_repo1.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests'
        pr_id: 103
        pr_url: 'http://test_repo1.com/projects/proj1/repos/repo1/pull-requests/103'
        pr_title: 'Pr 103, Repo 1, Project 1'

      spy = context.sandbox.spy()
      onEmit 'pr:decline', spy

      onEmit 'poll:end', ->
        # then
        asyncAssert done, ->
          expect(spy.calledWithExactly expectedPr).to.equal true

      # when
      context.poller.fetchRepositories()


    it 'should not emit an event for an unseen PR that is merged', (done) ->
      # given
      context.robot.brain.data['stash-poll'][context.repos[0].api_url] = context.repos[0]

      expectedPr =
        api_url: 'http://test_repo1.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests'
        pr_id: 105
        pr_url: 'http://test_repo1.com/projects/proj1/repos/repo1/pull-requests/105'
        pr_title: 'Pr 105, Repo 1, Project 1'

      spy = context.sandbox.spy()
      onEmit 'pr:merge', spy

      onEmit 'poll:end', ->
        # then
        asyncAssert done, ->
          expect(spy.calledWithExactly expectedPr).to.equal false

      # when
      context.poller.fetchRepositories()


    it 'should not emit an event for an unseen PR that is declined', (done) ->
      # given
      context.robot.brain.data['stash-poll'][context.repos[0].api_url] = context.repos[0]

      expectedPr =
        api_url: 'http://test_repo1.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests'
        pr_id: 106
        pr_url: 'http://test_repo1.com/projects/proj1/repos/repo1/pull-requests/106'
        pr_title: 'Pr 106, Repo 1, Project 1'

      spy = context.sandbox.spy()
      onEmit 'pr:decline', spy

      onEmit 'poll:end', ->
        # then
        asyncAssert done, ->
          expect(spy.calledWithExactly expectedPr).to.equal false

      # when
      context.poller.fetchRepositories()


    it 'should not emit an event for an existing PR if state is unchanged', (done) ->
      # given
      context.robot.brain.data['stash-poll'][context.repos[0].api_url] = context.repos[0]

      forbiddenArgs = [
        api_url: 'http://test_repo1.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests'
        pr_id: 101
        pr_url: 'http://test_repo1.com/projects/proj1/repos/repo1/pull-requests/101'
      ,
        api_url: 'http://test_repo1.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests'
        pr_id: 102
        pr_url: 'http://test_repo1.com/projects/proj1/repos/repo1/pull-requests/102'
      ,
        api_url: 'http://test_repo1.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests'
        pr_id: 103
        pr_url: 'http://test_repo1.com/projects/proj1/repos/repo1/pull-requests/103'
      ]

      spy = context.sandbox.spy()
      onEmit 'pr:open', spy
      onEmit 'pr:merge', spy
      onEmit 'pr:decline', spy

      onEmit 'poll:end', ->
        # then
        asyncAssert done, ->
          expect(spy.calledWithExactly arg).to.equal false for arg in forbiddenArgs

      # when
      context.poller.fetchRepositories()


    it 'should persist PR state after poll', (done) ->
      # given
      context.repos[0].pull_requests['103'].state = 'OPEN'
      context.robot.brain.data['stash-poll'][context.repos[0].api_url] = context.repos[0]

      expectedPr =
        api_url: 'http://test_repo1.com/rest/api/1.0/projects/proj1/repos/repo1/pull-requests'
        pr_id: 103
        pr_url: 'http://test_repo1.com/projects/proj1/repos/repo1/pull-requests/103'
        pr_title: 'Pr 103, Repo 1, Project 1'

      spy = context.sandbox.spy()
      onEmit 'pr:decline', spy

      onEmit 'poll:end', ->
        # then
        asyncAssert done, ->
          repo = context.robot.brain.data['stash-poll'][context.repos[0].api_url]
          expect(repo.pull_requests['103'].state).to.equal 'DECLINED'

      # when
      context.poller.fetchRepositories()



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



