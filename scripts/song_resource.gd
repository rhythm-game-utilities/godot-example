class_name SongResource

extends Resource

@export var audio_stream: AudioStream
@export var notes_path: String

var _song_data: Song

var song_data: Song:
	get:
		if _song_data == null:
			_load_song()
		return _song_data

func _load_song() -> void:
	_song_data = Song.new()

	if not FileAccess.file_exists(notes_path):
		printerr("Missing notes file!")
		return

	if notes_path.ends_with(".mid"):
		var data := FileAccess.get_file_as_bytes(notes_path)
		_song_data.load_song_from_midi(data)

		for note: Variant in _song_data.notes:
			if note["hand_position"] == 65:
				note["hand_position"] = 0
			elif note["hand_position"] == 69:
				note["hand_position"] = 1
			elif note["hand_position"] == 72:
				note["hand_position"] = 2

	elif notes_path.ends_with(".chart"):
		var data := FileAccess.get_file_as_string(notes_path)
		_song_data.load_song_from_chart(data, rhythm_game_utilities.Difficulty.Easy)

	if audio_stream:
		_song_data.recalculate_beat_bars_with_song_length(audio_stream.get_length(), true)
	else:
		printerr("Missing audio file!")

func mark_note_as_hit(id: int) -> void:
	for note: Variant in _song_data.notes:
		if note["id"] == id:
			note["hit"] = true
			break
