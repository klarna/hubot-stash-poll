format = require '../utils/format'


module.exports = ({msg, broker}) ->
  room = msg.message.user.room
  name = msg.match?[1]
  apiUrl = broker.getNormalizedApiUrl msg.match?[2]
  repo = broker.getRepo apiUrl

  if repo?
    repos = broker.getSubscribedReposFor room
    for r in repos
      if r.api_url is repo.api_url
        repo.pings ||= []
        if repo.pings.indexOf name is -1
          repo.pings.push name

        msg.reply "Notifications for #{apiUrl} will now ping #{name}"
        return
    msg.reply "#{room} is not subscribing to http://a.com/foo - maybe you should add it?"
  else
    msg.reply "There was no repo with api url #{apiUrl} - maybe you should add it?"
