url = require 'url'


###
# The Broker is responsible for adding/removing subscriptions
###
class Broker
  constructor: ({@robot}) ->


  tryRegisterRepo: (apiUrl, room) ->
    apiUrl = @getNormalizedApiUrl apiUrl
    if not apiUrl?
      return false

    @_ensureBrain()
    repo = @robot.brain.data['stash-poll'][apiUrl]

    if repo?
      repo.rooms ?= []
      repo.rooms.push(room) if room not in repo.rooms
    else
      repo =
        api_url: apiUrl
        rooms: [room]

    @robot.brain.data['stash-poll'][apiUrl] = repo
    return true


  tryUnregisterRepo: (apiUrl, room) ->
    repo = @robot.brain.data['stash-poll']?[apiUrl]

    if repo?.rooms?.length >= 0
      index = repo.rooms.indexOf room

      if index >= 0
        repo.rooms.splice index, 1
        return true

    return false


  getNormalizedApiUrl: (apiUrl) ->
    if typeof apiUrl isnt 'string'
      return null

    parsedUrl = url.parse apiUrl
    if not parsedUrl.host?
      return null

    url.format(parsedUrl).toLowerCase()


  getSubscribedReposFor: (room) ->
    repos = []
    for api_url, repo of @robot.brain.data['stash-poll']
      if repo.rooms? and repo.rooms.indexOf(room) >= 0
        repos.push repo

    repos


  _ensureBrain: ->
    if not @robot.brain.data['stash-poll']?
      @robot.brain.data['stash-poll'] = {}



module.exports = Broker