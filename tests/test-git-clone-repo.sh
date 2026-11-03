#!/bin/bash
# Test git-clone-repo offline: an https URL is rewritten to a local repository
# with url.<base>.insteadOf, so the path is derived from the URL as usual.
set -euo pipefail

TOOL=$(readlink -f "$(dirname "$0")/../git-clone-repo")
T=$(mktemp -d)
trap 'status=$?; if [ $status -eq 0 ]; then rm -rf "$T"; else echo "left in $T"; fi' EXIT
export GIT_CONFIG_GLOBAL=$T/gitconfig GIT_CONFIG_NOSYSTEM=1
git config --global user.name test
git config --global user.email test@example.com
git config --global url."$T/up/".insteadOf https://example.com/

fail() { echo "FAIL: $*" >&2; exit 1; }
cfg() { git -C "$1" config --get "$2" || true; }

git init -q "$T/up/me/demo"
git -C "$T/up/me/demo" commit -q --allow-empty -m one
ln -s demo "$T/up/me/demo.git"   # the same upstream with and without .git

# --class: $WS_SRC_ROOT/<class>/<host>/<path> (default /data/src), configured as a mirror.
"$TOOL" --help | tr -s ' \n' ' ' | grep -q 'default /data/src' || fail "default root is not /data/src"
WS_SRC_ROOT=$T/data/src "$TOOL" --class oss https://example.com/me/demo.git >/dev/null 2>&1
m=$T/data/src/oss/example.com/me/demo
[ -d "$m/.git" ] || fail "--class did not clone into $m"
[ "$(cfg "$m" extensions.preciousObjects)" = true ] || fail "mirror is not precious"
[ "$(cfg "$m" core.repositoryformatversion)" = 1 ] || fail "repository format not 1"
[ "$(cfg "$m" fetch.unpackLimit)" = 1 ] && [ "$(cfg "$m" gc.auto)" = 0 ] || fail "fetch/gc settings"
git -C "$m" gc 2>/dev/null; git -C "$m" prune 2>/dev/null && fail "prune ran in a precious mirror"

# --class on an existing clone converts it into a mirror.
SRC_REPO_PATH=$T/plain "$TOOL" https://example.com/me/demo >/dev/null 2>&1
p=$T/plain/example.com/me/demo
[ -z "$(cfg "$p" extensions.preciousObjects)" ] || fail "a plain clone was made a mirror"
"$TOOL" --root-dir "$T/plain" --class work https://example.com/me/demo >/dev/null 2>&1
[ "$(cfg "$p" extensions.preciousObjects)" = true ] || fail "existing clone not converted"

# --root-dir wins over --class; nothing at all is an error.
WS_SRC_ROOT=$T/data/src "$TOOL" --root-dir "$T/explicit" --class priv https://example.com/me/demo >/dev/null 2>&1
[ -d "$T/explicit/example.com/me/demo" ] && [ ! -e "$T/data/src/priv" ] || fail "--root-dir precedence"
if env -u SRC_REPO_PATH "$TOOL" https://example.com/me/demo >/dev/null 2>&1; then fail "ran without a root"; fi
if "$TOOL" --class bogus https://example.com/me/demo >/dev/null 2>&1; then fail "accepted class bogus"; fi

echo "PASS: git-clone-repo --class"
