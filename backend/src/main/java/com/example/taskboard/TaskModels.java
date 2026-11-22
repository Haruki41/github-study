package com.example.taskboard;

import java.time.OffsetDateTime;
import java.util.List;

/** API が返す JSON の形。 */
public final class TaskModels {

	private TaskModels() {
	}

	public record Card(long id, long columnId, String text, int position, OffsetDateTime createdAt) {
	}

	public record Column(long id, String name, int position, List<Card> cards) {
	}

	public record Board(long id, String name, OffsetDateTime createdAt, List<Column> columns) {
	}
}
