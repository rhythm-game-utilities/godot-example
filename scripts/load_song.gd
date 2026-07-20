extends Node

@export var audio_stream_player: AudioStreamPlayer

@export var song: SongResource

func _ready() -> void:
	if song.audio_stream:
		audio_stream_player.stream = song.audio_stream
		audio_stream_player.call_deferred("play")
