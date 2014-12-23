format = require '../utils/format'


# =========================================================================
#  PRIVATE METHODS
# =========================================================================
responses =
  invalidURI: (msg, uri) ->
    msg.reply "Sorry, #{uri} doesn't look like a valid URI to me"

  registered: (msg, name) ->
    room = msg.message.user.room
    msg.reply "#{room} is now subscribing to PR changes from #{name}"

  invalidRepo: (msg, uri) ->
    msg.reply "#{uri} does not appear to be a valid repo (or, I lack access)"

  exception: (msg, uri, e) ->
    room = msg.message.user.room
    msg.reply "An exception occurred! Could not add subscription for #{uri} " +
              "in room #{room}. Message: #{e.message}"


tryRegister = (msg, uri, broker) ->
  roomHandle = format.room.handle(msg)

  broker.tryRegisterRepo(uri, roomHandle)
    .then ->
      name = format.repo.nameFromUrl(uri) or uri
      responses.registered(msg, name)
    .fail (e) ->
      responses.invalidRepo(msg, uri)


# =========================================================================
#  EXPORTS
# =========================================================================
module.exports = ({broker, msg}) ->
  matchedUri = msg.match?[1]
  try
    apiUrl = broker.getNormalizedApiUrl(matchedUri)

    if apiUrl
      tryRegister(msg, apiUrl, broker)
    else
      responses.invalidURI(msg, matchedUri)
  catch e
    responses.exception(msg, matchedUri, e)
