url = require 'url'
Q = require 'q'
{EventEmitter} = require 'events'
config = require '../config/config'


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
    promises = []

    for api_url, repo of @robot.brain.data['stash-poll']
      fetchUrl = @_buildFetchUrl api_url

      do (fetchUrl, repo) =>
        deffered = Q.defer()
        promises.push deffered.promise

        @robot.http(fetchUrl).auth(config.username, config.password).get() (err, res, body) =>
          if err?
            @robot.logger.error "HTTP GET failed for #{fetchUrl} - #{err}"
            deffered.reject(err)
          else
            @_handleResponse repo, body
            deffered.resolve()

    Q.allSettled(promises).then (results) =>
      @events.emit 'poll:end'


  _buildFetchUrl: (repoApiUrl) ->
    parsedUrl = url.parse repoApiUrl
    if parsedUrl.query?
      repoApiUrl + "&state=ALL"
    else
      repoApiUrl + "?state=ALL"


  _handleResponse: (forRepo, body) ->
    parsed = try
      JSON.parse body
    catch err
      @robot.logger.error "JSON parse failed for body - #{err}"
      null

    pullRequests = parsed?.values
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

      @events.emit eventName,
        api_url: forRepo.api_url
        pr_id: pr.id
        pr_url: pr_url
        pr_title: pr.title



module.exports = Poller