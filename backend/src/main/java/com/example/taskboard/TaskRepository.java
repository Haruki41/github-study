package com.example.taskboard;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import com.example.taskboard.TaskModels.Board;
import com.example.taskboard.TaskModels.Card;
import com.example.taskboard.TaskModels.Column;

/** DB（PostgreSQL）から読み取る。値は必ず「?」のパラメータで渡す（SQL インジェクション対策）。 */
@Repository
public class TaskRepository {

	private static final RowMapper<Card> CARD_MAPPER = TaskRepository::mapCard;

	private final JdbcTemplate jdbc;

	public TaskRepository(JdbcTemplate jdbc) {
		this.jdbc = jdbc;
	}

	private static Card mapCard(ResultSet rs, int rowNum) throws SQLException {
		return new Card(
				rs.getLong("id"),
				rs.getLong("column_id"),
				rs.getString("text"),
				rs.getInt("position"),
				rs.getObject("created_at", OffsetDateTime.class));
	}

	/** 最初のボードを、列とカードごとまとめて取得する。ボードが無ければ空。 */
	public Optional<Board> findBoard() {
		List<Board> boards = jdbc.query(
				"SELECT id, name, created_at FROM boards ORDER BY id LIMIT 1",
				(rs, n) -> new Board(rs.getLong("id"), rs.getString("name"),
						rs.getObject("created_at", OffsetDateTime.class), List.of()));
		if (boards.isEmpty()) {
			return Optional.empty();
		}
		Board board = boards.get(0);

		List<Card> cards = jdbc.query(
				"""
				SELECT ca.id, ca.column_id, ca.text, ca.position, ca.created_at
				FROM cards ca JOIN columns co ON co.id = ca.column_id
				WHERE co.board_id = ?
				ORDER BY ca.position, ca.id
				""", CARD_MAPPER, board.id());
		Map<Long, List<Card>> cardsByColumn = new LinkedHashMap<>();
		for (Card card : cards) {
			cardsByColumn.computeIfAbsent(card.columnId(), k -> new ArrayList<>()).add(card);
		}

		List<Column> columns = jdbc.query(
				"SELECT id, name, position FROM columns WHERE board_id = ? ORDER BY position, id",
				(rs, n) -> new Column(rs.getLong("id"), rs.getString("name"), rs.getInt("position"),
						cardsByColumn.getOrDefault(rs.getLong("id"), List.of())),
				board.id());

		return Optional.of(new Board(board.id(), board.name(), board.createdAt(), columns));
	}

	/** カード一覧。columnId・keyword は省略可（null なら絞り込まない）。 */
	public List<Card> findCards(Long columnId, String keyword) {
		StringBuilder sql = new StringBuilder(
				"SELECT id, column_id, text, position, created_at FROM cards WHERE 1 = 1");
		List<Object> params = new ArrayList<>();
		if (columnId != null) {
			sql.append(" AND column_id = ?");
			params.add(columnId);
		}
		if (keyword != null && !keyword.isBlank()) {
			// position() を使い、% や _ を含む検索語もそのまま文字として扱う
			sql.append(" AND position(lower(?) in lower(text)) > 0");
			params.add(keyword.trim());
		}
		sql.append(" ORDER BY column_id, position, id");
		return jdbc.query(sql.toString(), CARD_MAPPER, params.toArray());
	}

	public Optional<Card> findCard(long id) {
		return jdbc.query(
				"SELECT id, column_id, text, position, created_at FROM cards WHERE id = ?",
				CARD_MAPPER, id).stream().findFirst();
	}
}
