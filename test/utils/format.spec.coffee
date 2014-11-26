# test framework
expect = require('chai').expect

# test target
format = require('../../src/utils/format')


describe 'utils | format', ->
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


    it 'should transform to emit format', ->
      # given
      input =
        id: 123
        url: 'foo.bar'
        title: 'abc'
        api_url: 'api.foo'

      # then
      expect(format.pr.toEmitFormat input).to.eql
        pr_id: 123
        pr_url: 'foo.bar'
        pr_title: 'abc'
        api_url: 'api.foo'


  # =========================================================================
  #  .repo
  # =========================================================================
  describe '.repo', ->

    # =========================================================================
    #  .nameFromUrl()
    # =========================================================================
    describe '.nameFromUrl()', ->
      it 'should return a name for a matching URL', ->
        # given
        api_url = 'http://test_repo1.com/rest/api/1.0/projects/foo-inc/repos' +
                  '/bar.git/pull-requests'

        # then
        expect(format.repo.nameFromUrl api_url).to.eql 'foo-inc/bar.git'


      it 'should return undefined for a non-matching URL', ->
        # given
        api_urls = [
          'http://mocha.com/'
          'http://asdf.com/api/projects/asdf/'
          'http://asdf.com/api/projects/asdf/repos/'
          ''
          undefined
        ]

        # then
        for url in api_urls
          expect(format.repo.nameFromUrl url).to.eql undefined


    # =========================================================================
    #  .list()
    # =========================================================================
    describe '.list()', ->
      it 'should list zero repos', ->
        # given
        room = '#mocha'
        repos = []

        expected =
          """
          #mocha is not subscribing to any PR changes
          """

        # then
        expect(format.repo.list repos, room).to.eql expected


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
        expect(format.repo.list repos, room).to.eql expected


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
        expect(format.repo.list repos, room).to.eql expected


      it 'should use friendly repo names if possible', ->
        # given
        room = '#mocha'
        repos = [
          api_url: 'http://test_repo1.com/rest/api/1.0/projects/proj1/repos' +
                   '/repo1/pull-requests'
          repo_name: 'proj1/repo1'
        ,
          api_url: 'http://r2.com/'
        ]

        expected =
          """
          #mocha is subscribing to PR changes from 2 repo(s):
            - proj1/repo1
            - http://r2.com/
          """

        # then
        expect(format.repo.list repos, room).to.eql expected


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
              state: 'MERGED'
            '123':
              id: '123'
              title: 'Foo request'
              url: 'http://r1.com/pr/123'
              state: 'OPEN'
            '55':
              id: '123'
              title: 'Foo request'
              url: 'http://r1.com/pr/123'
              state: 'DECLINED'
        ,
          api_url: 'http://r2.com/'
        ]

        expected =
          """
          #mocha is subscribing to PR changes from 2 repo(s):
            - http://r1.com/
              - #123 (Foo request): http://r1.com/pr/123
            - http://r2.com/
          """

        # then
        expect(format.repo.list repos, room).to.equal expected


      it 'should include failCount if set and larger than 0', ->
        # given
        room = '#mocha'
        repos = [
          api_url: 'http://r1.com/'
          failCount: 99
        ]

        expected =
          """
          #mocha is subscribing to PR changes from 1 repo(s):
            - http://r1.com/ (NOTE: 99 consecutive fetch fails)
          """

        # then
        expect(format.repo.list repos, room).to.eql expected


      it 'should not include failCount if not set or invalid', ->
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
        for n in [undefined, null, 0, -1]
          repos[0].failCount = n
          expect(format.repo.list repos, room).to.eql expected



    # =========================================================================
    #  .failed()
    # =========================================================================
    describe '.failed()', ->
      it 'should include the failCount', ->
        # given
        repo =
          api_url: 'http://test_repo1.com/rest/api/1.0/projects/foo-inc' +
                   '/repos/bar.git/pull-requests'
          failCount: 3

        expected =
          "NOTE: there has been 3 consecutive fails of fetching #{repo.api_url}"

        # then
        expect(format.repo.failed repo).to.equal expected
