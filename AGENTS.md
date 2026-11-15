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
- **`CHANGELOG.md` is Release Please's.** Never edit it by hand.
- **Keep secrets out of the repo.** The Lichess token comes from the
  environment and is never written to a tracked file.

## Before opening a PR

```sh
npm ci
npx commitlint --from origin/main --to HEAD --verbose
pre-commit run --all-files
```

## Things that need the owner

Repository settings and secrets, the release bot, and the Lichess account and
its token. List them in the PR instead of attempting them.
