-- docs/06_データベース設計.md を PostgreSQL 向けにしたもの
-- 何度実行しても安全（IF NOT EXISTS / WHERE NOT EXISTS）

CREATE TABLE IF NOT EXISTS boards (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       TEXT        NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS columns (
    id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    board_id BIGINT  NOT NULL REFERENCES boards(id) ON DELETE CASCADE,
    name     TEXT    NOT NULL,
    position INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS cards (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    column_id  BIGINT      NOT NULL REFERENCES columns(id) ON DELETE CASCADE,
    text       TEXT        NOT NULL,
    position   INTEGER     NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_columns_board_id ON columns(board_id);
CREATE INDEX IF NOT EXISTS idx_cards_column_id  ON cards(column_id);

-- 初期データ：ボード1件と列3件（未着手・進行中・完了）
INSERT INTO boards (name)
SELECT 'タスク管理ボード'
WHERE NOT EXISTS (SELECT 1 FROM boards);

INSERT INTO columns (board_id, name, position)
SELECT b.id, c.name, c.position
FROM (SELECT id FROM boards ORDER BY id LIMIT 1) b
CROSS JOIN (VALUES ('未着手', 0), ('進行中', 1), ('完了', 2)) AS c(name, position)
WHERE NOT EXISTS (SELECT 1 FROM columns);
