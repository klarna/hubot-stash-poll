format = require '../utils/format'


# =========================================================================
#  PRIVATE METHODS
# =========================================================================
responses =
  notSubscribing: (msg, uri) ->
    room = msg.message.user.room
    msg.reply "#{room} is not subscribing to #{uri} - maybe you should add it?"

  removed: (msg, uri, name) ->
    msg.reply "Notifications for #{uri} will no longer ping #{name}"

  invalidRepo: (msg, uri) ->
    msg.reply "There was no repo with api url #{uri} - maybe you should add it?"


getSubscribedRepo = (roomHandle, broker, uri) ->
  repos = broker.getSubscribedReposFor roomHandle

  for r in repos when r.api_url is uri
    return r


# =========================================================================
#  EXPORTS
# =========================================================================
module.exports = ({msg, broker}) ->
  roomHandle = format.room.handle(msg)
  name = msg.match?[1]
  apiUrl = broker.getNormalizedApiUrl msg.match?[2]
  repo = broker.getRepo apiUrl

  if repo?
    subscribedRepo = getSubscribedRepo(roomHandle, broker, apiUrl)

    if subscribedRepo?
      repo.pings ||= []

      index = repo.pings.indexOf name
      if index isnt -1
        repo.pings.splice index, 1

      responses.removed(msg, apiUrl, name)
    else
      responses.notSubscribing(msg, apiUrl)
  else
    responses.invalidRepo(msg, apiUrl)
