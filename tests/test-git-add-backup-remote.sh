#!/bin/bash
# Test the backup URL git-add-backup-remote derives (its --help prints it, no
# ssh involved): the repository's path below SRC_REPO_PATH, or below /data
# when that is unset, for a working clone, a bare clone and a linked worktree.
set -euo pipefail

TOOL=$(readlink -f "$(dirname "$0")/../git-add-backup-remote")
T=$(mktemp -d)
trap 'status=$?; if [ $status -eq 0 ]; then rm -rf "$T"; else echo "left in $T"; fi' EXIT
export GIT_CONFIG_GLOBAL=$T/gitconfig GIT_CONFIG_NOSYSTEM=1
export GIT_BACKUP_REMOTE_HOST=bk GIT_BACKUP_REMOTE_ROOT=GIT_BACKUP
git config --global user.name test
git config --global user.email test@example.com

fail() { echo "FAIL: $*" >&2; exit 1; }
url() { (cd "$1" && "$TOOL" --help 2>&1 || true) | sed -n 's/.*default GIT_BACKUP_URL is //p'; }

git init -q "$T/src/oss/example.com/demo"
git -C "$T/src/oss/example.com/demo" commit -q --allow-empty -m one
git clone -q --bare "$T/src/oss/example.com/demo" "$T/ws/w/src/demo.git"
git -C "$T/ws/w/src/demo.git" worktree add -q "$T/ws/w/gwt/001-demo" -b 001/x

export SRC_REPO_PATH=$T
[ "$(url "$T/src/oss/example.com/demo")" = bk:GIT_BACKUP/src/oss/example.com/demo.git ] ||
    fail "working clone: $(url "$T/src/oss/example.com/demo")"
[ "$(url "$T/ws/w/src/demo.git")" = bk:GIT_BACKUP/ws/w/src/demo.git ] ||
    fail "bare clone: $(url "$T/ws/w/src/demo.git")"
[ "$(url "$T/ws/w/gwt/001-demo")" = bk:GIT_BACKUP/ws/w/src/demo.git ] ||
    fail "worktree: $(url "$T/ws/w/gwt/001-demo")"
unset SRC_REPO_PATH
(cd "$T/ws/w/src/demo.git" && { "$TOOL" --help 2>&1 || true; } | grep -q 'not below /data') ||
    fail "no SRC_REPO_PATH: no refusal for a repository outside /data"

echo "PASS: git-add-backup-remote URL from SRC_REPO_PATH or /data"
