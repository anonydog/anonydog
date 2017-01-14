Anonydog Worker
====
This is the main bot in anonydog. It is supposed to be used in the
background through some kind of queueing system.

It mainly receives and reacts to two kinds of commands:

* fork: when someone asks for an anonymized fork via
  http://anonydog.org/fork
* pull request: when someone opens a PR to one of anonydog's repos

Cheat Sheet for Development
----
    $ bundle update
    $ bundle exec rake test
