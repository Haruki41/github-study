#!/usr/bin/env bash
# PreToolUse フック：開発サーバーを「別ポート」で起動しようとするコマンドをブロックする。
# 決められたポート：API 8080、画面 5173（CLAUDE.md の「開発サーバーのポート」）。
# 標準入力にツール呼び出しの JSON が渡される。exit 2 でブロック、exit 0 で許可。

input=$(cat)

# サーバーを起動するコマンドか（gradle の bootRun、java -jar、vite、npm run dev など）
starts_server='(bootRun|spring-boot:run|java[^|;&]*[[:space:]]-jar|vite|npm(\.cmd)?[[:space:]]+(run[[:space:]]+)?(dev|start)|node[^|;&]*server)'

# ポートを指定している記述（--port、server.port、PORT=、-p 3000 など）
port_option='(server\.port|SERVER_PORT|--port([[:space:]=\\"]|$)|(^|[^A-Za-z_])PORT=|\$env:PORT|[[:space:]]-p[[:space:]]+[0-9]{3,5}|localhost:(808[1-9]|80[1-7][0-9]|517[4-9]|518[0-9]))'

if printf '%s' "$input" | grep -Eqi "$starts_server" \
  && printf '%s' "$input" | grep -Eqi "$port_option"; then
  echo "ブロック: 開発サーバーを別ポートで起動することは禁止（API は 8080、画面は 5173 のみ）。ポートが競合している場合は、scripts/dev-servers.ps1 で持ち主を停止して、決められたポートで起動すること（スキル dev-servers）。" >&2
  exit 2
fi

exit 0
