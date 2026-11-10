# Contributing to Cmder

Thank you for helping Cmder. Bug reports, tests, documentation, and small fixes
all help us ship useful releases. You do not need to finish every related idea
before sending a pull request (PR).

## Find the right place

- Search [issues](https://github.com/cmderdev/cmder/issues) and
  [pull requests](https://github.com/cmderdev/cmder/pulls) before opening a new one.
  Add useful details to an existing report when it describes the same problem.
- Use the [issue forms](https://github.com/cmderdev/cmder/issues/new/choose) for
  reproducible bugs and proposed features.
- Use [Discussions](https://github.com/orgs/cmderdev/discussions) for questions,
  design choices, and ideas that need agreement before implementation.
- Give a report your Windows version, Cmder version and package, terminal
  emulator, shell, steps to reproduce, and expected and actual results.
  Include a small example and remove secrets from logs and screenshots.
- For a suspected security vulnerability, use the repository's
  [security reporting page](https://github.com/cmderdev/cmder/security) to check
  the available private reporting options before sharing sensitive details.

An issue should describe one clear outcome. Link related issues, discussions,
review comments, and earlier work so the next person can find the context.

## Choose a branch

Cmder is moving to the following branch model:

| Branch | Purpose | New work |
| --- | --- | --- |
| `main` | Current code and the next release | Send normal PRs here from a separate feature branch. |
| `legacy/1.x` | The preserved 1.x code and its maintenance releases | Send compatible 1.x bug fixes here. Link the related current-line fix when there is one. |
| `development` | Integration branch replaced by feature PRs to `main` | Continue new and unfinished work through feature PRs to `main`. |
| `master` | Default branch during the administrator handoff | Check [the migration issue](https://github.com/cmderdev/cmder/issues/3130) before targeting it. |

The transition must preserve the pre-integration `master` baseline and existing
`main` history. Creating a branch, merging the integration PR, changing the default
branch, and updating automation are separate steps. The `master` to `main`
default-branch switch needs a maintainer with the required repository access.
Until that handoff is complete, check the base branch on your PR and link the
[migration issue](https://github.com/cmderdev/cmder/issues/3130) if the GitHub default still points to `master`.

For a normal contribution, fork the repository, then create a short-lived branch
from the current `main`:

```console
git clone https://github.com/YOUR-USERNAME/cmder.git
cd cmder
git remote add upstream https://github.com/cmderdev/cmder.git
git fetch upstream
git switch -c fix/describe-the-change upstream/main
```

Before the release transition is complete, ask in the migration issue which base
contains the integrated code you need. Do not overwrite existing changes merely
to make a PR target match this table.

## Keep changes easy to review

- Give the PR one purpose. Put a larger redesign or an unrelated cleanup in a
  separate issue or PR.
- Keep existing user configuration, launch commands, and integrations working.
  Explain a required migration and offer a compatibility path when possible.
- For example, `vendor/init.bat` is a tracked compatibility shim for
  `vendor/init.cmd`. Existing terminal tasks can keep calling the shim while
  users update their task configuration. Do not ask users to delete it.
- Keep Cmder's name capitalized. Use "terminal emulator" when you mean ConEmu
  or Windows Terminal, and "shell" when you mean cmd, PowerShell, or Bash.
- Define package names and included vendors in
  [`scripts/package-profiles.json`](scripts/package-profiles.json). Keep build,
  packaging, documentation, and release asset names in agreement.
- Keep Windows PowerShell 5.1 compatibility when changing supported scripts.
  A PowerShell file containing non-ASCII text needs UTF-8 with BOM for that
  shell. Check both Windows PowerShell 5.1 and PowerShell 7 when relevant.
- Avoid committing downloaded vendors, local settings, generated archives,
  credentials, or unrelated changes.
- Use clear commit messages. You may tidy your own unpublished commits, but do
  not rewrite shared history or discard someone else's work.

## Build and check your change

Use a separate source checkout for builds and tests. The build script replaces
vendor files, and packaging clears its output directory. Do not build inside
your daily Cmder installation. Back up any custom configuration first.

For a full build on Windows, install Git, 7-Zip (`7z` on `PATH`), and Visual Studio
2022 or its Build Tools with **Desktop development with C++**, the **v143**
toolset, and a **Windows 10 SDK**. Use a developer PowerShell where `msbuild` is
on `PATH`. Vendor downloads need an internet connection.

Run these commands from the repository root:

```powershell
# Compile the launcher and download vendors for every terminal profile.
.\scripts\build.ps1 -Compile -Terminal all -Verbose

# Create the package variants and build/hashes.txt.
.\scripts\pack.ps1 -Terminal all -Verbose
```

For a launcher-only change, you can first use:

```powershell
.\scripts\build.ps1 -Compile -NoVendor -Verbose
```

That command skips vendor downloads; it does not produce a complete release.
See [`scripts/README.md`](scripts/README.md) for build and package options.

Run the quick repository checks that apply to your change:

```powershell
git diff --check
.\scripts\check-trailing-whitespace.ps1
.\scripts\test-update.ps1
```

The [Tests workflow](.github/workflows/tests.yml) also exercises command-script
extensions, the `init.bat` compatibility shim, Clink, PowerShell, and Bash.
The [Build workflow](.github/workflows/build.yml) compiles and packages Cmder.
The [CodeQL workflow](.github/workflows/codeql.yml) checks the launcher source.
Workflow files show the commands used in CI and the branches that currently
trigger them. Update those triggers as part of a branch migration.

Test the behavior you changed on Windows as well as running automated checks.
Use a fresh extraction to check a new user's experience. For startup, settings,
or migration changes, also check an existing installation with custom settings.
Check the affected terminal emulators and shells. A successful build alone
does not show that a window opens correctly or a user's settings survive.

## Send a pull request

1. Open a PR from your feature branch to the appropriate branch above. Use a
   draft PR if you are still working on it.
2. Explain the problem, the resulting behavior, and any compatibility or
   migration changes. Link the issue and the specific discussion or review
   comments that explain earlier decisions.
3. List the checks you ran and their results. Give the Windows, shell, and
   terminal versions for manual testing. State any checks you could not run.
4. Include screenshots for visible changes. For packaging changes, check the
   archive contents, filenames, variants, and hash manifest.
5. Respond to review comments, including automated reviews. Check suggestions
   against the code before applying them. Explain why you chose a different
   solution when a suggestion does not fit.
6. Resolve a review thread only after the concern is fixed, answered with an
   agreed reason, or moved to a linked follow-up that reviewers accept.

A review may uncover useful work outside the PR's scope. Create or update a
follow-up issue with the source comment, expected outcome, owner, and an easy
way to check completion. Say clearly whether it blocks this release. This lets
us ship finished work while keeping the remaining work visible.

## Maintain the backlog and project boards

Use issues as the lasting record; boards help people see their status. Prefer
an existing issue over a duplicate, and link source discussions rather than
copying them without context.

For each active item, record:

- the user problem and a small, clear completion checklist;
- the owner, affected release line, and source links;
- its state: **Backlog**, **Ready**, **In progress**, **In review**, or **Done**;
- a specific dependency or required permission if the item is blocked.

Record release blockers and affected release lines explicitly. Keep every
unfinished requirement active, with its source context and owner. Age or
inactivity alone is never a reason to close, remove, archive, or lower an item's
priority.

Move an item to Done only when its stated outcome is delivered. A draft PR,
an unanswered review, or a successful build with required manual testing left
is still unfinished. Close an item only when its requirements are delivered or
explicitly superseded by linked work. Keep any remaining requirements open.

## Backport a fix to 1.x

Fix the current code first when both lines are affected. Open a separate PR
against `legacy/1.x` for a compatible backport, and link the original PR. If only
1.x is affected, explain that in the maintenance PR.

When a commit applies cleanly, `git cherry-pick -x COMMIT` keeps a link to its
origin. Review and test the result on the destination branch; matching source
does not guarantee matching behavior. If the code differs, port the small fix
by hand and explain the differences. Avoid whole-branch merges between release
lines, and keep breaking changes out of the 1.x maintenance line.

## Prepare a release

A maintainer should choose a specific commit and a version for its release
line. Check existing tags and release notes first. Describe breaking changes,
migration steps, known problems, and which package to download.

- Build the chosen commit and check the expected package variants, contents,
  licenses, and SHA-256 hashes. Keep the build run and commit linked in the
  release record.
- Test both a fresh extraction and the supported upgrade path. Check startup,
  shell initialization, terminal selection, and preservation of user settings.
  Record the tested versions and any remaining limitations.
- Use a release candidate (for example, a tag ending in `-rc.1`) when community
  testing is needed. Mark its published release as a pre-release.
- The tag build workflow creates a **draft** release. Review its attached
  packages and notes before publishing. A draft is not a public download;
  publish a tested pre-release when asking the community to try an RC.
- Publish a final release only when its release checklist is complete. Record
  remaining work in linked issues, without describing it as finished.

Keep 1.x maintenance and current releases distinct in their tags and notes.
When its release checklist is complete, publish finished work while continuing
the remaining maintenance and feature work in linked issues and PRs. Ask for
focused community testing and use the results to guide the next update.

## More help

- [GitHub: contributing to a project](https://docs.github.com/en/get-started/exploring-projects-on-github/contributing-to-a-project)
- [GitHub: creating a pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request)
- [Cmder Discussions](https://github.com/orgs/cmderdev/discussions)
