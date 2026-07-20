extends Node

@export var audio_stream_player: AudioStreamPlayer

@export var song: SongResource

@export var _delta := 50

signal note_hit(accuracy: int, accuracy_ratio: float)

signal note_missed

var _input_mapping := {
	"lane1": 0,
	"lane2": 1,
	"lane3": 2,
}

func _input(_event: InputEvent) -> void:
	if song.song_data.notes.is_empty():
		return

	var tick_offset := rhythm_game_utilities.convert_seconds_to_ticks(
		audio_stream_player.get_playback_position(), song.song_data.resolution,
		song.song_data.tempo_changes
	)

	var found_notes := rhythm_game_utilities.find_notes_near_given_tick(
		song.song_data.notes, tick_offset, _delta
	)

	if found_notes.is_empty():
		return

	for found_note: Variant in found_notes:
		var id: int = found_note["id"]
		var hand_position: int = found_note["hand_position"]

		var position: int = found_note["position"]

		var hit := false

		for action: String in _input_mapping:
			if _event.is_action_pressed(action) and hand_position == _input_mapping[action]:
				hit = true
				break

		if not hit:
			note_missed.emit()
			continue

		song.mark_note_as_hit(id)

		var accuracy := rhythm_game_utilities.calculate_accuracy(position, tick_offset, _delta)
		var accuracy_ratio := rhythm_game_utilities.calculate_accuracy_ratio(position, tick_offset, _delta)

		note_hit.emit(accuracy, accuracy_ratio)
