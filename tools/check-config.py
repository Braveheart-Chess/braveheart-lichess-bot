"""Check the rendered config against the pinned lichess-bot and the engine.

Run by `run.sh --check`, with lichess-bot's Python environment, from the
lichess-bot checkout (so `lib` is lichess-bot's own package and the config's
relative paths resolve). It contacts nothing on Lichess. It fails when:

- lichess-bot rejects the config: a syntax error, a missing or mistyped
  section, an invalid choice, an engine that is absent or not executable;
- run.sh left a `__VERSION__` token in the config;
- the engine does not answer `uci` with `uciok`;
- the config sets a UCI option the engine does not advertise. lichess-bot
  would only find that out at the start of a game, and abandon it.
"""

import os
import re
import subprocess
import sys

sys.path.insert(0, os.getcwd())

from lib.config import load_config  # noqa: E402  (lichess-bot's, from the working directory)

CONFIG_FILE = "config.yml"


def main() -> int:
    problems = []

    config = load_config(CONFIG_FILE)  # raises, with lichess-bot's own message, when invalid

    with open(CONFIG_FILE) as stream:
        if "__VERSION__" in stream.read():
            problems.append("the config still contains __VERSION__; run.sh should have filled it in")

    engine = os.path.join(config.engine.dir, config.engine.name)
    answer = subprocess.run(
        [engine], input="uci\nquit\n", capture_output=True, text=True, timeout=30, check=False
    ).stdout
    if "uciok" not in answer.split():
        problems.append(f"{engine} did not answer `uci` with `uciok`")

    # UCI option names are case-insensitive.
    advertised = {m.group(1).lower() for m in re.finditer(r"^option name (.+?) type ", answer, re.MULTILINE)}
    wanted = config.engine.lookup("uci_options") or {}
    for name, _ in wanted.items():
        if name.lower() not in advertised:
            problems.append(f"engine.uci_options sets `{name}`, which the engine does not advertise")

    for problem in problems:
        print(f"check-config: {problem}", file=sys.stderr)
    if problems:
        return 1

    name = re.search(r"^id name (.+)$", answer, re.MULTILINE)
    print(
        f"ok: lichess-bot accepts the config; {name.group(1) if name else engine} "
        f"answers uci and advertises {', '.join(wanted.keys()) or 'no configured options'}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
