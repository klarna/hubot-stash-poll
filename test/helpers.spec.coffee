# test framework
expect = require('chai').expect

# test target
helpers = require './helpers'


describe 'helpers', ->
  describe 'brainFor', ->
    mockbot = undefined

    beforeEach ->
      mockbot = { brain: { data: 'stash-poll': {} } }


    it 'should set a repo', ->
      # given
      brain = helpers.brainFor(mockbot)
        .repo('http://foo.bar')
        .get()

      # then
      expect(brain).to.eql
        'http://foo.bar':
          api_url: 'http://foo.bar'
          rooms: []
          pings: []


    it 'should set rooms', ->
      # given
      brain = helpers.brainFor(mockbot)
        .repo('http://foo.bar', ['#test'])
        .get()

      # then
      expect(brain).to.eql
        'http://foo.bar':
          api_url: 'http://foo.bar'
          rooms: ['#test']
          pings: []


    it 'should set pings', ->
      # given
      brain = helpers.brainFor(mockbot)
        .repo('http://foo.bar', ['#test'], ['@foobar'])
        .get()

      # then
      expect(brain).to.eql
        'http://foo.bar':
          api_url: 'http://foo.bar'
          rooms: ['#test']
          pings: ['@foobar']


    it 'should set a pull request', ->
      # given
      brain = helpers.brainFor(mockbot)
        .repo('http://foo.bar/rest/api/1.0/projects/p1/repos/r1/pull-requests', ['#r00m'])
          .pr('101', 'DECLINED')
        .get()

      # then
      expect(brain).to.eql
        'http://foo.bar/rest/api/1.0/projects/p1/repos/r1/pull-requests':
          api_url: 'http://foo.bar/rest/api/1.0/projects/p1/repos/r1/pull-requests'
          rooms: ['#r00m']
          pings: []
          pull_requests:
            '101':
              state: 'DECLINED'
              title: '#101 @ http://foo.bar/projects/p1/repos/r1/pull-requests/101'
              url: 'http://foo.bar/projects/p1/repos/r1/pull-requests/101'


    it 'should be chainable', ->
      # given
      brain = helpers.brainFor(mockbot)
        .repo('http://1.bar/pull-requests')
        .repo('http://2.bar/pull-requests', ['#r2'])
          .pr('201', 'OPEN')
          .pr('202', 'MERGED')
        .repo('http://3.bar/pull-requests', ['#r3'])
          .pr('301', 'OPEN')
        .get()

      # then
      expect(brain).to.eql
        'http://1.bar/pull-requests':
          api_url: 'http://1.bar/pull-requests'
          rooms: []
          pings: []
        'http://2.bar/pull-requests':
          api_url: 'http://2.bar/pull-requests'
          rooms: ['#r2']
          pings: []
          pull_requests:
            '201':
              state: 'OPEN'
              title: '#201 @ http://2.bar/pull-requests/201'
              url: 'http://2.bar/pull-requests/201'
            '202':
              state: 'MERGED'
              title: '#202 @ http://2.bar/pull-requests/202'
              url: 'http://2.bar/pull-requests/202'
        'http://3.bar/pull-requests':
          api_url: 'http://3.bar/pull-requests'
          rooms: ['#r3']
          pings: []
          pull_requests:
            '301':
              state: 'OPEN'
              title: '#301 @ http://3.bar/pull-requests/301'
              url: 'http://3.bar/pull-requests/301'


    it 'should return the brain', ->
      # given
      brain = helpers.brainFor(mockbot)
        .repo('http://1.bar/pull-requests')
        .get()

      # then
      expect(mockbot.brain.data['stash-poll']).to.equal brain


    it 'should return the current repo', ->
      # given
      repo = helpers.brainFor(mockbot)
        .repo('http://1.bar/pull-requests')
        .repo()

      # then
      expect(repo.api_url).to.equal 'http://1.bar/pull-requests'


    it 'should return the current pull request', ->
      # given
      pr = helpers.brainFor(mockbot)
        .repo('http://1.bar/pull-requests')
          .pr('101', 'OPEN')
          .pr()

      # then
      expect(pr.url).to.equal 'http://1.bar/pull-requests/101'
