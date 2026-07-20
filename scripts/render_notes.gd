extends Node

@export var note_green_mesh: Mesh
@export var note_red_mesh: Mesh
@export var note_yellow_mesh: Mesh

@export var audio_stream_player: AudioStreamPlayer

@export var song: SongResource

@export var _tick_scale := 5

@export var _distance := 50

var _scenario: RID
var _note_instances: Dictionary[int, RID]

@onready var _hand_position_mapping := {
	0: {"mesh": note_green_mesh, "x": - 2.0},
	1: {"mesh": note_red_mesh, "x": 0.0},
	2: {"mesh": note_yellow_mesh, "x": 2.0}
}

func _ready() -> void:
	_scenario = get_viewport().find_world_3d().scenario

	for note: Variant in song.song_data.notes:
		var id: int = note["id"]
		var hand_position: int = note["hand_position"]

		var instance := RenderingServer.instance_create()

		var mesh: Mesh = _hand_position_mapping[hand_position]["mesh"]

		RenderingServer.instance_set_scenario(instance, _scenario)
		RenderingServer.instance_set_base(instance, mesh)
		RenderingServer.instance_set_visible(instance, false)

		_note_instances[id] = instance

func _process(_delta: float) -> void:
	var tick_offset := rhythm_game_utilities.convert_seconds_to_ticks(
		audio_stream_player.get_playback_position(), song.song_data.resolution,
		song.song_data.tempo_changes
	)

	for note: Variant in song.song_data.notes:
		var id: int = note["id"]
		var position: int = note["position"]
		var hand_position: int = note["hand_position"]
		var hit: bool = "hit" in note

		if not _note_instances.has(id) or not _note_instances[id].is_valid():
			continue

		var current_position := rhythm_game_utilities.convert_tick_to_position(
			position - tick_offset, song.song_data.resolution
		) * _tick_scale

		RenderingServer.instance_set_visible(_note_instances[id],
			current_position > -10 && current_position < _distance && !hit
		)

		var x: float = _hand_position_mapping[hand_position]["x"]

		RenderingServer.instance_set_transform(_note_instances[id],
			Transform3D(Basis.IDENTITY, Vector3(x, 0, -current_position))
		)

func _exit_tree() -> void:
	for note_instance: RID in _note_instances.values():
		if note_instance.is_valid():
			RenderingServer.free_rid(note_instance)
	_note_instances.clear()
