# Contributing

This repository is the Lichess bot for [Braveheart](https://github.com/Braveheart-Chess/braveheart),
the UCI chess engine. Engine changes belong in the engine repository; what
connects the engine to Lichess belongs here.

## Setup

```sh
npm ci                                                          # commitlint and the tests
pre-commit install --hook-type commit-msg --hook-type pre-commit
```

The hooks are a convenience. CI is the authoritative check.

## Checks

| CI job | What it runs | Locally |
| --- | --- | --- |
| `Commit messages` | commitlint over every commit in `base..head` | `npx commitlint --from origin/main --to HEAD --verbose`, then `npm run test:commitlint` |
| `PR title` | The title passes commitlint, scope included | |
| `Tests` | The chat greetings fit Lichess's 140-character limit | `npm test` |
| `Lint` | ShellCheck on `run.sh` | `shellcheck run.sh` |
| `Bot check` | A full setup, lichess-bot's validation of the config, the engine's UCI options | `./run.sh --check` |

`./run.sh --check` needs no token and never contacts Lichess. To try a change
in a real game, run the bot with the token of a bot account of your own (see
[README.md](README.md#one-time-setup)), never with the deployed bot's: one
process may hold a token at a time.

## Changing the config

- `config.yml` follows the layout of lichess-bot's `config.yml.default` at the
  commit `run.sh` pins (`LICHESS_BOT_REF`). Bump the pin deliberately, and
  compare the two files when you do.
- The `greeting` lines must fit 140 characters with a 9-character version in
  place of `__VERSION__`; `npm test` checks.
- A UCI option set under `engine.uci_options` must be one the engine
  advertises; `./run.sh --check` checks against the pinned release.
- Merging a change does not deploy it; the next release does. See
  [The deployed bot](README.md#the-deployed-bot).

## Moving to a new engine release

1. Check it: `BRAVEHEART_VERSION=v0.55.0 ./run.sh --check`.
2. Change `container-image.artifact.version` in `jaws.yaml`
   in a `feat` pull request that says what the release changes (link its release
   notes) and quotes the check.
3. After it merges, merging the Release Please PR deploys it.

## Commit messages

Every commit is a **single-line** [Conventional Commit](https://www.conventionalcommits.org/) with a type and a scope:

```
type(scope): subject
```

- At most 100 characters, with an imperative, lowercase subject and no trailing period.
- `type` is one of `feat`, `fix`, `perf`, `revert`, `docs`, `refactor`, `test`, `build`, `ci`, `style`, `chore`: the same set in every repository.
- `scope` is required: exactly one of the scopes below. A change that spans two is two pull requests, or takes the scope it is mostly about.
- Breaking changes are marked with `!`, for example `feat(config)!: stop accepting rated games`.
- The only content allowed after the header is a blank line followed by `Co-authored-by: Name <email>` trailers, in any letter case. No body text. Details belong in the PR description.
- The type drives the next version: `feat` bumps the minor version, `fix` the patch, and `!` the major (the minor while the version is below 1.0).

| Message | Valid |
| --- | --- |
| `feat(config): accept correspondence challenges` | Yes |
| `fix(config): shorten the spectator greeting` + blank line + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` | Yes |
| `feat: accept correspondence challenges` | No, no scope |
| `feat(nope): accept correspondence challenges` | No, not one of this repository's scopes |
| `feat(config): accept correspondence challenges` + blank line + `This adds…` | No, body text |

commitlint enforces this with `@commitlint/config-conventional` plus three local rules in `tools/commitlint/`: `only-coauthor-trailers` fails on any line after the header that is not blank or a `Co-authored-by` trailer, `single-scope` fails on a list such as `feat(a,b)`, and `subject-lowercase` requires a lowercase subject except in Dependabot's fixed `chore(deps): Bump ...`. The fixtures in `tests/commitlint/` show accepted and rejected messages. CI lints every commit in the PR range, so a rebase merge never lands a non-conforming commit on `main`, and lints the PR title through the same config. The standard behind it is the [repository conventions](https://github.com/jwallace145/repository-template/blob/main/repository-conventions.md).

### Scopes

Every commit names exactly one of this repository's scopes. They are `SCOPES` in `commitlint.config.mjs`; this table mirrors it, in the same order, and `npm run test:commitlint` fails if they drift. Adding, renaming or removing a scope goes through a pull request like any other change.

| Scope | Covers |
| --- | --- |
| `config` | `config.yml`, the lichess-bot configuration |
| `runner` | `run.sh`, which fetches the engine release and starts the bot |
| `checks` | `tools/check-config.py` and the tests |
| `deploy` | The release-to-Lichess workflow and `jaws.yaml` |
| `repo` | README, CONTRIBUTING, AGENTS, commitlint, the PR and issue templates, and repository tooling |
| `deps` | Dependency updates, mostly Dependabot's |
| `release` | Release Please's release pull requests and its config |

## Pull requests

Every change reaches `main` through a pull request. Nobody pushes to `main`.

- The title is a valid commit header, scope included: squash merges use it as the commit message. Release Please's own pull requests are titled `chore(release): release X.Y.Z`.
- Fill in every section of the one template, `.github/pull_request_template.md` (Summary, Why, Changes, Verification, Checklist). Write "n/a" rather than deleting one.
- Pull requests merge by squash or rebase only. There are no merge commits.
- Dependabot's titles are `chore(deps): bump ...` and pass as they are; squash merge them.

## Issues

Open issues from the forms: **Bug**, **Feature** or **Task**. Blank issues are off.
## Releases

[Release Please](https://github.com/googleapis/release-please) keeps a release
pull request open with the next version and the changelog. Merging it tags the
version and deploys it to the bot (`release-to-lichess.yml`). It owns
`CHANGELOG.md`; nobody edits that file by hand.

The release pull request is authored by the `braveheart-chess-release-bot`
GitHub App, the organisation's release bot, so CI runs on it. The workflow
reads the app's credentials from the secrets `RELEASE_BOT_CLIENT_ID` and
`RELEASE_BOT_PRIVATE_KEY`.
