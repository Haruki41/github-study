package com.example.taskboard;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class DbCheckController {

	private final JdbcTemplate jdbc;

	public DbCheckController(JdbcTemplate jdbc) {
		this.jdbc = jdbc;
	}

	// PostgreSQL に接続できるかの確認用
	@GetMapping("/db-check")
	public String dbCheck() {
		return jdbc.queryForObject("select version()", String.class);
	}
}
