# hubot-stash-poll

[![Build Status][travis-badge]][travis] 

A Hubot script that polls pull request status from Atlassian Stash. It can also list open
pull requests. See [`src/scripts/bot.coffee`](src/scripts/bot.coffee) for command documentation.

## Installation

    $ npm install git://github.com/klarna/hubot-stash-poll

## Example

    christoffer> hubot stash-poll add https://stashurl.com/rest/api/1.0/projects/MYPROJ/repos/MYREPO/pull-requests
    Hubot> christoffer: #your-room is now subscribing to PR changes in repo MYPROJ/MYREPO

The bot will poll the repos every minute (configurable) and will post a message like this to your channel:

    Hubot> #137 (Bugfix for foobar) opened: https://stashurl.com/projects/MYPROJ/repos/MYREPO/pull-requests/137

See [`src/scripts/bot.coffee`](src/scripts/bot.coffee) for further command documentation.

## Configuration

Requires read access to the Stash repositories you will be polling. 
See [`src/config/config.coffee`](src/config/config.coffee).

## Development

`npm test` to run linting + tests.
`npm start` to start a gulp-watch that runs linting + tests on file changes.

## License

[Apache 2](LICENSE)

## Author

[cskeppstedt](https://github.com/cskeppstedt) at [Klarna](https://github.com/klarna).

[travis]: https://travis-ci.org/klarna/hubot-stash-poll
[travis-badge]: https://travis-ci.org/klarna/hubot-stash-poll.svg?branch=master
