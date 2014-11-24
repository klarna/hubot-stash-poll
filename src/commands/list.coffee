format = require '../utils/format'


module.exports = ({msg, broker}) ->
  room = msg.message.user.room

  try
    repos = broker.getSubscribedReposFor room
    msg.reply format.repo.list repos, room
  catch e
    msg.reply "An exception occurred! Could not list subscriptions for room #{room}. Message: #{e.message}"
