repoNameRe = new RegExp 'projects/([^/]+)/repos/([^/]+)'


module.exports =
  # =========================================================================
  #  REPOSITORY/IES
  # =========================================================================
  repo:
    nameFromUrl: (api_url) ->
      matches = api_url?.match repoNameRe

      if matches? and matches[1]? and matches[2]?
        "#{matches[1]}/#{matches[2]}"
      else
        undefined


    list: (repos, inRoom) ->
      if not repos? or repos.length is 0
        "#{inRoom} is not subscribing to any PR changes"
      else
        repo = repos[0]
        lines = [
          "#{inRoom} is subscribing to PR changes from #{repos.length} repo(s):"
        ]

        for repo in repos
          name = module.exports.repo.nameFromUrl(repo.api_url) or repo.api_url
          repoLine = "  - #{name}"
          if repo.failCount? and repo.failCount > 0
            repoLine += " (NOTE: #{repo.failCount} consecutive fetch fails)"

          lines.push repoLine

          if repo.pull_requests?
            for id, pr of repo.pull_requests when pr.state is 'OPEN'
              pr = repo.pull_requests[id]
              formatted = "##{id} (#{pr.title}): #{pr.url}"
              lines.push "    - #{formatted}"

        lines.join '\n'


    failed: (repo) ->
      expected = "NOTE: there has been #{repo.failCount} consecutive fails " +
                 "of fetching #{repo.api_url}"



  # =========================================================================
  #  PULL REQUEST NOTIFICATIONS
  # =========================================================================
  pr:
    opened: (prData) ->
      "##{prData.pr_id} (#{prData.pr_title}) opened: #{prData.pr_url}"

    merged: (prData) ->
      "##{prData.pr_id} (#{prData.pr_title}) merged: #{prData.pr_url}"

    declined: (prData) ->
      "##{prData.pr_id} (#{prData.pr_title}) declined: #{prData.pr_url}"


    toEmitFormat: ({id, url, title, api_url}) ->
      pr_id: id
      pr_url: url
      pr_title: title
      api_url: api_url
