extends Control

func _ready() -> void:
	var d := Directory.new()
	var mb := $MenuButton as MenuButton
	var p := mb.get_popup()
	var args := OS.get_cmdline_args()
	var video := ''
	for a in args:
		if a.begins_with('--video='):
			video = a.replace('--video=', '')
	if d.open('res://test_samples') == OK:
		d.list_dir_begin(true)
		var file_name = d.get_next()
		var extensions = ResourceLoader.get_recognized_extensions_for_type('VideoStreamGDNative')
		print('scanning for videos with these extensions: %s' % [extensions])
		while file_name != '':
			var ext = file_name.get_extension()

			if ext in extensions:
				p.add_item(file_name)
			file_name = d.get_next()
	if video:
		_open(video)
	elif p.get_item_count():
		_open(p.get_item_text(p.get_item_count() - 1))
	var err = p.connect('index_pressed', self, '_on_menubutton_index_pressed')
	assert(err == OK)

func _on_menubutton_index_pressed(index: int):
	_open($MenuButton.get_popup().get_item_text(index))

func _open(file):
	file = 'res://test_samples/%s' % [file]
	var stream = VideoStreamGDNative.new()
	print(file)
	stream.set_file(file)
	var vp = $VideoPlayer
	vp.stream = stream
	var sp = vp.stream_position
	# hack: to get the stream length, set the position to a negative number
	# the plugin will set the position to the end of the stream instead.
	vp.stream_position = -1
	var duration = vp.stream_position
	$ProgressBar.max_value = duration
	vp.stream_position = sp
	vp.play()

func _on_VideoPlayer_finished():
	get_tree().quit()

func _process(delta: float) -> void:
	var pos = $VideoPlayer.stream_position
	$ProgressBar.value = pos
	$ProgressBar/Label.text = '%.f / %.f seconds' % [pos, $ProgressBar.max_value]
