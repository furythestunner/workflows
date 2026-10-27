#!/bin/bash
# Tests for secret-guard.mjs: each case is a scratch repo with changes and a command, and whether the guard must block
# it. The fake secrets are put together at run time, so this file holds none.
# Usage: bash .claude/hooks/secret-guard.test.sh   (exit 0 = all pass)
hook=$(cd "$(dirname "$0")" && pwd)/secret-guard.mjs
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail=0
gh_token="gh""p_$(printf 'a%.0s' {1..36})"
pkey="-----BEGIN RSA PRIVATE"" KEY-----"
n=0
t() { # <block|allow> <name> <setup commands> <tool> <tool_input JSON>
  local r="$tmp/r$((n++))" out got
  git init -q "$r"; echo x >"$r/a.txt"; git -C "$r" add -A; git -C "$r" -c user.name=t -c user.email=t@t commit -qm init
  (cd "$r" && eval "$3")
  out=$(node -e 'process.stdout.write(JSON.stringify({tool_name: process.argv[1], tool_input: JSON.parse(process.argv[2])}))' "$4" "$5" |
    CLAUDE_PROJECT_DIR=$r node "$hook")
  case $out in *'"deny"'*) got=block ;; *) got=allow ;; esac
  if [ "$got" = "$1" ]; then echo "ok    $1: $2"; else echo "FAIL  expected $1, got $got: $2 ($out)"; fail=1; fi
  case $out in *"$gh_token"*) echo "FAIL  $2: the reason shows the secret"; fail=1 ;; esac
}
t block 'staged token' "echo 'key=$gh_token' >c.txt; git add c.txt" Bash '{"command":"git commit -m x"}'
t block 'token, add and commit in one' "echo 'key=$gh_token' >c.txt" Bash '{"command":"git add -A && git commit -m x"}'
t block 'token, commit -am' "echo 'key=$gh_token' >>a.txt" Bash '{"command":"git commit -am x"}'
t block 'staged .env' "echo A=1 >.env; git add .env" Bash '{"command":"git commit -m x"}'
t block 'private key' "echo '$pkey' >k.txt; git add k.txt" Bash '{"command":"git commit -m x"}'
t allow 'plain change' "echo y >>a.txt; git add a.txt" Bash '{"command":"git commit -m x"}'
t allow '.env.example' "echo A= >.env.example; git add .env.example" Bash '{"command":"git commit -m x"}'
t allow 'token not staged, plain commit' "echo 'key=$gh_token' >c.txt" Bash '{"command":"git commit -m x"}'
t allow 'not a commit' "echo 'key=$gh_token' >c.txt; git add c.txt" Bash '{"command":"git status"}'
t block 'token in an accented file name' "echo 'key=$gh_token' >jelszó.txt; git add jelszó.txt" Bash '{"command":"git commit -m x"}'
t allow 'removing a committed .env' "echo A=1 >.env; git add .env; git -c user.name=t -c user.email=t@t commit -qm e; git rm -q --cached .env" Bash '{"command":"git commit -m \"remove secret\""}'
t allow 'loose .env not being added' "echo A=1 >.env; echo y >>a.txt" Bash '{"command":"git add a.txt && git commit -m x"}'
t block 'add of a folder with a key' "mkdir k; echo '$pkey' >k/id.txt" Bash '{"command":"git add k && git commit -m x"}'
t block 'new branch push, no upstream' "git update-ref refs/remotes/origin/main HEAD; git checkout -q -b topic; echo 'key=$gh_token' >c.txt; git add c.txt; git -c user.name=t -c user.email=t@t commit -qm c" Bash '{"command":"git push -u origin topic"}'
t block 'commit in another repo (cd)' "git init -q sub; echo 'key=$gh_token' >sub/c.txt; git -C sub add c.txt" Bash '{"command":"cd sub && git commit -m x"}'
t block 'commit in another repo (-C)' "git init -q sub; echo 'key=$gh_token' >sub/c.txt; git -C sub add c.txt" Bash '{"command":"git -C sub commit -m x"}'
t block 'GitHub tool: token' '' mcp__github__create_or_update_file "{\"path\":\"c.txt\",\"content\":\"$gh_token\"}"
t block 'GitHub tool: .pem' '' mcp__github__push_files '{"files":[{"path":"certs/a.pem","content":"x"}]}'
t allow 'GitHub tool: plain' '' mcp__github__push_files '{"files":[{"path":"a.md","content":"hello"}]}'
out=$(printf '{bad' | node "$hook" 2>&1); code=$?
if [ $code -eq 0 ] && [ -z "$out" ]; then echo "ok    bad input: silent, exit 0"; else echo "FAIL  bad input: exit $code: $out"; fail=1; fi
exit $fail
