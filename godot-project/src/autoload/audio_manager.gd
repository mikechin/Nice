## AudioManager — Handles SFX and music playback.
## Manages audio pools for overlapping sounds.
class_name AudioManagerClass
extends Node

const MAX_SFX_PLAYERS := 8
const MUSIC_FADE_TIME := 0.5

var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _sfx_bus_idx: int = -1
var _music_bus_idx: int = -1
var _sfx_cache: Dictionary = {}  # name -> AudioStream

var sfx_volume: float = 1.0
var music_volume: float = 0.7
var sfx_enabled: bool = true
var music_enabled: bool = true


func _ready() -> void:
	# Create audio stream players for SFX pooling
	for i in MAX_SFX_PLAYERS:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
		add_child(player)
		_sfx_players.append(player)

	# Create music player
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music" if AudioServer.get_bus_index("Music") >= 0 else "Master"
	add_child(_music_player)

	_sfx_bus_idx = AudioServer.get_bus_index("SFX") if AudioServer.get_bus_index("SFX") >= 0 else 0
	_music_bus_idx = AudioServer.get_bus_index("Music") if AudioServer.get_bus_index("Music") >= 0 else 0


func play_sfx(sfx_name: String) -> void:
	if not sfx_enabled:
		return
	var stream := _get_or_load_sfx(sfx_name)
	if stream == null:
		return
	var player := _get_free_sfx_player()
	if player == null:
		return
	player.stream = stream
	player.volume_db = linear_to_db(sfx_volume)
	player.play()


func play_correct() -> void:
	play_sfx("correct")


func play_wrong() -> void:
	play_sfx("wrong")


func play_combo_milestone(milestone: int) -> void:
	# Escalating pitch for higher combos
	var pitch_scale := 1.0 + (float(milestone) / 100.0) * 0.5
	var stream := _get_or_load_sfx("combo")
	if stream == null:
		return
	var player := _get_free_sfx_player()
	if player == null:
		return
	player.stream = stream
	player.pitch_scale = pitch_scale
	player.volume_db = linear_to_db(sfx_volume)
	player.play()


func play_radical_activation() -> void:
	play_sfx("radical_activate")


func play_srs_rare_reveal() -> void:
	play_sfx("rare_reveal")


func play_purchase() -> void:
	play_sfx("purchase")


func play_card_flip() -> void:
	play_sfx("card_flip")


func play_tier_promotion() -> void:
	play_sfx("tier_promotion")


func play_music(track_name: String) -> void:
	if not music_enabled:
		return
	var path := "res://assets/audio/music/%s.ogg" % track_name
	if not ResourceLoader.exists(path):
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	_music_player.stream = stream
	_music_player.volume_db = linear_to_db(music_volume)
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()


func set_music_volume(volume: float) -> void:
	music_volume = clampf(volume, 0.0, 1.0)
	if _music_player and _music_player.playing:
		_music_player.volume_db = linear_to_db(music_volume)


func set_sfx_volume(volume: float) -> void:
	sfx_volume = clampf(volume, 0.0, 1.0)


func _get_or_load_sfx(sfx_name: String) -> AudioStream:
	if sfx_name in _sfx_cache:
		return _sfx_cache[sfx_name]
	var path := "res://assets/audio/sfx/%s.ogg" % sfx_name
	if not ResourceLoader.exists(path):
		# Try wav
		path = "res://assets/audio/sfx/%s.wav" % sfx_name
		if not ResourceLoader.exists(path):
			return null
	var stream := load(path) as AudioStream
	if stream:
		_sfx_cache[sfx_name] = stream
	return stream


func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			player.pitch_scale = 1.0
			return player
	# All busy — steal the first one
	_sfx_players[0].stop()
	_sfx_players[0].pitch_scale = 1.0
	return _sfx_players[0]
