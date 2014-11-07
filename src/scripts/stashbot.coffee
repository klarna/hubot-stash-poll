# Description:
#   Hubot integration with Atlassian Stash.
#
# Configuration:
#  HUBOT_STASH_USERNAME
#  HUBOT_STASH_PASSWORD
#
# Commands:
#   hubot stash pr - Lists the subscriptions in the current room
#   hubot stash pr subscribe <api url> - Subscribe current room to PR changes on the given API url, e.g. https://stashurl.com/rest/api/1.0/projects/MYPROJ/repos/MYREPO/pull-requests
#   hubot stash pr unsubscribe <api url> - Unsubscribe current room from PR changes on the given API url, e.g. https://stashurl.com/rest/api/1.0/projects/MYPROJ/repos/MYREPO/pull-requests
#
# Authors:
#   Christoffer Skeppstedt (chris.skeppstedt@klarna.com, http://github.com/cskeppstedt/)


Broker = require '../utils/broker'
Poller = require '../utils/poller'
config = require '../config/config'


stashbot = (robot) ->
  stashbot.poller = new Poller robot: robot
  stashbot.broker = new Broker robot: robot


  # =========================================================================
  #  RESPONSES
  # =========================================================================
  robot.respond /stash pr$/i, (msg) ->
    room = msg.message.user.room

    try
      repos = stashbot.broker.getSubscribedReposFor room
      urls = repos.map (r) -> r.api_url
      msg.reply "#{room} is subscribing to PR changes from the #{urls.length} repo(s): #{urls.join ', '}"
    catch e
      msg.reply "An exception occurred! Could not list subscriptions for room #{room}. Message: #{e.message}"



  robot.respond /stash pr subscribe (.*)/i, (msg) ->
    room = msg.message.user.room

    try
      apiUrl = stashbot.broker.getNormalizedApiUrl msg.match?[1]
      if not apiUrl?
        msg.reply "Sorry, #{msg.match?[1]} doesn't look like a valid URI to me"
        return

      if stashbot.broker.tryRegisterRepo apiUrl, room
        msg.reply "#{room} is now subscribing to PR changes in repo #{apiUrl}"
      else
        msg.reply "Something went wrong! Could not add subscription for #{apiUrl} in room #{room}"
    catch e
      msg.reply "An exception occurred! Could not add subscription for #{apiUrl} in room #{room}. Message: #{e.message}"


  robot.respond /stash pr unsubscribe (.*)/i, (msg) ->
    room = msg.message.user.room

    try
      apiUrl = stashbot.broker.getNormalizedApiUrl msg.match?[1]
      if not apiUrl?
        msg.reply "Sorry, #{msg.match?[1]} doesn't look like a valid URI to me"
        return

      if stashbot.broker.tryUnregisterRepo apiUrl, room
        msg.reply "#{room} is no longer subscribing to PR changes in repo #{apiUrl}"
      else
        msg.reply "Something went wrong! Could not unsubscibe from #{apiUrl} in room #{room}"
    catch e
      msg.reply "An exception occurred! Could not unsubscibe from #{apiUrl} in room #{room}. Message: #{e.message}"



  # =========================================================================
  #  POLLING
  # =========================================================================
  sendRoomMessages = (prData, message) ->
    repo = robot.brain.data.stashPr?.repos?[prData.api_url]
    return if not repo? or not repo.rooms?

    for room in repo.rooms
      robot.messageRoom room, message


  stashbot.poller.events.on 'pr:open', (prData) ->
    sendRoomMessages prData, "PR ##{prData.pr_id} opened: #{prData.pr_url}"


  stashbot.poller.events.on 'pr:merge', (prData) ->
    sendRoomMessages prData, "PR ##{prData.pr_id} merged: #{prData.pr_url}"


  stashbot.poller.events.on 'pr:decline', (prData) ->
    sendRoomMessages prData, "PR ##{prData.pr_id} declined: #{prData.pr_url}"


  stashbot.poller.start()


module.exports = stashbot