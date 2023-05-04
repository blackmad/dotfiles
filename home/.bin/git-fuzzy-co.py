#!/usr/bin/env python3
"""
git fuzzy-checkout

Same as `git checkout branch`, but with fuzzy matching if checkout fails.
Turns `git checkout barnch` into `git checkout branch`,
assuming `branch` is a branch.
"""

import difflib
import sys
import os
import subprocess

from subprocess import check_output, check_call, CalledProcessError


def git_branches():
    """construct list of git branches"""
    text = check_output(["git", "branch"]).decode("utf8", "replace")
    return [line.lstrip("*").strip() for line in text.splitlines()]


def proximity(a, b):
    """measure proximity of two strings"""
    return difflib.SequenceMatcher(None, a, b).ratio()


def fuzzy_checkout(branch):
    """wrapper for git-checkout that does fuzzy-matching

    Helps with typos, etc. by automatically checking out the closest match
    if the initial checkout call fails.
    """
    try:
        check_call(["git", "checkout", branch])
    except CalledProcessError:
        branches = git_branches()
        branches = sorted(branches, key=lambda b: proximity(branch.upper(), b.upper()))
        best = branches[-1]
        if proximity(best, branch) > 0.6:
            print(
                "Best match for '%s': \033[92m'%s'\033[0m (%.1f%%)"
                % (branch, best, 100 * proximity(best, branch))
            )
            try:
                check_call(["git", "checkout", best])
            except CalledProcessError:
                return 1
        else:
            matches = list(filter(lambda x: branch.upper() in x.upper(), branches))
            if len(matches) == 1:
                print(
                    "Best match for '%s': \033[92m'%s'\033[0m (by substring)"
                    % (branch, matches[0])
                )
                try:
                    check_call(["git", "checkout", matches[0]])
                except CalledProcessError:
                    return 1
            elif len(matches) > 1:
                #                print("Multiple matches found:")
                #                print("\033[92m" + "\n".join(matches) + "\033[0m")

                command = f'git checkout "$($(whence -p git) branch | cut -c 3- | fzf --query="{branch}" --preview="git log {{}} --")"'
                subprocess.call(["zsh", "-c", command])

    return 0


if __name__ == "__main__":
    sys.exit(fuzzy_checkout(sys.argv[1]))
