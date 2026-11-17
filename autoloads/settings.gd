extends Node

## Persisted player settings: audio mix, window mode, resolution, language.
##
## Values live in user://settings.cfg so they survive restarts. Everything here
## is safe to call before the first frame - the display part is deferred until
## the window actually exists.

signal audio_changed
signal display_changed

const PATH := "user://settings.cfg"
const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"

enum WindowMode { WINDOWED, BORDERLESS, FULLSCREEN }

const MODES: Array[int] = [WindowMode.WINDOWED, WindowMode.BORDERLESS, WindowMode.FULLSCREEN]
const MODE_LABELS := {
	WindowMode.WINDOWED: "WINDOWED",
	WindowMode.BORDERLESS: "BORDERLESS",
	WindowMode.FULLSCREEN: "FULLSCREEN",
}

## Common 16:9 and 16:10 sizes, smallest first. 1280x720 is the design size.
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

var master_volume: float = 0.9
var music_volume: float = 0.6
var sfx_volume: float = 0.85
var window_mode: int = WindowMode.WINDOWED
var resolution: Vector2i = Vector2i(1280, 720)
var language: String = "en"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	load_settings()
	apply_audio()
	call_deferred("apply_display")


func saved_language() -> String:
	return language


# ---------------------------------------------------------------- audio

func _ensure_buses() -> void:
	for bus_name in [BUS_MUSIC, BUS_SFX]:
		if AudioServer.get_bus_index(bus_name) != -1:
			continue
		AudioServer.add_bus()
		var idx: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, BUS_MASTER)


func apply_audio() -> void:
	_set_bus_volume(BUS_MASTER, master_volume)
	_set_bus_volume(BUS_MUSIC, music_volume)
	_set_bus_volume(BUS_SFX, sfx_volume)
	audio_changed.emit()


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	var value: float = clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_mute(idx, value <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(value, 0.001)))


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	apply_audio()
	save_settings()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	apply_audio()
	save_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	apply_audio()
	save_settings()


# ---------------------------------------------------------------- display

func apply_display() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mode: int = DisplayServer.WindowMode.WINDOW_MODE_WINDOWED
	match window_mode:
		WindowMode.BORDERLESS:
			mode = DisplayServer.WINDOW_MODE_FULLSCREEN
		WindowMode.FULLSCREEN:
			mode = DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	DisplayServer.window_set_mode(mode)
	if window_mode == WindowMode.WINDOWED:
		DisplayServer.window_set_size(resolution)
		_center_window()
	display_changed.emit()


func _center_window() -> void:
	var screen: int = DisplayServer.window_get_current_screen()
	var usable: Vector2i = DisplayServer.screen_get_usable_rect(screen).size
	var pos: Vector2i = DisplayServer.screen_get_position(screen)
	pos += (usable - resolution) / 2
	DisplayServer.window_set_position(pos)


func set_window_mode(value: int) -> void:
	window_mode = clampi(value, 0, 2)
	apply_display()
	save_settings()


func set_resolution(value: Vector2i) -> void:
	for res in RESOLUTIONS:
		if res == value:
			resolution = value
			apply_display()
			save_settings()
			return


func set_language(code: String) -> void:
	if not Loc.LANGS.has(code):
		code = "en"
	language = code
	Loc.set_language(code)
	save_settings()


# ---------------------------------------------------------------- persistence

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	master_volume = float(cfg.get_value("audio", "master", master_volume))
	music_volume = float(cfg.get_value("audio", "music", music_volume))
	sfx_volume = float(cfg.get_value("audio", "sfx", sfx_volume))
	window_mode = int(cfg.get_value("video", "window_mode", window_mode))
	resolution = cfg.get_value("video", "resolution", resolution)
	language = String(cfg.get_value("misc", "language", language))
	if Loc.language != language:
		Loc.set_language(language)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("video", "window_mode", window_mode)
	cfg.set_value("video", "resolution", resolution)
	cfg.set_value("misc", "language", language)
	cfg.save(PATH)
