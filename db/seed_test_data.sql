-- 開発・動作確認用のテストデータ（手動で実行する。schema.sql のように自動実行はされない）
-- 何度実行しても重複しない（同じ列に同じ text が既にあれば追加しない）。
-- 前提：schema.sql 適用済みで、初期の列（未着手・進行中・完了）がある。

INSERT INTO cards (column_id, text, position)
SELECT c.id, v.text, v.position
FROM (VALUES
    ('未着手', '買い物に行く',            0),
    ('未着手', 'レポートを書く',          1),
    ('未着手', '部屋の掃除をする',        2),
    ('進行中', 'Dockerの使い方を学ぶ',    0),
    ('進行中', 'PostgreSQLにテーブルを作る', 1),
    ('完了',   'GitHubのルールを整備する', 0),
    ('完了',   'Docker Desktopを入れる',  1)
) AS v(column_name, text, position)
JOIN columns c ON c.name = v.column_name
WHERE NOT EXISTS (
    SELECT 1 FROM cards x WHERE x.column_id = c.id AND x.text = v.text
);
