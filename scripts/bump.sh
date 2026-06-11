#!/usr/bin/env bash
# Bump a formula in this tap to a new upstream version.
#
# Usage:
#   scripts/bump.sh <formula> <version>
#
# Examples:
#   scripts/bump.sh tess 0.9.1
#   scripts/bump.sh recon 0.78.0            # also bump recon-impersonate to keep them aligned
#   scripts/bump.sh recon-impersonate 0.78.0
#
# Prerequisites:
#   - The upstream tag v<version> must exist and be reachable anonymously.
#   - The repo `codedeviate/<repo>` must be public.

set -euo pipefail

FORMULA="${1:?usage: $0 <formula> <version>}"
VERSION="${2:?usage: $0 <formula> <version>}"

# Map formula name → upstream repo slug. recon-impersonate ships from the
# same repo as recon (different cargo features), so they share an upstream.
case "$FORMULA" in
    recon|recon-impersonate) REPO="recon" ;;
    batty)                   REPO="batty" ;;
    tess)                    REPO="tess" ;;
    sqlt)                    REPO="sqlt" ;;
    sercon)                  REPO="sercon" ;;
    webrunner)               REPO="webrunner" ;;
    witch)                   REPO="witch" ;;
    *)
        echo "error: unknown formula '$FORMULA'" >&2
        echo "known formulae: recon, recon-impersonate, batty, tess, sqlt, sercon, webrunner, witch" >&2
        exit 2
        ;;
esac

URL="https://github.com/codedeviate/${REPO}/archive/refs/tags/v${VERSION}.tar.gz"

http_code=$(curl -sIL -o /dev/null -w '%{http_code}' "$URL")
if [[ "$http_code" != "200" ]]; then
    echo "error: $URL returned HTTP $http_code" >&2
    echo "       (is the tag pushed and the repo public?)" >&2
    exit 1
fi

SHA=$(curl -sL "$URL" | shasum -a 256 | awk '{print $1}')
echo "formula:  $FORMULA"
echo "repo:     codedeviate/$REPO"
echo "version:  $VERSION"
echo "url:      $URL"
echo "sha256:   $SHA"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/Formula/${FORMULA}.rb"

if [[ ! -f "$FILE" ]]; then
    echo "error: $FILE not found" >&2
    exit 1
fi

sed -i.bak \
    -e "s|/${REPO}/archive/refs/tags/v[0-9][0-9.]*\.tar\.gz|/${REPO}/archive/refs/tags/v${VERSION}.tar.gz|" \
    -e "s|sha256 \"[^\"]*\"|sha256 \"${SHA}\"|" \
    "$FILE"
rm -f "${FILE}.bak"

echo
echo "Updated $FILE. Diff:"
git --no-pager -C "$ROOT" diff "Formula/${FORMULA}.rb" || true
