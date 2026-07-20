extends Node

@export var score_label: Label
@export var multiplier_label: Label
@export var accuracy_label: Label

@export var _score_min_increment := 10
@export var _score_max_increment := 100
@export var _multiplier_increment := 0.25

var _score := 0
var _multiplier := 1.0

var _accuracy_labels := ["Invalid", "Poor", "Fair", "Good", "Great", "Perfect"]

func update_ui(score: int, multiplier: float, accuracy: String) -> void:
	score_label.text = "Score: %d" % score
	multiplier_label.text = "Multiplier: %.2fx" % multiplier
	accuracy_label.text = accuracy
	accuracy_label.visible = not accuracy.is_empty()

func _on_handle_input_note_hit(accuracy: int, accuracy_ratio: float) -> void:
	_score += lerp(_score_max_increment, _score_min_increment, abs(accuracy_ratio)) * floor(_multiplier)
	_multiplier += _multiplier_increment

	var accuracy_label_value: String = _accuracy_labels[accuracy - 1]

	update_ui(_score, _multiplier, accuracy_label_value)

func _on_handle_input_note_missed() -> void:
	_multiplier = max(_multiplier - 1, 1)
	update_ui(_score, _multiplier, "Miss")
