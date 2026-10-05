extends Node
## Autoload. Everything the game makes noise through, and the one place
## that knows which files exist.
##
## Built to be wired up BEFORE the sound files are: every call here is a
## no-op when the file it wants is missing, so the hooks can live in
## hut.gd/BrewingUI/CarvingUI from day one and each .ogg starts working
## the moment it is dropped into assets/audio/. Nothing warns, nothing
## breaks, and a half-filled folder is a perfectly valid state — see
## assets/audio/README.md for the filenames it looks for.
##
## Deliberately NOT a general "play any sound" API: the named methods
## below are the game's whole vocabulary, so the callers never carry file
## paths around and renaming a file is a change in one place.
##
## One rule worth keeping when choosing the knock variants: the knock
## must never reveal Visitor.true_threat. WardRack exists to hint at
## that, at SIGNAL_CHANCE and no better, and an audibly inhuman knock
## would make the whole ward rack pointless. Vary them by mood — hurried,
## heavy, barely audible, too evenly spaced — never by species.

const AUDIO_DIR := "res://assets/audio/"
const SETTINGS_PATH := "user://settings.cfg"

const AMBIENCE_FADE := 2.5 ## seconds to cross between day and night beds
const BUSES := [&"Master", &"Ambience", &"SFX", &"Music"]

## Logical name -> file stem under assets/audio/. A stem ending in "_*"
## is a numbered family (knock_1, knock_2, ...) picked from at random.
const SOUNDS := {
	&"knock": "sfx/knock_*",
	&"door_open": "sfx/door_open",
	&"door_close": "sfx/door_close",
	&"floorboard": "sfx/floorboard_*",
	&"ingredient_drop": "sfx/ingredient_drop_*",
	&"stir": "sfx/stir",
	&"carve": "sfx/carve_*",
	&"give_item": "sfx/give_item",
	&"day_ambience": "ambience/day",
	&"night_ambience": "ambience/night",
	&"cauldron_loop": "sfx/cauldron_loop",
	&"fire_loop": "sfx/fire_loop",
	&"trembita": "music/trembita",
}

var _streams: Dictionary = {} # StringName -> Array[AudioStream]
var _sfx_players: Array[AudioStreamPlayer] = []
var _ambience_a: AudioStreamPlayer
var _ambience_b: AudioStreamPlayer
var _ambience_on_a: bool = true
var _music: AudioStreamPlayer
var _loops: Dictionary = {} # StringName -> AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # keep ambience alive through the pause menu
	_index_sounds()
	_build_players()
	_load_settings()
	GameCalendar.phase_changed.connect(_on_phase_changed)
	# The calendar has already settled by now, so start on the right bed
	# rather than waiting for the first flip hours into the session.
	_on_phase_changed(GameCalendar.phase)

## Walks assets/audio/ once and remembers what is actually there. Doing
## it by directory listing rather than by load()-and-catch keeps a fresh
## checkout with no audio at all completely silent in the console.
func _index_sounds() -> void:
	for key: StringName in SOUNDS:
		var stem: String = SOUNDS[key]
		var found: Array[AudioStream] = []
		if stem.ends_with("_*"):
			var prefix := stem.trim_suffix("*")
			for i in range(1, 10):
				var stream := _try_load("%s%d" % [prefix, i])
				if stream != null:
					found.append(stream)
		else:
			var stream := _try_load(stem)
			if stream != null:
				found.append(stream)
		if not found.is_empty():
			_streams[key] = found

func _try_load(stem: String) -> AudioStream:
	for extension: String in [".ogg", ".wav", ".mp3"]:
		var path := AUDIO_DIR + stem + extension
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null

func _build_players() -> void:
	# A small pool, so two sounds landing together don't cut each other
	# off — a knock during the day bed, a herb dropping mid-stir.
	for i in 6:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_sfx_players.append(player)
	_ambience_a = _new_player(&"Ambience")
	_ambience_b = _new_player(&"Ambience")
	_music = _new_player(&"Music")

func _new_player(bus: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus
	add_child(player)
	return player

## --- Playback -------------------------------------------------------

## One-shot. Unknown or not-yet-added names are silently ignored, which
## is the whole point — see the class doc.
func play(name: StringName, volume_db: float = 0.0) -> void:
	if not _streams.has(name):
		return
	var variants: Array = _streams[name]
	var player := _free_player()
	player.stream = variants[randi() % variants.size()]
	player.volume_db = volume_db
	player.play()

func _free_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player
	# All busy: reuse the oldest rather than dropping the sound, since a
	# missed knock is worse than a clipped floorboard creak.
	return _sfx_players[0]

## Starts a named looping sound if it isn't already going (the cauldron
## while BrewingUI is open, the hearth while in the hut). Idempotent.
func start_loop(name: StringName, volume_db: float = 0.0) -> void:
	if not _streams.has(name) or _loops.has(name):
		return
	var player := _new_player(&"SFX")
	player.stream = _looped(_streams[name][0])
	player.volume_db = volume_db
	player.play()
	_loops[name] = player

func stop_loop(name: StringName) -> void:
	if not _loops.has(name):
		return
	var player: AudioStreamPlayer = _loops[name]
	_loops.erase(name)
	player.queue_free()

## The chapter's only piece of music — see ChapterEnd. Трембіта
## traditionally announced a death across the valley, which is why it is
## held back for exactly one screen instead of playing under the game.
func play_music(name: StringName) -> void:
	if not _streams.has(name):
		return
	_music.stream = _streams[name][0]
	_music.play()

func stop_music() -> void:
	_music.stop()

## Sets the loop flag on the stream itself rather than asking whoever
## adds the file to remember the import setting.
func _looped(stream: AudioStream) -> AudioStream:
	var copy := stream.duplicate()
	if copy is AudioStreamOggVorbis:
		(copy as AudioStreamOggVorbis).loop = true
	elif copy is AudioStreamWAV:
		# loop_mode alone is not enough here: loop_end defaults to 0, so
		# the loop region is empty and playback simply ends — which looks
		# exactly like a crossfade dropping both beds halfway through.
		var wav := copy as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * wav.mix_rate)
	elif copy is AudioStreamMP3:
		(copy as AudioStreamMP3).loop = true
	return copy

## --- Ambience -------------------------------------------------------

func _on_phase_changed(phase: int) -> void:
	var wanted: StringName = &"night_ambience" if phase == GameCalendar.Phase.NIGHT else &"day_ambience"
	_crossfade_ambience(wanted)

## Two players swapping roles, so day and night overlap for a moment
## instead of one cutting out before the other starts.
func _crossfade_ambience(name: StringName) -> void:
	if not _streams.has(name):
		return
	var incoming := _ambience_b if _ambience_on_a else _ambience_a
	var outgoing := _ambience_a if _ambience_on_a else _ambience_b
	_ambience_on_a = not _ambience_on_a

	incoming.stream = _looped(_streams[name][0])
	incoming.volume_db = -40.0
	incoming.play()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(incoming, "volume_db", 0.0, AMBIENCE_FADE)
	if outgoing.playing:
		tween.tween_property(outgoing, "volume_db", -40.0, AMBIENCE_FADE)
		tween.chain().tween_callback(outgoing.stop)

## --- Volume, persisted outside the save ------------------------------
##
## Settings are not part of a playthrough, so they live in their own
## file: wiping the save or starting a new game must not reset the
## volume someone set once.

func set_bus_volume(bus: StringName, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(clampf(linear, 0.0, 1.0)))
	AudioServer.set_bus_mute(index, linear <= 0.001)
	_save_settings()

func get_bus_volume(bus: StringName) -> float:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return 1.0
	if AudioServer.is_bus_mute(index):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(index))

func _save_settings() -> void:
	var config := ConfigFile.new()
	for bus: StringName in BUSES:
		config.set_value("audio", String(bus), get_bus_volume(bus))
	config.save(SETTINGS_PATH)

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	for bus: StringName in BUSES:
		var index := AudioServer.get_bus_index(bus)
		if index < 0:
			continue
		var linear: float = config.get_value("audio", String(bus), 1.0)
		AudioServer.set_bus_volume_db(index, linear_to_db(clampf(linear, 0.0, 1.0)))
		AudioServer.set_bus_mute(index, linear <= 0.001)
