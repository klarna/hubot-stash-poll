# Description:
#   Hubot integration with Atlassian Stash.
#
# Configuration:
#  HUBOT_STASH_USERNAME
#  HUBOT_STASH_PASSWORD
#
# Commands:
#   hubot stash-poll - Lists the subscriptions in the current room
#   hubot stash-poll add <api url> - Subscribe current room to PR changes on the given API url, e.g. https://stashurl.com/rest/api/1.0/projects/MYPROJ/repos/MYREPO/pull-requests
#   hubot stash-poll rm <api url> - Unsubscribe current room from PR changes on the given API url, e.g. https://stashurl.com/rest/api/1.0/projects/MYPROJ/repos/MYREPO/pull-requests
#
# Authors:
#   Christoffer Skeppstedt (chris.skeppstedt@klarna.com, http://github.com/cskeppstedt/)


Broker = require '../utils/broker'
Poller = require '../utils/poller'
config = require '../config/config'
format = require '../utils/format'

# will be instantiated when bot is activated
utils =
  poller: undefined
  broker: undefined


bot = (robot) ->
  utils.poller = new Poller robot: robot
  utils.broker = new Broker robot: robot


  # =========================================================================
  #  RESPONSES
  # =========================================================================
  robot.respond /stash-poll$/i, (msg) ->
    room = msg.message.user.room

    try
      repos = utils.broker.getSubscribedReposFor room
      msg.reply format.listRepos repos, room
    catch e
      msg.reply "An exception occurred! Could not list subscriptions for room #{room}. Message: #{e.message}"



  robot.respond /stash-poll add (.*)/i, (msg) ->
    room = msg.message.user.room

    try
      apiUrl = utils.broker.getNormalizedApiUrl msg.match?[1]
      if not apiUrl?
        msg.reply "Sorry, #{msg.match?[1]} doesn't look like a valid URI to me"
        return

      if utils.broker.tryRegisterRepo apiUrl, room
        name = format.repoFriendlyNameFromUrl(apiUrl) or apiUrl
        msg.reply "#{room} is now subscribing to PR changes from #{name}"
      else
        msg.reply "Something went wrong! Could not add subscription for #{apiUrl} in room #{room}"
    catch e
      msg.reply "An exception occurred! Could not add subscription for #{apiUrl} in room #{room}. Message: #{e.message}"


  robot.respond /stash-poll rm (.*)/i, (msg) ->
    room = msg.message.user.room

    try
      apiUrl = utils.broker.getNormalizedApiUrl msg.match?[1]
      if not apiUrl?
        msg.reply "Sorry, #{msg.match?[1]} doesn't look like a valid URI to me"
        return

      if utils.broker.tryUnregisterRepo apiUrl, room
        msg.reply "#{room} is no longer subscribing to PR changes in repo #{apiUrl}"
      else
        msg.reply "Something went wrong! Could not unsubscibe from #{apiUrl} in room #{room}"
    catch e
      msg.reply "An exception occurred! Could not unsubscibe from #{apiUrl} in room #{room}. Message: #{e.message}"



  # =========================================================================
  #  POLLING
  # =========================================================================
  sendRoomMessages = (prData, message) ->
    repo = robot.brain.data['stash-poll']?[prData.api_url]
    return if not repo? or not repo.rooms?

    for room in repo.rooms
      robot.messageRoom room, message


  utils.poller.events.on 'pr:open', (prData) ->
    sendRoomMessages prData, format.pr.opened(prData)


  utils.poller.events.on 'pr:merge', (prData) ->
    sendRoomMessages prData, format.pr.merged(prData)


  utils.poller.events.on 'pr:decline', (prData) ->
    sendRoomMessages prData, format.pr.declined(prData)


  utils.poller.start()


module.exports = bot