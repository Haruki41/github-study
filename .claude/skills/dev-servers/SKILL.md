---
name: dev-servers
description: バックエンド（API）とフロントエンドの開発サーバーを、必ず決められたポート（8080・5173）で起動・停止・確認する。動作確認のためにサーバーを起動するとき、ポートが競合したとき、サーバーを止めるときに使う。
---

# 開発サーバーの起動・停止（ポート厳守）

## 決められたポート
| サーバー | ポート | 設定の場所 |
|---|---|---|
| バックエンド（Spring Boot） | **8080** | `backend/src/main/resources/application.properties` の `server.port` |
| フロントエンド（Vite） | **5173** | `frontend/vite.config.ts` の `server.port`（`strictPort: true`） |

画面は `/api` を 8080 へ転送する設計のため、別ポートでは動かない。**一時的にでも別ポートで起動しない。**

## 手順
起動前に、DB（Docker の `taskboard-db`、5432 番）が動いていること。動いていなければ `docker compose up -d --wait`。

```
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev-servers.ps1 -Action start
```
- `-Action start`：競合しているポートの持ち主を停止して、8080・5173 で起動し、応答を確認する。
- `-Action stop`：8080・5173 のサーバーを停止する。確認が終わったら、起動した側が停止する。
- `-Action status`：両ポートの使用状況を表示する。
- `-Target backend` / `-Target frontend`：片方だけを対象にする。

## 守ること
1. ポートが使用中でも、別ポートを指定して逃げない（`--port`、`server.port`、`PORT=` などは使わない。hooks がブロックする）。
2. 競合したら、必ずポートの持ち主を停止してから、決められたポートで起動する（スクリプトが行う）。
3. **何を停止したかを、ユーザーに必ず報告する**（スクリプトの `[停止]` の行をそのまま伝える）。
4. 次の持ち主は、スクリプトが自動停止せずにエラーで止まる。**回避せず、ユーザーに報告して指示を仰ぐ。**
   - Windows のシステム（PID 4 以下）
   - Docker・WSL 関連のプロセス（止めると Docker 全体が落ちる）
5. 起動に失敗したら、スクリプトが表示するログを読んで原因を伝える。別ポートでの起動で済ませない。
6. DB のポート（5432）の競合は、このスキルの対象外。データに影響し得るため、自動では停止せず、ユーザーに確認する。

## 動作確認の方法
- API：`http://localhost:8080/hello`、`http://localhost:8080/api/board`
- 画面（プロキシ経由の API 含む）：`http://localhost:5173/`、`http://localhost:5173/api/board`
- 画面の描画結果：`msedge.exe --headless=new --virtual-time-budget=8000 --dump-dom http://localhost:5173/`
- 別ポートで動いていないことの確認：`-Action status`、または 8081・5174 などが空きであること。
