#!/usr/bin/env bash
# Run Braveheart as a Lichess bot.
#
#   LICHESS_TOKEN=lip_... ./run.sh            # fetch the engine and lichess-bot, play
#   LICHESS_TOKEN=lip_... ./run.sh --upgrade  # one-time: turn a fresh account into a bot
#   ./run.sh --check                          # set everything up and validate it; never contacts Lichess
#
# The engine is the release the deployed bot plays (container-image.artifact.version
# in jwall-engineering-sites.yaml), for this machine, verified against its
# published checksum. To play something else:
#
#   BRAVEHEART_VERSION=v0.55.0 ./run.sh                          # another release
#   BRAVEHEART_VERSION=latest ./run.sh                           # the newest release
#   BRAVEHEART_BIN=../braveheart/target/release/braveheart ./run.sh  # a local build
#
# Needs: a Lichess account that has never played a game, with an API token
# that has the bot:play scope; Python 3.10+; git, curl and tar. Everything is
# set up under .lichess-bot/ (ignored by git); delete that directory to start
# again from nothing.
set -euo pipefail

# lichess-bot publishes no tags (its last, 1.1.3, is from 2018), so pin a
# master commit instead. Bump deliberately and re-check config.yml.default.
LICHESS_BOT_REF="${LICHESS_BOT_REF:-afa430da25cb6d506c878d3ca2fa155be8da625d}" # 2026-10-27
ENGINE_REPO="https://github.com/Braveheart-Chess/braveheart"

here="$(cd "$(dirname "$0")" && pwd)"
work="$here/.lichess-bot"
engine="$work/engines/braveheart"

die() {
  echo "run.sh: $*" >&2
  exit 1
}

mode="${1:-}"
case "$mode" in
  "" | --upgrade | --check) ;;
  *) die "unknown argument '$mode' (expected --upgrade, --check or nothing)" ;;
esac

if [ "$mode" = "--check" ]; then
  # Never sent anywhere: --check stops before lichess-bot connects.
  LICHESS_TOKEN="check-only-not-a-token"
fi
: "${LICHESS_TOKEN:?set LICHESS_TOKEN to a Lichess API token with the bot:play scope}"

# lichess-bot, at the pinned commit. A checkout left at another commit (the
# pin was bumped since) is moved to it, and its requirements reinstalled.
if [ "$(git -C "$work" rev-parse --verify --quiet HEAD 2>/dev/null || true)" != "$LICHESS_BOT_REF" ]; then
  echo "==> fetching lichess-bot at $LICHESS_BOT_REF"
  [ -d "$work/.git" ] || git init --quiet "$work"
  git -C "$work" fetch --quiet --depth 1 https://github.com/lichess-bot-devs/lichess-bot.git "$LICHESS_BOT_REF"
  git -C "$work" -c advice.detachedHead=false checkout --quiet FETCH_HEAD
  rm -f "$work/venv/.installed"
fi

if [ ! -f "$work/venv/.installed" ]; then
  echo "==> creating the Python environment"
  python3 -m venv "$work/venv"
  "$work/venv/bin/pip" install --quiet --upgrade pip
  "$work/venv/bin/pip" install --quiet -r "$work/requirements.txt"
  touch "$work/venv/.installed"
fi

# The engine: a local build when BRAVEHEART_BIN names one, otherwise a
# release binary. The engine repository builds and publishes them; nothing is
# compiled here.
mkdir -p "$work/engines"
if [ -n "${BRAVEHEART_BIN:-}" ]; then
  [ -x "$BRAVEHEART_BIN" ] || die "BRAVEHEART_BIN='$BRAVEHEART_BIN' is not an executable file"
  echo "==> using the engine at $BRAVEHEART_BIN"
  cp "$BRAVEHEART_BIN" "$engine"
  rm -f "$work/engines/.release"
else
  case "$(uname -s)-$(uname -m)" in
    Darwin-arm64) target="aarch64-apple-darwin" ;;
    Darwin-x86_64) target="x86_64-apple-darwin" ;;
    Linux-x86_64) target="x86_64-unknown-linux-gnu" ;;
    *) die "Braveheart publishes no release binary for $(uname -s) $(uname -m); build the engine and set BRAVEHEART_BIN" ;;
  esac

  tag="${BRAVEHEART_VERSION:-}"
  if [ -z "$tag" ]; then
    # The pin: the only `version: vX.Y.Z` in the project file.
    tag="$(sed -n 's/^ *version: *\(v[0-9][0-9.]*\).*$/\1/p' "$here/jwall-engineering-sites.yaml")"
    [ -n "$tag" ] || die "jwall-engineering-sites.yaml pins no engine release (container-image.artifact.version)"
  elif [ "$tag" = "latest" ]; then
    # releases/latest redirects to releases/tag/<tag>: no API call, so no rate limit.
    latest="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "$ENGINE_REPO/releases/latest")"
    tag="${latest##*/}"
  fi
  [[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "'$tag' is not a release tag like v0.54.0"

  release="$tag-$target"
  if [ ! -x "$engine" ] || [ "$(cat "$work/engines/.release" 2>/dev/null || true)" != "$release" ]; then
    echo "==> downloading braveheart $tag ($target)"
    asset="braveheart-$release.tar.gz"
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    curl -fsSL -o "$tmp/$asset" "$ENGINE_REPO/releases/download/$tag/$asset" \
      || die "could not download $asset from the $tag release"
    curl -fsSL -o "$tmp/$asset.sha256" "$ENGINE_REPO/releases/download/$tag/$asset.sha256" \
      || die "could not download the checksum of $asset"
    if command -v sha256sum >/dev/null 2>&1; then
      (cd "$tmp" && sha256sum --check --quiet "$asset.sha256") || die "checksum mismatch for $asset"
    else
      (cd "$tmp" && shasum -a 256 --check --quiet "$asset.sha256") || die "checksum mismatch for $asset"
    fi
    tar -xzf "$tmp/$asset" -C "$tmp"
    cp "$tmp/braveheart-$release/braveheart" "$engine"
    chmod +x "$engine"
    echo "$release" > "$work/engines/.release"
  fi
fi

# The token, and the engine's version for the chat greeting (`braveheart
# --version` prints `braveheart 0.46.2`). The rendered config holds the
# token, so only this user may read it.
version="v$("$engine" --version | awk '{print $2}')"
(
  umask 077
  sed -e "s|LICHESS_TOKEN_PLACEHOLDER|$LICHESS_TOKEN|" -e "s|__VERSION__|$version|g" "$here/config.yml" > "$work/config.yml"
)

cd "$work"
case "$mode" in
  --check)
    echo "==> checking the config against lichess-bot and braveheart $version"
    exec venv/bin/python "$here/tools/check-config.py"
    ;;
  --upgrade)
    echo "==> upgrading the account to a bot (irreversible for that account)"
    exec venv/bin/python lichess-bot.py -u
    ;;
esac
echo "==> playing braveheart $version; watch at https://lichess.org/@/<your-bot-username>"
exec venv/bin/python lichess-bot.py -v
