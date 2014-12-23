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


getSubscribedRepo = (roomHandle, broker, uri) ->
  repos = broker.getSubscribedReposFor roomHandle

  for r in repos when r.api_url is uri
    return r


inPingList = (repo, name) ->
  repo.pings?.indexOf(name) >= 0


# =========================================================================
#  EXPORTS
# =========================================================================
module.exports = ({msg, broker}) ->
  roomHandle = format.room.handle(msg)
  name = msg.match?[1]
  apiUrl = broker.getNormalizedApiUrl(msg.match?[2])

  if broker.getRepo(apiUrl)?
    subscribedRepo = getSubscribedRepo(roomHandle, broker, apiUrl)

    if subscribedRepo?
      unless inPingList(subscribedRepo, name)
        subscribedRepo.pings ||= []
        subscribedRepo.pings.push(name)

      responses.added(msg, apiUrl, name)
    else
      responses.notSubscribing(msg, apiUrl)
  else
    responses.invalidRepo(msg, apiUrl)
