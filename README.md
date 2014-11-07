# hubot-stash

A Hubot script that integrates with Atlassian Stash. Currently supports:

- polling pull requests for updates

## Installation

    $ npm install git://github.com/klarna/hubot-stash

## Example

    christoffer> hubot stash-poll add https://stashurl.com/rest/api/1.0/projects/MYPROJ/repos/MYREPO/pull-requests
    Hubot> christoffer: #your-room is now subscribing to PR changes in repo https://stashurl.com/rest/api/1.0/projects/MYPROJ/repos/MYREPO/pull-requests

## Configuration

See [`src/scripts/stash.coffee`](src/scripts/stash.coffee).

## Development

`gulp test` to run linting + mocha tests.
`gulp watch` to start a watcher that runs linting + mocha tests on file change.

## License

[Apache 2](LICENSE)

## Author

[cskeppstedt][user] &lt;[chris.skeppstedt@klarna.com][mail]&gt; for [Klarna AB][klarna].

## Badges

[![Build Status][travis-badge]][travis]

[travis]: https://travis-ci.org/klarna/hubot-stash
[travis-badge]: https://travis-ci.org/klarna/hubot-stash.svg?branch=master
[user]: https://github.com/cskeppstedt
[mail]: mailto:chris.skeppstedt@klarna.com
[klarna]: https://github.com/klarna