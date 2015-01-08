format = require '../utils/format'


module.exports = ({msg, broker}) ->
  room = msg.message.user.room
  roomHandle = format.room.handle(msg)

  try
    repos = broker.getSubscribedReposFor roomHandle
    msg.reply format.repo.list repos, room
  catch e
    msg.reply "An exception occurred! Could not list subscriptions for " +
              "room #{room}. Message: #{e.message}"
