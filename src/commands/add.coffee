format = require '../utils/format'


module.exports = ({broker, msg}) ->
  room = msg.message.user.room

  try
    apiUrl = broker.getNormalizedApiUrl msg.match?[1]
    if not apiUrl?
      msg.reply "Sorry, #{msg.match?[1]} doesn't look like a valid URI to me"
      return

    broker.tryRegisterRepo(apiUrl, room)
      .then ->
        name = format.repo.nameFromUrl(apiUrl) or apiUrl
        msg.reply "#{room} is now subscribing to PR changes from #{name}"
      .fail (e) ->
        msg.reply "#{apiUrl} does not appear to be a valid repo (or, I lack access)"
        if e
          msg.reply e.toString()
  catch e
    msg.reply "An exception occurred! Could not add subscription for #{apiUrl} in room #{room}. Message: #{e.message}"
