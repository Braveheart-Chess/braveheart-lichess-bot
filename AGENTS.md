# Guidance for coding agents

This repository is the Lichess bot for [Braveheart](https://github.com/Braveheart-Chess/braveheart),
the UCI chess engine. Read [README.md](README.md) for what the project is and
[CONTRIBUTING.md](CONTRIBUTING.md) for the full rules. The rules below are the
ones you MUST follow.

## Rules

- **Never push to `main`.** Every change goes through a pull request on a branch.
- **Commits are a single line**: `type(scope)?: subject`, at most 100 characters.
  Allowed types: `feat`, `fix`, `docs`, `chore`, `refactor`, `ci`, `build`, `perf`, `style`, `test`, `revert`.
  The only thing allowed after the header is a blank line and
  `Co-authored-by: Name <email>` trailers. No body text. Put details in the PR description.
- **Open PRs with a typed template** and fill in every section:

  ```sh
  gh pr create --template <feat|fix|docs|chore|refactor|ci>.md
  ```

  The PR title MUST be a valid Conventional Commit; squash merges use it as the commit message.
- **Merges are squash or rebase only.** Never create merge commits.
- **Run the repo's checks locally before opening the PR** (see below).
- **The engine is not built or changed here.** `run.sh` takes a published
  Braveheart release (or the binary `BRAVEHEART_BIN` names). Engine changes go
  to [Braveheart-Chess/braveheart](https://github.com/Braveheart-Chess/braveheart),
  and the bot's opening book stays lichess-bot's, never the engine's.
- **Never run the bot with the deployed bot's token.** Exactly one process may
  hold a bot's token; a second one takes its games away. `./run.sh --check`
  needs no token and never contacts Lichess; use it to test changes.
- **A config change is not deployed by merging it.** Until the deployment moves
  here ([README](README.md#the-deployed-bot)), the deployed bot reads the engine
  repository's copy of the config. Say in the PR whether that copy needs the
  same change.
- **Bump the lichess-bot pin deliberately.** `LICHESS_BOT_REF` in `run.sh` is a
  commit of lichess-bot's `master`. When it changes, compare `config.yml` with
  that commit's `config.yml.default` and say what changed in the PR.
- **`CHANGELOG.md` is Release Please's.** Never edit it by hand.
- **Keep secrets out of the repo.** The Lichess token comes from the
  environment and is written only to `.lichess-bot/config.yml`, which git ignores.

## Before opening a PR

```sh
npm ci
npx commitlint --from origin/main --to HEAD --verbose
pre-commit run --all-files
npm test              # the chat greetings fit Lichess's 140-character limit
shellcheck run.sh
./run.sh --check      # lichess-bot accepts the config; the engine advertises its UCI options
```

## Things that need the owner

Repository settings and secrets, the release bot, the Lichess account and its
token, and anything that touches the deployed bot (jwall-engineering-infra's
Bot apply, its secrets, its instance). List them in the PR instead of
attempting them.
