#!/usr/bin/env bash
# PreToolUse フック：main への直接変更など、CLAUDE.md で禁止している操作をブロックする。
# 標準入力にツール呼び出しの JSON が渡される。exit 2 でブロック、exit 0 で許可。
# ユーザー自身がターミナルで行う操作は対象外（Claude Code のツール経由のみ）。

input=$(cat)
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

deny() {
  echo "ブロック: $1（CLAUDE.md のルール）" >&2
  exit 2
}

ask() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$1"
  exit 0
}

# git push の判定
if printf '%s' "$input" | grep -Eq 'git[^|;&]*[[:space:]]push([[:space:]]|\\|")'; then
  # force push
  if printf '%s' "$input" | grep -Eq '[[:space:]](--force|--force-with-lease|-f)([[:space:]=\\"]|$)'; then
    deny "force push は禁止"
  fi
  # main / master を明示した push
  if printf '%s' "$input" | grep -Eq '([[:space:]:/])(main|master)([[:space:]\\"]|$)'; then
    deny "main への push は禁止。作業ブランチを push して PR を作ること"
  fi
  # main 上での push（宛先省略を含む）
  if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
    deny "main ブランチ上では push できない。ブランチを切ってから行うこと"
  fi
fi

# main 上でのコミット
if printf '%s' "$input" | grep -Eq 'git[^|;&]*[[:space:]]commit([[:space:]]|\\|")'; then
  if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
    deny "main ブランチ上ではコミットできない。Issue を作ってブランチを切ること"
  fi
fi

# フック・署名の回避
if printf '%s' "$input" | grep -Eq 'git[^|;&]*(--no-verify|--no-gpg-sign|gpgsign=false)'; then
  deny "フック・署名の回避は禁止"
fi

# Ruleset・ブランチ保護の変更は実行前にユーザーへ確認
if printf '%s' "$input" | grep -Eq 'gh[^|;&]*api' \
  && printf '%s' "$input" | grep -Eq '(rulesets|/protection)' \
  && printf '%s' "$input" | grep -Eq '(-X|--method)[[:space:]]*(POST|PUT|PATCH|DELETE)'; then
  ask "Ruleset・ブランチ保護を変更しようとしている。実行してよいか確認する"
fi

exit 0
