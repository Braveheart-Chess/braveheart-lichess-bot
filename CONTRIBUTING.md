# Contributing

This repository is the Lichess bot for [Braveheart](https://github.com/Braveheart-Chess/braveheart),
the UCI chess engine. Engine changes belong in the engine repository; what
connects the engine to Lichess belongs here.

## Setup

```sh
npm ci                                                          # commitlint
pre-commit install --hook-type commit-msg --hook-type pre-commit
```

The hooks are a convenience. CI is the authoritative check.

## Commit messages

Every commit is a **single-line** [Conventional Commit](https://www.conventionalcommits.org/)
of at most 100 characters. Details go in the pull request description, never in a commit body.

- Format: `type(scope)?: subject`, with an imperative, lowercase subject and no trailing period.
- The only thing allowed after the header is a blank line followed by
  `Co-authored-by: Name <email>` trailers.
- Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `ci`, `build`, `perf`, `style`, `test`, `revert`.
- A breaking change is marked with `!`, as in `feat!: stop accepting rated games`.
- The type drives the next version: `feat` bumps the minor version, `fix` the patch,
  and `!` the major (the minor while the version is below 1.0).

| Message | Valid |
| --- | --- |
| `feat: accept correspondence challenges` | Yes |
| `fix: shorten the spectator greeting` + blank line + `Co-authored-by: Claude <noreply@anthropic.com>` | Yes |
| `feat: add thing` + blank line + `This adds the thing because…` | No, body text |
| `Added thing` | No, not conventional |

CI lints every commit in the pull request, and the pull request title separately.

## Pull requests

Every change reaches `main` through a pull request. Nobody pushes to `main`.

- The title is a valid Conventional Commit: squash merges use it as the commit message.
- Open the pull request with a typed template and fill in every section:

  ```sh
  gh pr create --template <feat|fix|docs|chore|refactor|ci>.md
  ```

- Pull requests merge by squash or rebase only. There are no merge commits.

## Releases

[Release Please](https://github.com/googleapis/release-please) keeps a release
pull request open with the next version and the changelog. Merging it tags the
version; it deploys nothing. It owns `CHANGELOG.md`; nobody edits that file by hand.

The release pull request is authored by the `jwallace145-release-bot` GitHub
App, so CI runs on it. The workflow reads the app's credentials from the
repository secrets `RELEASE_BOT_CLIENT_ID` and `RELEASE_BOT_PRIVATE_KEY`.
