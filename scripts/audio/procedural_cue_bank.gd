extends RefCounted
class_name ProceduralCueBank

const SAMPLE_RATE := 22050

const CUE_PROFILES := {
	"ui_confirm": {"bus": "UI", "functional_priority": 0.35, "industrial_weight": false, "ducks_music": false},
	"ui_back": {"bus": "UI", "functional_priority": 0.35, "industrial_weight": false, "ducks_music": false},
	"pause": {"bus": "UI", "functional_priority": 0.45, "industrial_weight": false, "ducks_music": false},
	"resume": {"bus": "UI", "functional_priority": 0.45, "industrial_weight": false, "ducks_music": false},
	"impact_medium": {"bus": "SFX", "functional_priority": 0.72, "industrial_weight": true, "ducks_music": true},
	"impact_heavy": {"bus": "SFX", "functional_priority": 0.92, "industrial_weight": true, "ducks_music": true},
	"part_destroyed": {"bus": "SFX", "functional_priority": 0.9, "industrial_weight": true, "ducks_music": true},
	"part_recovered": {"bus": "SFX", "functional_priority": 0.78, "industrial_weight": true, "ducks_music": true},
	"part_denied": {"bus": "SFX", "functional_priority": 0.86, "industrial_weight": true, "ducks_music": true},
	"robot_disabled": {"bus": "SFX", "functional_priority": 0.9, "industrial_weight": true, "ducks_music": true},
	"robot_exploded": {"bus": "SFX", "functional_priority": 0.95, "industrial_weight": true, "ducks_music": true},
	"pickup_taken": {"bus": "SFX", "functional_priority": 0.74, "industrial_weight": true, "ducks_music": true},
	"round_start": {"bus": "SFX", "functional_priority": 0.7, "industrial_weight": true, "ducks_music": true},
	"round_unlock": {"bus": "SFX", "functional_priority": 0.7, "industrial_weight": true, "ducks_music": true},
	"pressure_warning": {"bus": "SFX", "functional_priority": 0.88, "industrial_weight": true, "ducks_music": true},
	"round_close": {"bus": "SFX", "functional_priority": 0.82, "industrial_weight": true, "ducks_music": true},
	"match_close": {"bus": "SFX", "functional_priority": 0.88, "industrial_weight": true, "ducks_music": true},
}

var _cue_streams: Dictionary = {}
var _music_streams: Dictionary = {}


func get_bus_for_cue(cue_id: String) -> String:
	var profile: Dictionary = CUE_PROFILES.get(cue_id, {})
	return str(profile.get("bus", "SFX"))


func get_available_cue_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for cue_id in CUE_PROFILES.keys():
		ids.append(String(cue_id))
	ids.sort()
	return ids


func get_cue_profile(cue_id: String) -> Dictionary:
	var profile: Dictionary = CUE_PROFILES.get(cue_id, {})
	return profile.duplicate(true)


func get_cue_stream(cue_id: String) -> AudioStreamWAV:
	if not _cue_streams.has(cue_id):
		_cue_streams[cue_id] = _build_cue_stream(cue_id)
	return _cue_streams.get(cue_id) as AudioStreamWAV


func get_music_stream(state_name: String) -> AudioStreamWAV:
	if not _music_streams.has(state_name):
		_music_streams[state_name] = _build_music_stream(state_name)
	return _music_streams.get(state_name) as AudioStreamWAV


func _build_cue_stream(cue_id: String) -> AudioStreamWAV:
	match cue_id:
		"ui_confirm":
			return _make_stream(_build_tone(0.08, [760.0, 980.0], 0.18, "sine", 0.008, 0.05))
		"ui_back":
			return _make_stream(_build_tone(0.09, [540.0, 410.0], 0.16, "triangle", 0.008, 0.05))
		"pause":
			return _make_stream(_build_tone(0.12, [260.0, 220.0], 0.18, "square", 0.01, 0.07))
		"resume":
			return _make_stream(_build_tone(0.11, [220.0, 330.0], 0.16, "triangle", 0.008, 0.06))
		"impact_medium":
			return _make_stream(_build_tone(0.14, [92.0, 130.0], 0.24, "triangle", 0.004, 0.08, 0.14))
		"impact_heavy":
			return _make_stream(_build_tone(0.18, [74.0, 110.0], 0.3, "square", 0.004, 0.11, 0.22))
		"part_destroyed":
			return _make_stream(_build_tone(0.16, [180.0, 120.0, 92.0], 0.24, "saw", 0.003, 0.1, 0.2))
		"part_recovered":
			return _make_stream(_build_tone(0.16, [320.0, 420.0, 540.0], 0.18, "triangle", 0.006, 0.09, 0.08))
		"part_denied":
			return _make_stream(_build_tone(0.18, [160.0, 118.0, 86.0], 0.23, "saw", 0.004, 0.11, 0.16))
		"robot_disabled":
			return _make_stream(_build_tone(0.22, [110.0, 82.0, 68.0], 0.26, "square", 0.004, 0.14, 0.2))
		"robot_exploded":
			return _make_stream(_build_tone(0.36, [78.0, 104.0, 156.0, 62.0], 0.32, "saw", 0.002, 0.22, 0.28))
		"pickup_taken":
			return _make_stream(_build_tone(0.15, [480.0, 620.0, 820.0], 0.18, "sine", 0.01, 0.08))
		"round_start":
			return _make_stream(_build_tone(0.2, [220.0, 330.0, 440.0], 0.18, "triangle", 0.01, 0.12))
		"round_unlock":
			return _make_stream(_build_tone(0.13, [360.0, 520.0, 720.0], 0.18, "sine", 0.005, 0.08))
		"pressure_warning":
			return _make_stream(_build_tone(0.22, [200.0, 180.0], 0.22, "square", 0.01, 0.12))
		"round_close":
			return _make_stream(_build_tone(0.24, [180.0, 260.0, 320.0], 0.18, "triangle", 0.01, 0.14))
		"match_close":
			return _make_stream(_build_tone(0.34, [220.0, 330.0, 440.0, 550.0], 0.22, "sine", 0.01, 0.2))
		_:
			return _make_stream(_build_tone(0.1, [440.0], 0.12, "sine", 0.01, 0.06))


func _build_music_stream(state_name: String) -> AudioStreamWAV:
	match state_name:
		"shell":
			return _make_stream(_build_tone(1.4, [110.0, 164.0, 220.0], 0.07, "sine", 0.08, 0.22, 0.04))
		"match_intro":
			return _make_stream(_build_tone(1.2, [92.0, 140.0, 196.0], 0.08, "triangle", 0.06, 0.18, 0.06))
		"match_live":
			return _make_stream(_build_tone(1.3, [118.0, 176.0, 236.0], 0.08, "saw", 0.04, 0.18, 0.05))
		"final_pressure":
			return _make_stream(_build_tone(1.1, [140.0, 210.0, 280.0], 0.09, "square", 0.03, 0.15, 0.08))
		"pause":
			return _make_stream(_build_tone(1.0, [82.0, 123.0], 0.06, "sine", 0.04, 0.16, 0.03))
		"results":
			return _make_stream(_build_tone(1.5, [164.0, 246.0, 328.0], 0.08, "triangle", 0.06, 0.2, 0.03))
		_:
			return _make_stream(_build_tone(1.0, [110.0], 0.05, "sine", 0.04, 0.14))


func _build_tone(
	duration: float,
	frequencies: Array,
	volume: float,
	waveform: String,
	attack: float,
	release: float,
	detune: float = 0.0
) -> PackedFloat32Array:
	var sample_count := maxi(int(duration * SAMPLE_RATE), 1)
	var samples := PackedFloat32Array()
	samples.resize(sample_count)
	var safe_attack := maxf(attack, 0.001)
	var safe_release := maxf(release, 0.001)
	var safe_duration := maxf(duration, 0.001)
	for index in range(sample_count):
		var t := float(index) / float(SAMPLE_RATE)
		var envelope := minf(t / safe_attack, 1.0) * minf((safe_duration - t) / safe_release, 1.0)
		envelope = clampf(envelope, 0.0, 1.0)
		var sample_value := 0.0
		for freq_index in range(frequencies.size()):
			var frequency := float(frequencies[freq_index]) + detune * freq_index
			var phase := TAU * frequency * t
			match waveform:
				"square":
					sample_value += 1.0 if sin(phase) >= 0.0 else -1.0
				"triangle":
					sample_value += asin(sin(phase)) * (2.0 / PI)
				"saw":
					sample_value += (2.0 * (phase / TAU - floor(0.5 + phase / TAU)))
				_:
					sample_value += sin(phase)
		sample_value /= maxf(float(frequencies.size()), 1.0)
		samples[index] = sample_value * envelope * volume
	return samples


func _make_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = _encode_samples(samples)
	return stream


func _encode_samples(samples: PackedFloat32Array) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for index in range(samples.size()):
		var clamped := clampf(samples[index], -1.0, 1.0)
		var sample_int := int(round(clamped * 32767.0))
		if sample_int < 0:
			sample_int = 65536 + sample_int
		bytes[index * 2] = sample_int & 0xFF
		bytes[index * 2 + 1] = (sample_int >> 8) & 0xFF
	return bytes
