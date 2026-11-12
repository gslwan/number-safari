extends Node
## Autoload: all sounds are synthesized at startup, so there are no audio files.

const RATE := 22050

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_streams["good"] = _tones([[880.0, 0.0, 0.10], [1318.5, 0.07, 0.16]], 0.45, 0.45)
	_streams["step"] = _tones([[420.0, 0.0, 0.03]], 0.08, 0.35)
	_streams["star"] = _tones([[1568.0, 0.0, 0.12], [2093.0, 0.05, 0.14]], 0.4, 0.35)
	_streams["click"] = _tones([[660.0, 0.0, 0.04]], 0.1, 0.35)
	_streams["win"] = _tones([
		[523.25, 0.0, 0.14], [659.25, 0.12, 0.14], [783.99, 0.24, 0.14], [1046.5, 0.36, 0.16],
		[523.25, 0.54, 0.4], [659.25, 0.54, 0.4], [783.99, 0.54, 0.4], [1046.5, 0.54, 0.4],
	], 1.8, 0.22)
	_streams["bad"] = _buzz()


func play(sound: String, pitch := 1.0, volume_db := 0.0) -> void:
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[sound]
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


## notes: [frequency, start time, decay time]. Bell-like tones that ring out.
func _tones(notes: Array, length: float, gain: float) -> AudioStreamWAV:
	var n := int(length * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for note in notes:
		var freq: float = note[0]
		var start := int(float(note[1]) * RATE)
		var decay: float = note[2]
		var count := mini(int(decay * 4.0 * RATE), n - start)
		for i in count:
			var t := float(i) / RATE
			var env := minf(t / 0.004, 1.0) * exp(-t / decay * 1.6)
			var ph := TAU * freq * t
			buf[start + i] += (sin(ph) + 0.35 * sin(2.0 * ph) + 0.15 * sin(3.0 * ph)) * env * gain
	return _wav(buf)


## A sagging, wobbly "bleh" for wrong answers.
func _buzz() -> AudioStreamWAV:
	var length := 0.5
	var n := int(length * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := t / length
		var freq := lerpf(230.0, 85.0, k) * (1.0 + 0.04 * sin(TAU * 18.0 * t))
		ph += freq / RATE
		var saw := 2.0 * fposmod(ph, 1.0) - 1.0
		var sq := 1.0 if fposmod(ph * 0.5, 1.0) < 0.5 else -1.0
		var env := minf(t / 0.01, 1.0) * (1.0 - k)
		buf[i] = (saw * 0.6 + sq * 0.4) * env * 0.3
	return _wav(buf)


func _wav(buf: PackedFloat32Array) -> AudioStreamWAV:
	var n := buf.size()
	var fade := mini(300, n)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var v := buf[i]
		if i >= n - fade:
			v *= float(n - i) / fade
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav
