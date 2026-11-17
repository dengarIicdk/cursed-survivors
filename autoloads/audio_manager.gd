extends Node

## Pooled audio system: effects with per-sound throttling and pitch variation,
## plus two crossfading music players driven by EventBus signals.

const SFX_POOL_SIZE: int = 12
const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"

var sfx_volume: float = 0.8
var music_volume: float = 0.55

var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0
var _last_played: Dictionary = {}
var _music_ducked: bool = false

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _current_music_player: AudioStreamPlayer
var _current_track: String = ""
var _crossfade_tween: Tween = null

## Minimum seconds between two plays of the same effect (stops machine-gun spam).
const SFX_THROTTLE := {
	"hit": 0.05,
	"hit_heavy": 0.12,
	"orb_hit": 0.06,
	"lightning": 0.08,
	"enemy_die": 0.06,
	"xp_pickup": 0.035,
	"coin": 0.06,
	"gem_absorb": 0.05,
	"ui_hover": 0.05,
	"ui_click": 0.06,
}

const SFX_PITCH := {
	"hit": [0.92, 1.10],
	"hit_heavy": [0.9, 1.05],
	"orb_hit": [0.95, 1.12],
	"enemy_die": [0.88, 1.15],
	"xp_pickup": [0.95, 1.12],
	"coin": [1.0, 1.05],
}

var _sfx_map: Dictionary = {
	"hit": SFX_DIR + "hit.wav",
	"hit_heavy": SFX_DIR + "hit_heavy.wav",
	"orb_hit": SFX_DIR + "orb_hit.wav",
	"lightning": SFX_DIR + "lightning.wav",
	"xp_pickup": SFX_DIR + "xp_pickup.wav",
	"coin": SFX_DIR + "coin.wav",
	"heart": SFX_DIR + "heart.wav",
	"level_up": SFX_DIR + "level_up.wav",
	"weapon_evolve": SFX_DIR + "weapon_evolve.wav",
	"enemy_die": SFX_DIR + "enemy_die.wav",
	"boss_die": SFX_DIR + "boss_die.wav",
	"boss_spawn": SFX_DIR + "boss_spawn.wav",
	"player_die": SFX_DIR + "player_die.wav",
	"blink": SFX_DIR + "blink.wav",
	"surge": SFX_DIR + "surge.wav",
	"last_stand": SFX_DIR + "last_stand.wav",
	"run_start": SFX_DIR + "run_start.wav",
	"ui_click": SFX_DIR + "ui_click.wav",
	"ui_hover": SFX_DIR + "ui_hover.wav",
	"ui_denied": SFX_DIR + "ui_denied.wav",
	"gem_absorb": SFX_DIR + "gem_absorb.wav",
}

var _music_map: Dictionary = {
	"menu": MUSIC_DIR + "menu.wav",
	"graveyard_calm": MUSIC_DIR + "graveyard_calm.wav",
	"graveyard_intense": MUSIC_DIR + "graveyard_intense.wav",
	"depths_calm": MUSIC_DIR + "depths_calm.wav",
	"depths_intense": MUSIC_DIR + "depths_intense.wav",
	"boss": MUSIC_DIR + "boss.wav",
}

var _stream_cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_pool.append(player)

	_music_a = AudioStreamPlayer.new()
	_music_a.bus = "Music"
	_music_a.volume_db = linear_to_db(music_volume)
	add_child(_music_a)

	_music_b = AudioStreamPlayer.new()
	_music_b.bus = "Music"
	_music_b.volume_db = linear_to_db(0.0)
	add_child(_music_b)

	_current_music_player = _music_a

	EventBus.enemy_killed.connect(func(_e, _p): play_sfx("enemy_die"))
	EventBus.boss_spawned.connect(func(_n): play_sfx("boss_spawn"))
	EventBus.boss_killed.connect(func(_n): play_sfx("boss_die"))
	EventBus.player_damaged.connect(func(_a, _hp): play_sfx("hit_heavy"))
	EventBus.player_died.connect(func(): play_sfx("player_die"))
	EventBus.player_revived.connect(func(): play_sfx("heart"))
	EventBus.level_up.connect(func(_l): play_sfx("level_up"))
	EventBus.weapon_evolved.connect(func(_a, _b): play_sfx("weapon_evolve"))
	EventBus.run_started.connect(func(_c, _m): play_sfx("run_start"))
	EventBus.surge_triggered.connect(func(): play_sfx("surge"))
	EventBus.last_stand_activated.connect(func(): play_sfx("last_stand"))
	EventBus.player_blinked.connect(func(_a, _b): play_sfx("blink"))
	EventBus.item_picked.connect(func(_n): play_sfx("coin"))
	EventBus.soul_coins_earned.connect(func(_a): play_sfx("coin"))
	EventBus.game_paused.connect(func():
		play_sfx("ui_click")
		duck_music(true))
	EventBus.game_resumed.connect(func():
		play_sfx("ui_click")
		duck_music(false))


func _cache(path: String) -> AudioStream:
	if _stream_cache.has(path):
		return _stream_cache[path]
	if not ResourceLoader.exists(path):
		return null
	var stream: AudioStream = load(path)
	_stream_cache[path] = stream
	return stream


func play_sfx(sound_name: String, volume_scale: float = 1.0, pitch: float = 1.0) -> void:
	var path: String = _sfx_map.get(sound_name, "")
	if path.is_empty():
		return

	var now: float = Time.get_ticks_msec() / 1000.0
	var min_gap: float = SFX_THROTTLE.get(sound_name, 0.0)
	if min_gap > 0.0 and now - float(_last_played.get(sound_name, -100.0)) < min_gap:
		return
	_last_played[sound_name] = now

	var stream: AudioStream = _cache(path)
	if not stream:
		return

	var player := _sfx_pool[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % SFX_POOL_SIZE
	player.stream = stream
	player.volume_db = linear_to_db(clampf(sfx_volume * volume_scale, 0.001, 1.0))

	var pr: Array = SFX_PITCH.get(sound_name, [1.0, 1.0])
	var jitter: float = randf_range(float(pr[0]), float(pr[1]))
	player.pitch_scale = pitch * jitter
	player.play()


func _looped(stream: AudioStream) -> AudioStream:
	# Make sure generated WAV loops wrap seamlessly, whatever the import did.
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		if wav.loop_mode != AudioStreamWAV.LOOP_FORWARD:
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			wav.loop_end = int(wav.get_length() * wav.mix_rate)
	return stream


func play_music(track: String) -> void:
	var path: String = _music_map.get(track, "")
	if path.is_empty() or track == _current_track:
		return
	var stream: AudioStream = _cache(path)
	if not stream:
		return
	_current_track = track
	_current_music_player.stream = _looped(stream)
	_current_music_player.volume_db = linear_to_db(music_volume * (0.6 if _music_ducked else 1.0))
	_current_music_player.play()


func crossfade_music(to_track: String, duration: float = 2.5) -> void:
	var path: String = _music_map.get(to_track, "")
	if path.is_empty() or to_track == _current_track:
		return
	var stream: AudioStream = _cache(path)
	if not stream:
		return

	var old_player: AudioStreamPlayer = _current_music_player
	var next_player: AudioStreamPlayer = _music_b if _current_music_player == _music_a else _music_a
	next_player.stream = _looped(stream)
	next_player.volume_db = -60.0
	next_player.play()

	var target_db: float = linear_to_db(music_volume * (0.6 if _music_ducked else 1.0))
	if _crossfade_tween and _crossfade_tween.is_valid():
		_crossfade_tween.kill()
	_crossfade_tween = create_tween()
	_crossfade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_crossfade_tween.set_parallel(true)
	_crossfade_tween.tween_property(old_player, "volume_db", -60.0, duration)
	_crossfade_tween.tween_property(next_player, "volume_db", target_db, duration)
	_crossfade_tween.set_parallel(false)
	_crossfade_tween.tween_callback(old_player.stop)

	_current_music_player = next_player
	_current_track = to_track


func duck_music(on: bool, amount: float = 0.6) -> void:
	if _music_ducked == on:
		return
	_music_ducked = on
	var target: float = linear_to_db(music_volume * (amount if on else 1.0))
	var t := create_tween()
	# Music must be able to fade while the game tree itself is paused.
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(_current_music_player, "volume_db", target, 0.35)


func stop_music() -> void:
	_music_a.stop()
	_music_b.stop()
	_current_track = ""


func set_sfx_volume(vol: float) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)


func set_music_volume(vol: float) -> void:
	music_volume = clampf(vol, 0.0, 1.0)
	_current_music_player.volume_db = linear_to_db(music_volume)