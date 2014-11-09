expect = require('chai').expect
format = require('../../src/utils/format')


describe 'utils | format', ->
  # =========================================================================
  #  .listRepos()
  # =========================================================================
  describe '.listRepos()', ->
    it 'should list zero repos', ->
      # given
      room = '#mocha'
      repos = []

      expected =
        """
        #mocha is not subscribing to any PR changes
        """

      # then
      expect(format.listRepos repos, room).to.eql expected


    it 'should list a single repo', ->
      # given
      room = '#mocha'
      repos = [
        api_url: 'http://r1.com/'
      ]

      expected =
        """
        #mocha is subscribing to PR changes from 1 repo(s):
          - http://r1.com/
        """

      # then
      expect(format.listRepos repos, room).to.eql expected


    it 'should list a multiple repos', ->
      # given
      room = '#mocha'
      repos = [
        api_url: 'http://r1.com/'
      ,
        api_url: 'http://r2.com/'
      ]

      expected =
        """
        #mocha is subscribing to PR changes from 2 repo(s):
          - http://r1.com/
          - http://r2.com/
        """

      # then
      expect(format.listRepos repos, room).to.eql expected



    it 'should list all open pull requests inside repos', ->
      # given
      room = '#mocha'
      repos = [
        api_url: 'http://r1.com/'
        pull_requests:
          '8':
            id: '8'
            title: 'Bar request'
            url: 'http://r1.com/pr/8'
          '123':
            id: '123'
            title: 'Foo request'
            url: 'http://r1.com/pr/123'
      ,
        api_url: 'http://r2.com/'
      ]

      expected =
        """
        #mocha is subscribing to PR changes from 2 repo(s):
          - http://r1.com/
            - #8 (Bar request): http://r1.com/pr/8
            - #123 (Foo request): http://r1.com/pr/123
          - http://r2.com/
        """

      # then
      expect(format.listRepos repos, room).to.equal expected


  # =========================================================================
  #  .pr
  # =========================================================================
  describe '.pr', ->
    it 'should format an opened PR', ->
      # given
      input =
        pr_id: '1122'
        pr_url: 'http://foo.bar/pr/1122'
        pr_title: 'Foo request'

      expected = '#1122 (Foo request) opened: http://foo.bar/pr/1122'

      # then
      expect(format.pr.opened input).to.eql expected


    it 'should format a merged PR', ->
      # given
      input =
        pr_id: '78'
        pr_url: 'http://baz/pr/78'
        pr_title: 'Add baz'

      expected = '#78 (Add baz) merged: http://baz/pr/78'

      # then
      expect(format.pr.merged input).to.eql expected


    it 'should format a declined PR', ->
      # given
      input =
        pr_id: '33'
        pr_url: 'http://yo.yo/pr/33'
        pr_title: 'Fix tests'

      expected = '#33 (Fix tests) declined: http://yo.yo/pr/33'

      # then
      expect(format.pr.declined input).to.eql expected