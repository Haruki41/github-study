package com.example.taskboard;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import com.example.taskboard.TaskModels.Board;
import com.example.taskboard.TaskModels.Card;

/** 読み取り専用の API（CRUD の R）。 */
@RestController
@RequestMapping("/api")
public class TaskController {

	private final TaskRepository repository;

	public TaskController(TaskRepository repository) {
		this.repository = repository;
	}

	/** ボード・列・カードをまとめて取得する。 */
	@GetMapping("/board")
	public Board board() {
		return repository.findBoard()
				.orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "ボードがありません"));
	}

	/** カード一覧。?columnId=1 で列、?q=Docker でキーワードの絞り込み。 */
	@GetMapping("/cards")
	public List<Card> cards(
			@RequestParam(required = false) Long columnId,
			@RequestParam(required = false) String q) {
		return repository.findCards(columnId, q);
	}

	/** カードを1件取得する。無ければ 404。 */
	@GetMapping("/cards/{id}")
	public Card card(@PathVariable long id) {
		return repository.findCard(id)
				.orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "カードが見つかりません: " + id));
	}
}
