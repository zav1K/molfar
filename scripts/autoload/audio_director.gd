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

## Preference order when the same sound exists in more than one.
const EXTENSIONS := [".ogg", ".wav", ".mp3"]

const AMBIENCE_FADE := 2.5 ## seconds to cross between day and night beds
const BUSES := [&"Master", &"Ambience", &"SFX", &"Music"]

## Logical name -> how to find it and how to play it.
##
## `prefixes` are matched against the real filenames found in
## assets/audio/, so anything starting with one counts as a variant and
## knock_1 … knock_5 all answer to &"knock" without being listed. Drop
## in a sixth and it joins the rotation; no number sequence to keep
## unbroken, no code change.
##
## `volume` is the sound's place in the mix. `pitch` is the half-width
## of a random pitch shift applied per play, which matters more than it
## sounds: most of these have only one or two variants, and a single
## sample played back identically every time stops reading as a door and
## starts reading as a sound effect by about the fifth knock. A few
## percent of wobble, plus the volume jitter below, hides that almost
## completely.
const SOUNDS := {
	&"knock": {prefixes = ["sfx/knock"], volume = 0.0, pitch = 0.07},
	&"door_open": {prefixes = ["sfx/door_open"], volume = -2.0, pitch = 0.04},
	&"door_close": {prefixes = ["sfx/door_close"], volume = -2.0, pitch = 0.04},
	&"floorboard": {prefixes = ["sfx/floorboard"], volume = -8.0, pitch = 0.10},
	&"ingredient_drop": {prefixes = ["sfx/ingredient_drop"], volume = -4.0, pitch = 0.12},
	&"stir": {prefixes = ["sfx/stir"], volume = -4.0, pitch = 0.06},
	&"carve_loop": {prefixes = ["sfx/carve"], volume = -6.0, pitch = 0.0},
	&"give_item": {prefixes = ["sfx/give_item"], volume = -4.0, pitch = 0.06},
	&"day_ambience": {prefixes = ["ambience/day"], volume = -6.0, pitch = 0.0},
	&"night_ambience": {prefixes = ["ambience/night"], volume = -6.0, pitch = 0.0},
	&"cauldron_loop": {prefixes = ["sfx/cauldron"], volume = -4.0, pitch = 0.0},
	&"fire_loop": {prefixes = ["sfx/fire"], volume = -8.0, pitch = 0.0},
	&"trembita": {prefixes = ["music/trembita"], volume = 0.0, pitch = 0.0},
}

## Per-file correction, measured offline from each file's RMS and peak.
## The sources are found in different places by different people and
## arrive up to 23 dB apart — knock_loud sits at -14.7 RMS against
## knock_3's -37.6, so played flat one startles and the other is
## inaudible. Each value brings the file toward the family's level
## without pushing its peak past -0.5 dBFS.
##
## A stopgap, not a system: once the files are normalised on the way in,
## these can all go to zero and this table can be deleted.
const FILE_TRIM_DB := {
	"sfx/knock_1": 0.0,
	"sfx/knock_2": -2.0,
	"sfx/knock_3": 11.0,
	"sfx/knock_4": 8.5,
	"sfx/knock_5": -9.0,
	"sfx/door_open": 0.0,
	"sfx/door_close": -3.0, ## peaks at 0.0 dBFS, so it needs the headroom
	"sfx/floorboard_1": 6.0,
	"sfx/ingredient_drop_1": 0.0,
	"sfx/cauldron_loop": 6.0,
	"sfx/fire_loop": 10.0,
	"sfx/carve_loop": 4.0,
}

## Half-width of the random level wobble on every one-shot, in dB. Same
## purpose as `pitch` above.
const VOLUME_JITTER_DB := 1.5

var _streams: Dictionary = {} # StringName -> Array of {stream, trim}
var _last_variant: Dictionary = {} # StringName -> index last played
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

## Walks assets/audio/ once and remembers what is actually there,
## matching real filenames against the prefixes above. Doing it by
## directory listing rather than by load()-and-catch keeps a fresh
## checkout with no audio at all completely silent in the console.
func _index_sounds() -> void:
	var files := _list_audio_files()
	for key: StringName in SOUNDS:
		var found: Array = []
		for stem: String in files:
			for prefix: String in SOUNDS[key].prefixes:
				if stem.begins_with(prefix):
					var stream := load(files[stem]) as AudioStream
					if stream != null:
						found.append({stream = stream, trim = float(FILE_TRIM_DB.get(stem, 0.0))})
					break
		if not found.is_empty():
			found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return a.stream.resource_path < b.stream.resource_path)
			_streams[key] = found

## "sfx/knock_1" -> "res://assets/audio/sfx/knock_1.wav", for every
## playable file in the tree.
func _list_audio_files() -> Dictionary:
	var out := {}
	for folder: String in ["sfx", "ambience", "music"]:
		var dir := DirAccess.open(AUDIO_DIR + folder)
		if dir == null:
			continue
		for file_name: String in dir.get_files():
			# In an exported build the listing hands back the .import
			# stub rather than the source. Stripping it is not enough on
			# its own: a stub whose source has been deleted still loads
			# out of .godot/imported/, and silently shadowed the real
			# ambience here until it was caught.
			file_name = file_name.trim_suffix(".import")
			var extension := "." + file_name.get_extension()
			if extension not in EXTENSIONS:
				continue
			var path := "%s%s/%s" % [AUDIO_DIR, folder, file_name]
			if not ResourceLoader.exists(path):
				continue
			# Same stem in two formats: pick by EXTENSIONS order rather
			# than by whichever the directory happened to list last.
			var stem := "%s/%s" % [folder, file_name.get_basename()]
			if out.has(stem) and EXTENSIONS.find(extension) >= EXTENSIONS.find("." + String(out[stem]).get_extension()):
				continue
			out[stem] = path
	return out

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
	var variant := _take_variant(name)
	if variant.is_empty():
		return
	var config: Dictionary = SOUNDS[name]
	var player := _free_player()
	player.stream = variant.stream
	player.volume_db = volume_db + float(config.volume) + float(variant.trim) \
		+ randf_range(-VOLUME_JITTER_DB, VOLUME_JITTER_DB)
	player.pitch_scale = 1.0 + randf_range(-float(config.pitch), float(config.pitch))
	player.play()

## Picks a variant, avoiding the one played last whenever there is a
## choice. Pure randomness hands out the same knock twice in a row often
## enough to notice, and two identical knocks back to back is exactly
## the moment the illusion breaks.
func _take_variant(name: StringName) -> Dictionary:
	if not _streams.has(name):
		return {}
	var variants: Array = _streams[name]
	if variants.size() == 1:
		return variants[0]
	var index := randi() % variants.size()
	if index == _last_variant.get(name, -1):
		index = (index + 1) % variants.size()
	_last_variant[name] = index
	return variants[index]

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
	player.stream = _looped(_streams[name][0].stream)
	player.volume_db = volume_db + float(SOUNDS[name].volume) + float(_streams[name][0].trim)
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
	_music.stream = _streams[name][0].stream
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

	incoming.stream = _looped(_streams[name][0].stream)
	incoming.volume_db = -40.0
	incoming.play()
	var tween := create_tween().set_parallel(true)
	var target: float = float(SOUNDS[name].volume) + float(_streams[name][0].trim)
	tween.tween_property(incoming, "volume_db", target, AMBIENCE_FADE)
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
