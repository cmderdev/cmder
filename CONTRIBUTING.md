# How to contribute

This is the `legacy/1.x` maintenance line. Read the
[maintenance guide](docs/MAINTENANCE-1.x.md) before preparing a backport.
New features and normal current work follow the
[current contribution guide](https://github.com/cmderdev/cmder/blob/main/CONTRIBUTING.md)
and target `main` through feature PRs. Continue unfinished work through those PRs;
`development` must not collect ongoing work. Keep unfinished requirements active
regardless of age, preserving their source links and contributor commitments.

Unfortunately we all can't work on Cmder every day of the year, so I have decided to write some guidelines for contributing.

If you follow them your contribution will likely be pulled in quicker.

## Getting Started

* Fork the repository on GitHub (It's that easy)
* Create a separate branch from `legacy/1.x` for a compatible 1.x fix. Link its current-line fix or original report.

## Making Changes

* Make changes in your separate branch.
* Check for unnecessary whitespace with `git diff --check` before committing.
* Make sure your commit messages are easy to understand
* Keep commits focused and preserve contributor credit. Do not rewrite shared history or discard existing work.
* Make sure your changes won't affect new users or user without a customised system, try out your changes on a fresh Windows VM to see if it would affect a new user's experience.
  * Sometimes a change that helps you with your cmder experience and tools doesn't always mean other people may need/want it.

## Making Trivial Changes

### Documentation

* Send documentation about this maintenance line to `legacy/1.x`. Send documentation about current features to `main`.

## Submitting Changes

* Push your changes to the branch in your fork of the repository.
* Submit a pull request to `legacy/1.x` for a reviewed maintenance fix, or to `main` for current work.
* Open a draft pull request while the change is still in progress.


# Additional Resources

* [Squashing Commits](http://gitready.com/advanced/2009/02/10/squashing-commits-with-rebase.html)
* [General GitHub documentation](http://help.github.com/)
* [GitHub pull request documentation](http://help.github.com/articles/creating-a-pull-request/)
