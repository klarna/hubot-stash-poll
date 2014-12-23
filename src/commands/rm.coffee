format = require '../utils/format'


# =========================================================================
#  PRIVATE METHODS
# =========================================================================
responses =
  invalidURI: (msg, uri) ->
    msg.reply "Sorry, #{uri} doesn't look like a valid URI to me"

  unregistered: (msg, uri) ->
    room = msg.message.user.room
    msg.reply "#{room} is no longer subscribing to PR changes in repo #{uri}"

  failed: (msg, uri) ->
    room = msg.message.user.room
    msg.reply "Something went wrong! Could not unsubscibe from #{uri} in " +
              "room #{room}"

  exception: (msg, uri, e) ->
    room = msg.message.user.room
    msg.reply "An exception occurred! Could not remove subscription for " +
              "#{uri} in room #{room}. Message: #{e.message}"


tryUnregister = (msg, uri, broker) ->
  roomHandle = format.room.handle(msg)

  if broker.tryUnregisterRepo(uri, roomHandle)
    responses.unregistered(msg, uri)
  else
    responses.failed(msg, apiUrl)


module.exports = ({msg, broker}) ->
  matchedUri = msg.match?[1]

  try
    apiUrl = broker.getNormalizedApiUrl(matchedUri)

    if apiUrl
      tryUnregister(msg, apiUrl, broker)
    else
      responses.invalidURI(matchedUri)
  catch e
    responses.exception(msg, matchedUri, e)
