fs = require 'fs'
path = require 'path'
Q = require 'q'
url = require 'url'
nock = require 'nock'
format = require '../src/utils/format'
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


  brainFor: (robot) ->
    ctx =
      brain: robot.brain.data['stash-poll'] = {}
      repo: undefined
      pr: undefined

    api =
      repo: (api_url, rooms) ->
        return ctx.repo unless arguments.length > 0

        ctx.repo = ctx.brain[api_url] =
          api_url: api_url
          rooms: rooms ? []

        api

      pr: (id, state) ->
        return ctx.pr unless arguments.length > 0
        pr_url = "#{ctx.repo.api_url}/#{id}"
          .replace('/rest/api/1.0', '')

        prs = (ctx.repo.pull_requests ||= {})
        ctx.pr = prs[id] =
          state: state
          url: pr_url
          title: "##{id} @ #{pr_url}"

        api

      get: ->
        ctx.brain

    api


  nocksFor: (robot) ->
    for api_url, repo of robot.brain.data['stash-poll']
      u = url.parse repo.api_url
      do (u) -> nock("#{u.protocol}//#{u.host}").get("#{u.path}?state=ALL").reply 200, ->
        fs.createReadStream(path.resolve "test/fixture/#{u.hostname}_pull-requests.json")


  asEmittedPR: (pull_request) ->
    format.pr.toEmitFormat
      id: parseInt pull_request.url.split('/').reverse()[0], 10
      url: pull_request.url
      title: pull_request.title
      api_url: pull_request.url
        .replace('/projects/', '/rest/api/1.0/projects/')
        .replace(/\/\d+$/, '')
