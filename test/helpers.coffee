Q = require 'q'
TextMessage = require('hubot/src/message').TextMessage


module.exports =
  asyncAssert: (done, assert) ->
    try
      assert()
      done()
    catch e
      done(e)


  onRobotReply: (robot, user, message, replyCallback) ->
    Q.Promise (resolve, reject) ->
      robot.adapter.on 'reply', (envelope, strings) ->
        try
          resolve replyCallback
            envelope: envelope
            strings: strings
        catch e
          reject e

      robot.adapter.receive new TextMessage(user, "#{robot.name} #{message}")