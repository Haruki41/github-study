# CLAUDE.md（Claude Code 向けの必須ルール）

このリポジトリ（`Haruki41/github-study`）での開発は、下記の手順を**例外なく**守る。
ユーザーが「コミットして push して」と頼んだ場合も、この手順に従う（`main` への直接 push はしない）。

## 1. 作業の流れ（必ずこの順）
1. **Issue を作る（または既存 Issue を確認する）**。Issue なしで作業を始めない。
2. **ブランチを切る**。必ず最新の `main` から作成する。
3. 変更を**ブランチ上で**コミットする。
4. **ブランチを push し、PR を作る**。PR 本文に `Closes #番号` を書く。
5. **マージはユーザーが確認してから**。Claude が勝手にマージしない。
6. マージ後は `main` を最新にし、作業ブランチを削除する。

## 2. 禁止事項
- `main` への直接コミット・直接 push・強制 push（`--force`）。
- Issue 番号のないブランチを作ること。
- ユーザーの許可なく PR をマージすること、ブランチ保護や Ruleset を変更・解除すること。
- フック（`--no-verify`）や署名の回避。

### 機械的なガード（hooks）
`.claude/settings.json` と `.claude/hooks/guard-main.sh` が、上の禁止事項を Claude Code のツール実行前に検査する。
- ブロック：`main` への push、`main` 上での commit / push、force push、`--no-verify` など。
- 実行前に確認：Ruleset・ブランチ保護を変更する `gh api`（POST / PUT / PATCH / DELETE）。
- コミットメッセージにコマンド風の文字列（`--force` など）を含めると誤検知することがある。長いメッセージは `git commit -F ファイル` で渡す。
- hooks はセッション開始時に読み込まれる。変更後は Claude Code を再起動する。
- ブロックされたら回避せず、手順（Issue、ブランチ、PR）を守り直す。

## 3. ブランチ名
`<種類>/<Issue番号>-<英小文字とハイフンの短い説明>`

| 種類 | 用途 | 例 |
|---|---|---|
| `feature` | 機能の追加 | `feature/12-add-card-api` |
| `fix` | 不具合の修正 | `fix/15-card-position-bug` |
| `docs` | ドキュメントのみ | `docs/18-update-readme` |
| `chore` | 設定・環境・雑務 | `chore/1-dev-workflow-rules` |

## 4. Issue
- テンプレート（`.github/ISSUE_TEMPLATE/`）に沿って、「背景」「やること」「完了条件」を書く。
- タイトルは「何をするか」が分かる日本語にする。
- 1 Issue = 1 目的。大きい場合は分割する。

## 5. コミットメッセージ
- 日本語で、1行目に要約（何をしたか）を書く。必要なら空行のあとに理由・補足を書く。
- 1つのコミットには1つの目的だけを含める。
- シークレット（パスワード・トークン・`.env`）をコミットしない。

## 6. PR
- タイトルは Issue と同じ粒度で、何をしたか分かるようにする。
- 本文は PR テンプレートに沿い、`Closes #番号` を必ず入れる。
- 確認方法（動かした手順・結果）を書く。確認していないことは「未確認」と書く。

## 7. 開発環境のメモ
- DB は Docker の PostgreSQL（`docker compose up -d`、`github-study` フォルダで実行）。
- バックエンドは `backend/` で `./gradlew bootRun`（Spring Boot、Java 17）。
- `docker` / `gh` が PATH にない場合は、`C:\Program Files\Docker\Docker\resources\bin\docker.exe`、`C:\Program Files\GitHub CLI\gh.exe` を直接指定する。
