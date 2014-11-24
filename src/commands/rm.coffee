format = require '../utils/format'


module.exports = ({msg, broker}) ->
  room = msg.message.user.room

  try
    apiUrl = broker.getNormalizedApiUrl msg.match?[1]
    if not apiUrl?
      msg.reply "Sorry, #{msg.match?[1]} doesn't look like a valid URI to me"
      return

    if broker.tryUnregisterRepo apiUrl, room
      msg.reply "#{room} is no longer subscribing to PR changes in repo #{apiUrl}"
    else
      msg.reply "Something went wrong! Could not unsubscibe from #{apiUrl} in room #{room}"
  catch e
    msg.reply "An exception occurred! Could not unsubscibe from #{apiUrl} in room #{room}. Message: #{e.message}"
