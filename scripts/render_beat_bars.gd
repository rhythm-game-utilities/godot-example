extends Node

@export var beat_bar_mesh: Mesh

@export var audio_stream_player: AudioStreamPlayer

@export var song: SongResource

@export var _tick_scale := 5

@export var _distance := 50

var _scenario: RID
var _beat_bar_instances: Array[RID]

func _ready() -> void:
	_scenario = get_viewport().find_world_3d().scenario

	for i in song.song_data.beat_bars.size():
		var instance := RenderingServer.instance_create()

		var mesh: Mesh = beat_bar_mesh

		RenderingServer.instance_set_scenario(instance, _scenario)
		RenderingServer.instance_set_base(instance, mesh)
		RenderingServer.instance_set_visible(instance, false)

		_beat_bar_instances.append(instance)

func _process(_delta: float) -> void:
	var tick_offset := rhythm_game_utilities.convert_seconds_to_ticks(
		audio_stream_player.get_playback_position(), song.song_data.resolution,
				song.song_data.tempo_changes
	)

	for i in song.song_data.beat_bars.size():
		var position: int = song.song_data.beat_bars[i]["position"]

		if not _beat_bar_instances[i].is_valid():
			continue

		var current_position := rhythm_game_utilities.convert_tick_to_position(
			position - tick_offset, song.song_data.resolution
		) * _tick_scale

		RenderingServer.instance_set_visible(_beat_bar_instances[i],
			current_position > -1 && current_position < _distance
		)

		RenderingServer.instance_set_transform(_beat_bar_instances[i],
			Transform3D(Basis.IDENTITY, Vector3(0, 0, -current_position))
		)

func _exit_tree() -> void:
	for beat_bar_instance in _beat_bar_instances:
		if beat_bar_instance.is_valid():
			RenderingServer.free_rid(beat_bar_instance)
	_beat_bar_instances.clear()
