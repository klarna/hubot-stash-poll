# hubot-stash

[![Build Status][travis-badge]][travis] 

A Hubot script that polls pull request status from Atlassian Stash.


## Installation

    $ npm install git://github.com/klarna/hubot-stash-poll

## Example

    christoffer> hubot stash-poll add https://stashurl.com/rest/api/1.0/projects/MYPROJ/repos/MYREPO/pull-requests
    Hubot> christoffer: #your-room is now subscribing to PR changes in repo https://stashurl.com/rest/api/1.0/projects/MYPROJ/repos/MYREPO/pull-requests

## Configuration

Requires read access to the Stash repositories you will be polling. 
See [`src/config/config.coffee`](src/config/config.coffee).

## Development

`gulp test` to run linting + mocha tests.
`gulp watch` to start a watcher that runs linting + mocha tests on file change.

## License

[Apache 2](LICENSE)

## Author

[cskeppstedt][user] at [Klarna AB][klarna].


[travis]: https://travis-ci.org/klarna/hubot-stash-poll
[travis-badge]: https://travis-ci.org/klarna/hubot-stash-poll.svg?branch=master
[user]: https://github.com/cskeppstedt
[mail]: mailto:chris.skeppstedt@klarna.com
[klarna]: https://github.com/klarna
