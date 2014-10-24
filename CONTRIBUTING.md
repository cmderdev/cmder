# How to contribute

Unfortunately we all can't work on cmder every day of the year, so I have decided to write some guidelines for contributing.

If you follow them your contribution will likely be pulled in quicker.

## Getting Started

* Fork the repository on GitHub (It's that easy)
* Create a feature branch based on the development branch.

## Making Changes

* Make changes in your seperate branch.
* Check for unnecessary whitespace with `git diff --check` before committing.
* Make sure your commit messages are easy to understand
* Squash your 'Correcting mistakes' commits if you have a lot of them. (See the 'Squashing Commits' link below)
* Make sure your changes won't affect new users or user without a customised system, try out your changes on a fresh Windows VM to see if it would affect a new user's experience.
  * Sometimes a change that helps you with your cmder experience and tools doesn't always mean other people may need/want it.

## Making Trivial Changes

### Documentation

* If the documentation is about a currently available feature in cmder or correcting already created documentation, you can safely make your changes on the master branch and pull request them onto master.

## Submitting Changes

* Push your changes to the branch in your fork of the repository.
* Submit a pull request to the develop branch of the cmder repository (unless it's a change in documentation [see above]).
* Make sure you explicitly say to not complete the pull request if you are still making changes.


# Additional Resources

* [Squashing Commits](http://gitready.com/advanced/2009/02/10/squashing-commits-with-rebase.html)
* [General GitHub documentation](http://help.github.com/)
* [GitHub pull request documentation](http://help.github.com/send-pull-requests/)
