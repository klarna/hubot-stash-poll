url = require 'url'
Q = require 'q'
{EventEmitter} = require 'events'
config = require '../config/config'
format = require './format'


###
# The Poller is responsible for polling all subscribed stash repos
# and will emit events when it sees new/updated pull requests.
###
class Poller
  pollInterval: config.pollIntervalMilliseconds


  constructor: ({@robot}) ->
    @events = new EventEmitter()


  start: ->
    return if @intervalId?

    @intervalId = setInterval =>
      # Don't fetch anything if the Poller was
      # started in a test environment.
      if process.env.NODE_ENV isnt 'test'
        @fetchRepositories()

    , @pollInterval


  stop: ->
    clearInterval @intervalId if @intervalId?
    @intervalId = undefined


  fetchRepositories: ->
    if not @robot.brain.data['stash-poll']?
      return

    @events.emit 'poll:begin'
    promises = for api_url, repo of @robot.brain.data['stash-poll']
      @fetchRepository repo

    Q.allSettled(promises).then (results) =>
      @events.emit 'poll:end'


  fetchRepository: (repo) ->
    deferred = Q.defer()

    fail = (e) =>
      @_handleRepoFailed(repo)
      deferred.reject(e)

    try
      fetchUrl = @_buildFetchUrl repo.api_url

      @robot.http(fetchUrl).auth(config.username, config.password).get() (err, res, body) =>
        if err?
          fail(err)
        else
          json = JSON.parse body
          pullRequests = json?.values

          if pullRequests?
            @_upsertPullrequests pullRequests, repo
            repo.failCount = 0
            deferred.resolve(repo)
          else
            fail(new Error "Invalid JSON format, expected { values: [] }")
    catch e
      fail(e)

    deferred.promise


  _handleRepoFailed: (repo) ->
    repo.failCount = 0 unless repo.failCount?
    repo.failCount += 1

    if repo.failCount is 3
      @events.emit 'repo:failed', repo


  _buildFetchUrl: (repoApiUrl) ->
    parsedUrl = url.parse repoApiUrl
    if parsedUrl.query?
      repoApiUrl + "&state=ALL"
    else
      repoApiUrl + "?state=ALL"


  _upsertPullrequests: (pullRequests, forRepo) ->
    return if not pullRequests or pullRequests.length is 0

    for pr in pullRequests
      existing = forRepo.pull_requests?[pr.id]

      # skip existing PR that has no state-change
      continue if existing? and existing.state is pr.state

      # skip unseen PR if it is merged or declined
      continue if not existing? and pr.state in ['MERGED', 'DECLINED']

      prLinks = pr.links?.self?.filter (link) -> link.href?
      pr_url = prLinks?[0]?.href

      eventName = switch pr.state.toLowerCase()
        when 'open'     then 'pr:open'
        when 'merged'   then 'pr:merge'
        when 'declined' then 'pr:decline'
        else
          @robot.logger.warning "Unrecognized PR-state: #{pr.state}"
          "pr:#{pr.state.toLowerCase()}"

      # update/insert PR state
      forRepo.pull_requests ||= {}

      if not forRepo.pull_requests[pr.id]?
        forRepo.pull_requests[pr.id] =
          id: pr.id
          title: pr.title
          url: pr_url

      forRepo.pull_requests[pr.id].state = pr.state

      @events.emit eventName, format.pr.toEmitFormat
        id: pr.id
        url: pr_url
        title: pr.title
        api_url: forRepo.api_url



module.exports = Poller