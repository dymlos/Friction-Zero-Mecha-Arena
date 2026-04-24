extends SceneTree

const PostMatchEvent = preload("res://scripts/systems/post_match_event.gd")
const PostMatchReview = preload("res://scripts/systems/post_match_review.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert_timestamp_format()
	_assert_ignores_empty_events()
	_assert_match_close_is_selected_first()
	_assert_snippets_are_limited_to_three()
	_assert_decisive_support_beats_common_pickup()
	_assert_mode_specific_reading()
	_assert_review_copy_stays_out_of_onboarding()
	_finish()


func _assert_timestamp_format() -> void:
	_assert(PostMatchEvent.format_timestamp(0.0) == "00:00", "El timestamp cero deberia formatear 00:00.")
	_assert(PostMatchEvent.format_timestamp(9.4) == "00:09", "El timestamp bajo diez segundos deberia rellenar segundos.")
	_assert(PostMatchEvent.format_timestamp(65.0) == "01:05", "El timestamp deberia formatear minutos y segundos.")
	_assert(
		PostMatchEvent.format_moment_line(
			"Momento decisivo",
			{"headline": "Player 4 cayo al vacio por Player 1"}
		) == "Momento decisivo | Player 4 cayo al vacio por Player 1",
		"El formateador de momento deberia conservar etiqueta y headline."
	)


func _assert_ignores_empty_events() -> void:
	var review := PostMatchReview.new()
	review.record_event(PostMatchEvent.make_event(1, 1, 0.0, PostMatchEvent.TYPE_ELIMINATION, 90, ""))
	var summary := review.build_review(_teams_context())
	_assert((summary.get("snippets", []) as Array).is_empty(), "Los eventos sin headline no deberian alimentar snippets.")


func _assert_match_close_is_selected_first() -> void:
	var review := PostMatchReview.new()
	review.record_event(PostMatchEvent.make_event(
		1,
		1,
		10.0,
		PostMatchEvent.TYPE_ELIMINATION,
		90,
		"Player 3 cayo al vacio",
		"",
		{"arena_zone": "borde oeste", "cause_label": "ring-out", "competitor_label": "Player 3"}
	))
	review.record_event(PostMatchEvent.make_event(
		2,
		1,
		18.0,
		PostMatchEvent.TYPE_MATCH_CLOSE,
		70,
		"Equipo 1 cerro la partida",
		"",
		{"arena_zone": "borde este", "cause_label": "ring-out", "competitor_label": "Equipo 1"}
	))
	review.build_review(_teams_context())
	var snippets := review.get_snippet_lines()
	_assert(snippets.size() >= 1, "El cierre de match deberia generar al menos un snippet.")
	_assert(snippets[0] == "Replay | 00:18 R1 | borde este | ring-out | Equipo 1", "El cierre de match deberia entrar primero aunque tenga menor prioridad.")
	_assert(_has_line_containing(snippets, "Replay | 00:18 R1 | borde este | ring-out | Equipo 1"), "El replay deberia incluir tiempo, ronda, zona, causa y competidor.")


func _assert_snippets_are_limited_to_three() -> void:
	var review := PostMatchReview.new()
	for index in range(5):
		review.record_event(PostMatchEvent.make_event(
			index + 1,
			1,
			float(index),
			PostMatchEvent.TYPE_ELIMINATION,
			80 - index,
			"Baja %s" % index,
			"",
			{"arena_zone": "centro", "cause_label": "ring-out", "competitor_label": "Player %s" % index}
		))
	review.build_review(_teams_context())
	_assert(review.get_snippet_lines().size() == 3, "La revision no deberia mostrar mas de tres snippets.")


func _assert_decisive_support_beats_common_pickup() -> void:
	var review := PostMatchReview.new()
	review.record_event(PostMatchEvent.make_event(
		1,
		1,
		8.0,
		PostMatchEvent.TYPE_EDGE_PICKUP,
		80,
		"Player 1 tomo energia de borde",
		"",
		{"arena_zone": "borde norte", "competitor_label": "Player 1"}
	))
	review.record_event(PostMatchEvent.make_event(
		2,
		1,
		11.0,
		PostMatchEvent.TYPE_SUPPORT,
		65,
		"Apoyo de Equipo 1 preparo el cierre",
		"",
		{"arena_zone": "borde sur", "competitor_label": "Equipo 1", "decisive": true}
	))
	review.build_review(_teams_context())
	var snippets := review.get_snippet_lines()
	_assert(snippets.size() >= 2, "La revision deberia conservar soporte y pickup si hay espacio.")
	_assert(snippets[0].contains("Equipo 1"), "El soporte decisivo deberia priorizarse sobre pickups comunes.")


func _assert_mode_specific_reading() -> void:
	var teams_review := PostMatchReview.new()
	var teams_summary := teams_review.build_review(_teams_context())
	var teams_story := teams_summary.get("story", []) as Array
	_assert(_has_line_containing(teams_story, "Lectura | Equipo 1"), "Teams deberia producir lectura centrada en equipo ganador.")
	_assert(_has_line_containing(teams_review.get_loser_reading_lines(), "Como perdiste |"), "Teams deberia producir una lectura compacta de derrota clara.")

	var ffa_review := PostMatchReview.new()
	var ffa_summary := ffa_review.build_review(_ffa_context())
	var ffa_story := ffa_summary.get("story", []) as Array
	_assert(_has_line_containing(ffa_story, "Lectura | FFA"), "FFA deberia producir lectura centrada en supervivencia/posiciones.")
	_assert(_has_line_containing(ffa_review.get_loser_reading_lines(), "Como perdiste |"), "FFA deberia producir una lectura compacta global, no por jugador.")


func _assert_review_copy_stays_out_of_onboarding() -> void:
	for context in [_teams_context(), _ffa_context()]:
		var review := PostMatchReview.new()
		review.record_event(PostMatchEvent.make_event(
			1,
			1,
			12.0,
			PostMatchEvent.TYPE_MATCH_CLOSE,
			100,
			"%s cerro la partida" % String(context.get("winner_label", "Ganador")),
			"",
			{
				"arena_zone": "borde este",
				"cause_label": "ring-out",
				"competitor_label": String(context.get("winner_label", "Ganador")),
			}
		))
		review.build_review(context)

		var lines: Array[String] = []
		lines.append_array(review.get_story_lines())
		lines.append_array(review.get_loser_reading_lines())
		lines.append_array(review.get_snippet_lines())
		var joined_lines := "\n".join(PackedStringArray(lines))
		for forbidden in ["How to Play", "Controles", "Easy", "Hard", "Tutorial", "Practica", "tabla"]:
			_assert(
				not joined_lines.contains(forbidden),
				"PostMatchReview no debe emitir onboarding: %s" % forbidden
			)


func _teams_context() -> Dictionary:
	return {
		"match_mode": "Teams",
		"winner_label": "Equipo 1",
		"winner_key": "team_1",
		"score_line": "Marcador | Equipo 1 1 | Equipo 2 0",
		"closing_cause_label": "ring-out",
		"closing_summary_line": "Cierre decisivo | ring-out (+2)",
		"part_loss_lines": ["Stats | Equipo 2 | partes perdidas 3 (1 brazos, 2 piernas) | bajas sufridas 2 (2 vacio)"],
		"support_summary_line": "Aporte de apoyo | 1/1 rondas (100%) decisivas con apoyo",
		"last_elimination_line": "Ultima baja | Player 4 cayo al vacio por Player 1",
	}


func _ffa_context() -> Dictionary:
	return {
		"match_mode": "FFA",
		"winner_label": "Player 1 / Ariete",
		"winner_key": "player_1",
		"score_line": "Marcador | Player 1 2 pts | Player 2 0 pts",
		"standings_line": "Posiciones | 1. Player 1 | 2. Player 2 | 3. Player 3",
		"tiebreaker_line": "Desempate | 0 pts: Player 2 > Player 3",
		"closing_cause_label": "ring-out",
		"closing_summary_line": "Cierre decisivo | ring-out (+2)",
		"part_loss_lines": [],
		"support_summary_line": "",
		"last_elimination_line": "Ultima baja | Player 3 cayo al vacio por Player 1",
	}


func _has_line_containing(lines: Array, expected_fragment: String) -> bool:
	for line in lines:
		if str(line).contains(expected_fragment):
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _finish() -> void:
	quit(1 if _failed else 0)
