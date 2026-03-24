extends Node

@export var audio_stream: AudioStreamPlayer
@export var mesh: Mesh

var _scenario: RID
var _materials: Dictionary[String, Material]
var _track_instance: RID
var _track_separator_instances: Array[RID]
var _hit_note_instances: Array[RID]
var _note_instances: Dictionary[int, RID]

var _tick_scale: int = 5

var _note_scale: Vector3 = Vector3(0.5, 0.1, 0.35)
var _hit_note_scale: Vector3 = Vector3(0.5, 0.05, 0.35)

var _distance: float = 50

var _song: Song

func _create_material_from_color(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	return material

func _ready() -> void:
	_scenario = get_viewport().find_world_3d().scenario

	var file: FileAccess = FileAccess.open("res://songs/Demo 1/notes.chart", FileAccess.READ)
	var contents: String = file.get_as_text()

	_song = Song.new()
	_song.load_song_from_chart(contents, rhythm_game_utilities.Medium)

	audio_stream.stream = load("res://songs/Demo 1/song.ogg")
	audio_stream.play()

	_song.recalculate_beat_bars_with_song_length(audio_stream.stream.get_length(), true)

	_setup_colors()
	_setup_track()
	_setup_track_separators()
	_setup_hit_notes()

func _process(_delta: float) -> void:
	_update_notes()

func _setup_colors() -> void:
	_materials["black"] = _create_material_from_color(Color(0.0, 0.0, 0.0))
	_materials["white"] = _create_material_from_color(Color(0.75, 0.75, 0.75))
	_materials["green"] = _create_material_from_color(Color(0.0, 1.0, 0.0))
	_materials["red"] = _create_material_from_color(Color(1.0, 0.0, 0.0))
	_materials["yellow"] = _create_material_from_color(Color(1.0, 1.0, 0.0))
	_materials["blue"] = _create_material_from_color(Color(0.0, 0.0, 1.0))
	_materials["orange"] = _create_material_from_color(Color(1.0, 0.5, 0.0))

func _setup_track() -> void:
	var transform: Transform3D = Transform3D(
		Basis.IDENTITY.scaled(Vector3(5, 0.1, _distance)), Vector3(2.5, -0.05, -_distance / 2))

	var instance: RID = RenderingServer.instance_create()
	RenderingServer.instance_set_base(instance, mesh)
	RenderingServer.instance_set_scenario(instance, _scenario)
	RenderingServer.instance_set_transform(instance, transform)
	RenderingServer.instance_geometry_set_material_override(instance, _materials["black"].get_rid())

	_track_instance = instance

func _setup_track_separators() -> void:
	for i: int in range(6):
		var transform: Transform3D = Transform3D(
			Basis.IDENTITY.scaled(Vector3(0.05, 0.15, _distance)),
			Vector3(0.05 + (i * 1), -0.025, -_distance / 2))

		var instance: RID = RenderingServer.instance_create()
		RenderingServer.instance_set_base(instance, mesh)
		RenderingServer.instance_set_scenario(instance, _scenario)
		RenderingServer.instance_set_transform(instance, transform)
		RenderingServer.instance_geometry_set_material_override(instance,
			_materials["white"].get_rid())

		_track_separator_instances.push_back(instance)

func _setup_hit_notes() -> void:
	for i: int in range(5):
		var transform: Transform3D = Transform3D(
			Basis.IDENTITY.scaled(_hit_note_scale), Vector3(i + 0.5, 0, 0))

		var instance: RID = RenderingServer.instance_create()
		RenderingServer.instance_set_base(instance, mesh)
		RenderingServer.instance_set_scenario(instance, _scenario)
		RenderingServer.instance_set_transform(instance, transform)

		var note_color: String = "green"

		match (i):
			0:
				note_color = "green"
			1:
				note_color = "red"
			2:
				note_color = "yellow"
			3:
				note_color = "blue"
			4:
				note_color = "orange"

		RenderingServer.instance_geometry_set_material_override(instance,
			_materials[note_color].get_rid())

		_hit_note_instances.push_back(instance)

func _update_notes() -> void:
	var tick_offset: int = rhythm_game_utilities.convert_seconds_to_ticks(
		audio_stream.get_playback_position(), _song.resolution, _song.tempo_changes)

	for i: int in _song.notes.size():
		var position: int = _song.notes[i]["position"]
		var hand_position: int = _song.notes[i]["hand_position"]

		var current_position: float = rhythm_game_utilities.convert_tick_to_position(
			position - tick_offset, _song.resolution) * _tick_scale

		if _note_instances.has(i) and _note_instances[i]:
			var transform: Transform3D = Transform3D(
				Basis.IDENTITY.scaled(_note_scale),
				Vector3(hand_position + 0.5, 0, -current_position))

			RenderingServer.instance_set_transform(_note_instances[i], transform)

			if current_position < 0:
				RenderingServer.free_rid(_note_instances[i])
				var _results: bool = _note_instances.erase(i)

		elif not _note_instances.has(i) and current_position > 0 and current_position < _distance and hand_position < 5:
			var transform: Transform3D = Transform3D(
				Basis.IDENTITY.scaled(_note_scale),
				Vector3(hand_position + 0.5, 0, -current_position))

			var instance: RID = RenderingServer.instance_create()
			RenderingServer.instance_set_base(instance, mesh)
			RenderingServer.instance_set_scenario(instance, _scenario)
			RenderingServer.instance_set_transform(instance, transform)

			var note_color: String = "green"

			match (_song.notes[i]["hand_position"]):
				0:
					note_color = "green"
				1:
					note_color = "red"
				2:
					note_color = "yellow"
				3:
					note_color = "blue"
				4:
					note_color = "orange"

			RenderingServer.instance_geometry_set_material_override(instance,
				_materials[note_color].get_rid())

			_note_instances[i] = instance

func _exit_tree() -> void:
	RenderingServer.free_rid(_track_instance)

	for track_separator: RID in _track_separator_instances:
		RenderingServer.free_rid(track_separator)

	for i: int in _note_instances.size():
		RenderingServer.free_rid(_note_instances[i])

	for hit_note_instance: RID in _hit_note_instances:
		RenderingServer.free_rid(hit_note_instance)
