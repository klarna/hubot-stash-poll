format = require '../utils/format'


# =========================================================================
#  PRIVATE METHODS
# =========================================================================
responses =
  notSubscribing: (msg, uri) ->
    room = msg.message.user.room
    msg.reply "#{room} is not subscribing to #{uri} - maybe you should add it?"

  added: (msg, uri, name) ->
    msg.reply "Notifications for #{uri} will now ping #{name}"

  invalidRepo: (msg, uri) ->
    msg.reply "There was no repo with api url #{uri} - maybe you should add it?"


getSubscribedRepo = (room, broker, uri) ->
  repos = broker.getSubscribedReposFor room

  for r in repos when r.api_url is uri
    return r


# =========================================================================
#  EXPORTS
# =========================================================================
module.exports = ({msg, broker}) ->
  room = msg.message.user.room
  name = msg.match?[1]
  apiUrl = broker.getNormalizedApiUrl msg.match?[2]
  repo = broker.getRepo apiUrl

  if repo?
    subscribedRepo = getSubscribedRepo(room, broker, apiUrl)

    if subscribedRepo?
      repo.pings ||= []

      if repo.pings.indexOf name is -1
        repo.pings.push name

      responses.added(msg, apiUrl, name)
    else
      responses.notSubscribing(msg, apiUrl)
  else
    responses.invalidRepo(msg, apiUrl)
