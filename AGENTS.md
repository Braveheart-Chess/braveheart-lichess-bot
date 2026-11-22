# Guidance for coding agents

This repository is the Lichess bot for [Braveheart](https://github.com/Braveheart-Chess/braveheart),
the UCI chess engine. Read [README.md](README.md) for what the project is and
[CONTRIBUTING.md](CONTRIBUTING.md) for the full rules. The rules below are the
ones you MUST follow.

## Rules

- **Never push to `main`.** Every change goes through a pull request on a branch.
- **Commits are a single line**: `type(scope): subject`, at most 100 characters, with a lowercase imperative subject and no trailing period. Types: `feat`, `fix`, `perf`, `revert`, `docs`, `refactor`, `test`, `build`, `ci`, `style`, `chore`; never invent another. Scope: exactly one of `SCOPES` in `commitlint.config.mjs` (the Scopes table in CONTRIBUTING.md); never invent one, and if none fits, ask. The only thing allowed after the header is a blank line and `Co-authored-by: Name <email>` trailers. No body text. Put details in the PR description.
- **PR titles are valid commit headers**, scope included; squash merges use the title as the commit message.
- **PR bodies use the template's sections, in order, every one filled in**; write "n/a" rather than deleting one:

  ```sh
  gh pr create --title "type(scope): subject" --body-file <file>
  ```
- **Merges are squash or rebase only.** Never create merge commits.
- **Run the repo's checks locally before opening the PR** (see below).
- **The engine is not built or changed here.** `run.sh` takes a published
  Braveheart release (or the binary `BRAVEHEART_BIN` names). Engine changes go
  to [Braveheart-Chess/braveheart](https://github.com/Braveheart-Chess/braveheart),
  and the bot's opening book stays lichess-bot's, never the engine's.
- **Never run the bot with the deployed bot's token.** Exactly one process may
  hold a bot's token; a second one takes its games away. `./run.sh --check`
  needs no token and never contacts Lichess; use it to test changes.
- **Merging deploys nothing; a release does.** A change to `config.yml` or the
  engine pin (`container-image.artifact.version`) reaches the bot when the
  Release Please PR is merged ([README](README.md#the-deployed-bot)). Never
  merge that PR yourself unless the owner asks: it changes what the live bot
  plays. Say in your PR what the bot will do differently.
- **Pin only a published engine release.** The pin must be a `vX.Y.Z` release
  of the engine repository with its Linux asset attached; run
  `BRAVEHEART_VERSION=<tag> ./run.sh --check` first, and quote it in the PR.
- **Bump the lichess-bot pin deliberately.** `LICHESS_BOT_REF` in `run.sh` is a
  commit of lichess-bot's `master`. When it changes, compare `config.yml` with
  that commit's `config.yml.default` and say what changed in the PR.
- **`CHANGELOG.md` is Release Please's.** Never edit it by hand.
- **Keep secrets out of the repo.** The Lichess token comes from the
  environment and is written only to `.lichess-bot/config.yml`, which git ignores.

## Before opening a PR

```sh
npm ci
npm run test:commitlint   # the commit rules, the scopes table and the fixtures
npx commitlint --from origin/main --to HEAD --verbose
pre-commit run --all-files
npm test              # the chat greetings fit Lichess's 140-character limit
shellcheck run.sh
./run.sh --check      # lichess-bot accepts the config; the engine advertises its UCI options
```

## Things that need the owner

Repository settings and secrets, the release bot, the Lichess account and its
token, merging the Release Please PR, and anything else that touches the
deployed bot (jaws's Bot apply, its secrets, its instance).
List them in the PR instead of attempting them.
