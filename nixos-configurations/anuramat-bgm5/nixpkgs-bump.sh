#!/usr/bin/env bash
# Bumps the `nixpkgs` input of the flake repo at $1, builds every non-deprecated
# host, points the `nixpkgs-bump` branch at the bump commit, and fast-forwards
# the checked out branch to it. All work happens in a throwaway worktree, so
# concurrent edits in the checkout are safe: if the branch moved or flake.lock
# is dirty, the fast-forward is skipped and the bump waits on `nixpkgs-bump`.
# Build results are kept as GC roots in $2.
set -euo pipefail

repo=$1
roots=$2
log=$(mktemp)
wt=$(mktemp -d)
trap 'git -C "$repo" worktree remove --force "$wt"; rm -f "$log"' EXIT

notify() {
	{
		echo "nixpkgs-bump: $1"
		if [ "${2-}" = log ]; then
			tail -n 20 "$log"
		fi
	} | tgfy
}

base=$(git -C "$repo" rev-parse HEAD)
git -C "$repo" worktree add --quiet --detach "$wt" "$base"
cd "$wt"

nix flake update nixpkgs 2>"$log" || {
	notify 'update failed' log
	exit 1
}
if git diff --quiet flake.lock; then
	exit 0
fi

nix flake check 2>"$log" || {
	notify 'flake check failed' log
	exit 1
}
mapfile -t hosts < <(nix eval --json '.#hosts' | jq -r 'to_entries[] | select(.value.deprecated | not) | .key')
for host in "${hosts[@]}"; do
	nix build --out-link "$roots/$host" ".#nixosConfigurations.$host.config.system.build.toplevel" 2>"$log" || {
		notify "build of $host failed" log
		exit 1
	}
done

# the pre-commit config is an untracked symlink, absent in the worktree
git commit --quiet --no-verify -m 'flake: bump nixpkgs (auto)' flake.lock
# always the latest built bump: merged into the branch, or waiting to be
git branch --force nixpkgs-bump

# --ff-only refuses if the branch moved since $base or flake.lock is dirty
if git -C "$repo" merge --quiet --ff-only nixpkgs-bump 2>"$log"; then
	notify "merged $(git -C "$repo" rev-parse --short HEAD); built all hosts"
else
	notify "built all hosts, but couldn't fast-forward; merge the nixpkgs-bump branch" log
fi
