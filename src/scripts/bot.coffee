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

commands =
  rm: require '../commands/rm'
  add: require '../commands/add'
  list: require '../commands/list'


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
    commands.list
      msg: msg
      broker: utils.broker


  robot.respond /stash-poll add (.*)/i, (msg) ->
    commands.add
      msg: msg
      broker: utils.broker


  robot.respond /stash-poll rm (.*)/i, (msg) ->
    commands.rm
      msg: msg
      broker: utils.broker

  robot.respond /stash-poll ping ([^\s]+) (.*)/i, (msg) ->
    room = msg.message.user.room

    # try
    #   apiUrl = utils.broker.getNormalizedApiUrl msg.match?[1]
    #   if not apiUrl?
    #     msg.reply "Sorry, #{msg.match?[1]} doesn't look like a valid URI to me"
    #     return

    #   if utils.broker.tryUnregisterRepo apiUrl, room
    #     msg.reply "#{room} is no longer subscribing to PR changes in repo #{apiUrl}"
    #   else
    #     msg.reply "Something went wrong! Could not unsubscibe from #{apiUrl} in room #{room}"
    # catch e
    #   msg.reply "An exception occurred! Could not unsubscibe from #{apiUrl} in room #{room}. Message: #{e.message}"



  # =========================================================================
  #  POLLING
  # =========================================================================
  sendRoomMessages = (forApiUrl, message) ->
    repo = robot.brain.data['stash-poll']?[forApiUrl]
    return if not repo? or not repo.rooms?

    for room in repo.rooms
      robot.messageRoom room, message


  utils.poller.events.on 'pr:open', (prData) ->
    sendRoomMessages prData.api_url, format.pr.opened(prData)


  utils.poller.events.on 'pr:merge', (prData) ->
    sendRoomMessages prData.api_url, format.pr.merged(prData)


  utils.poller.events.on 'pr:decline', (prData) ->
    sendRoomMessages prData.api_url, format.pr.declined(prData)


  utils.poller.events.on 'repo:failed', (repo) ->
    sendRoomMessages repo.api_url, format.repo.failed(repo)


  utils.poller.start()


module.exports = bot