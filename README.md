<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/Braveheart-Chess/braveheart-branding/main/banner-dark.png">
    <img src="https://raw.githubusercontent.com/Braveheart-Chess/braveheart-branding/main/banner-light.png" alt="Braveheart" width="640">
  </picture><br>
  <sub>Logo © the artist, used under licence. All rights reserved; not covered by this repository's licence (<a href="https://github.com/Braveheart-Chess/braveheart-branding#licence">details</a>).</sub>
</p>

# braveheart-lichess-bot

The Lichess bot for [Braveheart](https://github.com/Braveheart-Chess/braveheart),
the UCI chess engine: play the engine, or watch it play, on Lichess through a
bot account.

The bridge is [lichess-bot](https://github.com/lichess-bot-devs/lichess-bot),
the standard program that connects a UCI engine to Lichess's bot API. The
engine is used exactly as it is released. The engine repository holds only the
engine; everything that connects it to Lichess lives here.

| File | What it is |
| --- | --- |
| [`config.yml`](config.yml) | The lichess-bot configuration: challenges accepted, the opening book, pondering, the engine's options, the chat greetings |
| [`jaws.yaml`](jaws.yaml) | The deployed bot: the engine release it plays (the pin), its instance, token, records and logs |
| [`.github/workflows/release-to-lichess.yml`](.github/workflows/release-to-lichess.yml) | Deploys each release of this repository to the bot |
| [`run.sh`](run.sh) | Sets up lichess-bot and the engine under `.lichess-bot/` and plays |
| [`tools/check-config.py`](tools/check-config.py) | What `run.sh --check` runs: lichess-bot's own validation of the config, and the engine's UCI options |
| [`tests/`](tests) | The chat greetings fit Lichess's message limit (`npm test`) |

## One-time setup

1. **Create a bot account.** Register a new Lichess account for the bot. It
   must never have played a game; once upgraded to a bot it cannot play as a
   human again.
2. **Create a token.** Logged in as that account, go to
   https://lichess.org/account/oauth/token/create?scopes[]=bot:play&description=braveheart
   and copy the token (it starts with `lip_`). Keep it out of the repo.
3. **Upgrade the account to a bot** (once):

   ```sh
   LICHESS_TOKEN=lip_... ./run.sh --upgrade
   ```

## Playing

```sh
LICHESS_TOKEN=lip_... ./run.sh
```

This fetches lichess-bot at the pinned commit (it publishes no release tags),
installs it into a virtual environment, downloads the Braveheart release the
deployed bot plays (the pin) for this machine and verifies its checksum, writes
the config, and starts
accepting challenges. Leave it running; press Ctrl-C to stop (games in progress
are resigned by the server after `abort_time`).

- **Watch or play:** open `https://lichess.org/@/<bot-username>` and send a
  challenge (standard chess, bullet to rapid, casual or rated). Spectators see
  the games live on the bot's profile.
- **Let it find opponents:** set `matchmaking.allow_matchmaking: true` in
  `config.yml` and it challenges other bots within 300 rating points while idle.
- **Games are saved** as PGN under `.lichess-bot/game_records/`.

It needs Python 3.10 or newer, `git`, `curl`, `tar` and a network. Exactly one
process may hold a bot's token at a time, so don't run this with the token of
a bot that is already playing somewhere else.

### Which engine plays

Nothing is compiled here: the engine repository builds and publishes the
binaries, and `run.sh` takes one of them.

| Setting | Engine |
| --- | --- |
| none | The pinned release, `container-image.artifact.version` in `jaws.yaml` |
| `BRAVEHEART_VERSION=v0.55.0` | That release, for example one you are about to pin |
| `BRAVEHEART_VERSION=latest` | The newest release |
| `BRAVEHEART_BIN=/path/to/braveheart` | A binary you built, for example `../braveheart/target/release/braveheart` |

Releases exist for Apple silicon and Intel Macs and for x86-64 Linux. The Linux
binary is built for x86-64-v3, so it needs a CPU with AVX2. On any other
machine, build the engine and pass it as `BRAVEHEART_BIN`.

### Checking the setup

```sh
./run.sh --check
```

does everything a real run does except connect: it needs no token and never
contacts Lichess. It then has lichess-bot validate the config, and checks that
the engine answers `uci` and advertises every UCI option the config sets.
lichess-bot would otherwise only discover an unknown option at the start of a
game. CI runs it on every pull request.

Everything lives under `.lichess-bot/`, which git ignores. Delete it to start
again from nothing. Changing `LICHESS_BOT_REF` in `run.sh` moves the checkout
to the new commit on the next run.

## Chat

At its first move the bot greets both chat rooms with its name, the release
it is running and what it is, for example:

> Hi! I'm Braveheart v0.46.2: from-scratch Rust alpha-beta + NNUE, trained
> on billions of my own self-play positions, all labelled by me.

The goodbye carries the engine repository's link. The texts are the `greeting`
block of `config.yml`; `run.sh` fills `__VERSION__` from `braveheart --version`
when it writes the config, and the deployed bot's entrypoint
(jaws) does the same substitution. Lichess caps a chat
message at 140 characters and lichess-bot silently drops a longer one, so
`npm test` checks every greeting with a 9-character version filled in. Anyone
in the chat can also type `!name`, which lichess-bot answers with the engine's
UCI name, `Braveheart <version>`.

## Pondering

The bot thinks on its opponent's clock (`engine.ponder: true` in
`config.yml`). After each move lichess-bot tells the engine the reply it
expects (the second move of its principal variation, sent as
`bestmove … ponder …`) and has it search that position while the opponent
thinks. If the opponent plays it (`ponderhit`), the search carries on with
the clock running and has a head start of however long they took; if not,
it is stopped and a fresh search begins. The deployed bot's instance has one
core, so pondering uses time that was idle.

## Opening book

The bot plays its openings from Lichess's
[opening explorer](https://lichess.org/analysis#explorer) (masters games),
through lichess-bot's `online_moves.lichess_opening_explorer`, like most
Lichess bots: instant, sound moves in the opening and the whole clock saved
for the middlegame. It picks the best-scoring move among those masters played
at least 50 times, so its book lines are the same game to game; out of book,
or with under 20 seconds left, the engine searches as usual.

The book belongs to the bot, not the engine. `braveheart` has no book and no
book option: SPRTs, the Stockfish ladder and anyone running the binary see the
bare engine. So the bot's Lichess rating includes the book, and the ladder
numbers do not.

## The deployed bot

`run.sh` plays only while it is running. The deployed bot,
[jwallace145](https://lichess.org/@/jwallace145), plays from 08:00 to 20:00 UTC
every day (`lichess-bot.schedule`; outside those hours it is offline). It is one
`c8a.medium` EC2 instance run by
[jaws](https://github.com/Jaws-Platform/jaws)
from this repository's [`jaws.yaml`](jaws.yaml),
project `braveheart-bot` (the tool's
[docs/lichess-bot.md](https://github.com/Jaws-Platform/jaws/blob/main/docs/lichess-bot.md)).
This repository owns the deployment: the engine repository has no workflow,
file or role for the bot.

**What it plays** is the pin, `container-image.artifact.version`: one release of
the engine repository, its Linux binary checksum-verified and smoke-tested, never
rebuilt. A newer engine release changes nothing until the pin moves.

**How a change reaches it:**

1. Merge a pull request that changes the pin or `config.yml`.
2. Release Please updates its release pull request. Merging that is the
   deliberate act that deploys.
3. The release runs `Release to Lichess`. It builds an image from the pinned
   release and the release's `config.yml`, tags it `<pin>-<8 hex digits of the
   config's SHA-256>` (for example `v0.54.0-3f9c2a1b`), pushes it to ECR, and
   rolls the bot to it **after the game in progress ends**. If the new image does
   not come up, the previous one is restarted.

A release that changes neither the pin nor the config deploys nothing.

| What | Where |
| --- | --- |
| Engine release | `container-image.artifact.version` |
| lichess-bot settings | `config.yml`; the entrypoint fills `__VERSION__` with the pinned release |
| Hash size and move overhead | `engine.hash_mb` and `engine.move_overhead_ms` in the project file, which override `config.yml`'s `uci_options` |
| lichess-bot's own version | jaws's image, pinned to the same commit as `LICHESS_BOT_REF` in `run.sh` |
| Instance type, records, logs | The project file. Changing the instance replaces it, so that change also needs a Bot apply in jaws, run while the bot is idle |
| Token | SSM `/jaws/braveheart-bot/lichess-token` in jaws's production account, never in a file |

Every finished game is shipped to `s3://jaws-braveheart-bot-records/records/`,
filed under the image tag that played it (`engine=v0.54.0-3f9c2a1b`). Games
from before the bot moved to this repository are there too, under the same
keys: they were copied from jaws's old `jwall-engineering-braveheart-records`
bucket on 2026-11-21, before it was deleted.

To see what is running, from a shell with the production account's AWS
credentials, in a checkout of jaws:

```sh
JAWS_SKIP_ROLE_CHECK=1 uv run jaws --config config.yaml \
  bot status   # run next to this repository's jaws.yaml
```

## Rating

Lichess gives the bot a rating after enough games: the real-world number the
engine's roadmap asks for, next to the Stockfish-ladder estimate each engine
release records. The two are not comparable: the bot's rating includes its
book and its hardware.

## Contributing

Changes go through pull requests with one-line Conventional Commits; see
[CONTRIBUTING.md](CONTRIBUTING.md). The rules for coding agents are in
[AGENTS.md](AGENTS.md). Licensed under the [MIT License](LICENSE).
