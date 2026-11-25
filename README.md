# Trello風タスク管理アプリ

タスクをカードとして「未着手」「進行中」「完了」の3列に並べて管理する、個人用の簡易アプリです。
プログラミング学習（React、Spring Boot、PostgreSQL、Docker、GitHub での開発手順）を兼ねています。

画面（React）→ API（Spring Boot）→ データベース（PostgreSQL）の3つで動き、すべて自分のPC（localhost）の中で完結します。

## 現在の状況（2026-11-25 時点）
| 機能 | 状態 |
|---|---|
| F-01 ボード表示 | 実装済 |
| F-09 カード検索 | 次に作る（API は実装済、画面が未実装） |
| F-02 カード追加、F-03 カード移動、F-04 カード削除 | 未実装 |

詳しい進捗は [要件定義書](./要件定義書.md) の「6. 現状と課題」を参照してください。

| 知りたいこと | 見る場所 |
|---|---|
| 完成条件ごとの確認状況 | [08_受け入れ基準](./docs/08_受け入れ基準.md) |
| 画面の部品ごとの実装状況 | [04_画面設計](./docs/04_画面設計.md) |
| 学習教材（講義動画）との違い | [07_技術要件](./docs/07_技術要件.md) の「7. 学習教材との違い」 |
| これまでの Issue・PR | [要件定義書](./要件定義書.md) の「7. これまでの経過」 |

## 構成
```
ブラウザ ─▶ frontend（React / Vite :5173）─ /api を転送 ─▶ backend（Spring Boot :8080）─▶ PostgreSQL（Docker :5432）
```

| フォルダ・ファイル | 内容 |
|---|---|
| `frontend/` | 画面（React + TypeScript + Vite） |
| `backend/` | API（Spring Boot、Java 17、Gradle） |
| `db/` | 動作確認用のテストデータ（`seed_test_data.sql`） |
| `docker-compose.yml` | PostgreSQL のコンテナ定義 |
| `scripts/` | 開発サーバーの起動・停止スクリプト（`dev-servers.ps1`） |
| `docs/` | 要件ドキュメント |
| `index.html`、`mock/` | 旧版（ブラウザだけで動く版）。参考用で、今後は更新しない |

## 使用技術
| 層 | 技術 |
|---|---|
| 画面 | React 19、TypeScript 7、Vite 8 |
| API | Spring Boot 4、Java 17、Gradle 9 |
| データベース | PostgreSQL 17（Docker） |

細かいバージョンは [07_技術要件](./docs/07_技術要件.md) の「2.1 バージョン一覧」を参照してください。

## 必要なもの
- Docker Desktop
- Java 17
- Node.js（npm を含む）
- Windows の PowerShell（起動スクリプトを使う場合）

## 起動方法
### 1. データベース
```
docker compose up -d --wait
```
初回は、`db/seed_test_data.sql` を流すと動作確認用のカードが入ります。

### 2. API と画面（スクリプトで起動する方法）
```
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev-servers.ps1 -Action start
```
- 停止は `-Action stop`、状況の確認は `-Action status` を指定します。
- ポートは **8080（API）と 5173（画面）で固定**です。使用中のときは、持ち主を停止してから起動します。

### 3. 画面を開く
ブラウザで <http://localhost:5173> を開きます。3列とカードが表示されれば成功です。

### 手動で起動する場合
| 手順 | コマンド | 場所 |
|---|---|---|
| API | `./gradlew bootRun` | `backend/` |
| 画面（初回のみ `npm install`） | `npm run dev` | `frontend/` |

### 確認・検査
| 内容 | コマンド | 場所 |
|---|---|---|
| 画面のビルド | `npm run build` | `frontend/` |
| 画面のコード検査 | `npm run lint` | `frontend/` |

## ドキュメント
入口は [要件定義書](./要件定義書.md) です。

| ドキュメント | 内容 |
|---|---|
| [01_機能一覧](./docs/01_機能一覧.md) | 機能のIDと概要、優先度 |
| [02_機能要件](./docs/02_機能要件.md) | 各機能の詳しい振る舞い |
| [03_非機能要件](./docs/03_非機能要件.md) | 使いやすさ・安全性などの条件 |
| [04_画面設計](./docs/04_画面設計.md) | 画面のレイアウトと部品 |
| [05_ユースケース](./docs/05_ユースケース.md) | 操作フロー、状態遷移図 |
| [06_データベース設計](./docs/06_データベース設計.md) | ER図、テーブル、API 一覧 |
| [07_技術要件](./docs/07_技術要件.md) | 全体構成、技術とバージョン、起動方法 |
| [08_受け入れ基準](./docs/08_受け入れ基準.md) | 完成とみなす確認条件 |
| [99_用語集](./docs/99_用語集.md) | 用語の説明 |

## 開発ルール
変更は、Issue → ブランチ → Pull Request の順で行い、`main` へ直接コミット・push しません。
ブランチ名、コミットメッセージ、PR の書き方、サーバーのポートの決まりは [CLAUDE.md](./CLAUDE.md) にまとめています。
