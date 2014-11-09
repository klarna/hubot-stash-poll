module.exports =
  # =========================================================================
  #  LIST
  # =========================================================================
  listRepos: (repos, inRoom) ->
    if not repos? or repos.length is 0
      "#{inRoom} is not subscribing to any PR changes"
    else
      repo = repos[0]
      lines = [
        "#{inRoom} is subscribing to PR changes from #{repos.length} repo(s):"
      ]

      for repo in repos
        lines.push "  - #{repo.api_url}"

        if repo.pull_requests?
          for id, pr of repo.pull_requests
            pr = repo.pull_requests[id]
            formatted = "##{id} (#{pr.title}): #{pr.url}"
            lines.push "    - #{formatted}"

      lines.join '\n'



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
