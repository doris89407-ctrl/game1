extends Control

const BANK_ART := "res://assets/dream-bank.png"
const MARKET_ART := "res://assets/moon-market.png"
const QUIZ_ITEMS := [
	{
		"prompt": "如果手上的零用錢有限，哪個安排最能同時照顧需要和未來目標？",
		"choices": [
			"先買最想要的新玩具，其他事情以後再說。",
			"先安排每天需要的午餐，再留一部分儲蓄，最後才看有沒有錢買想要的東西。",
			"把全部零用錢都花掉，這樣就不用想怎麼分配。"
		],
		"answer": 1,
		"explain": "先分清需要和想要，安排必要支出，再儲蓄和留預備金。"
	},
	{
		"prompt": "如果想支持小店、但不知道哪家下個月生意更好，可以怎麼想？",
		"choices": [
			"全部放在最紅的店，因為紅就代表一定賺。",
			"分散選擇，保留急用的錢，並記得結果可能好也可能不好。",
			"只要認識店老闆，投入多少都不會有風險。"
		],
		"answer": 1,
		"explain": "分散選擇可以降低單一事件的影響，但投資仍有風險，沒有保證獲利。"
	}
]
const STAGES := [
	{
		"number": "01",
		"name": "星星銀行",
		"title": "先照顧需要，再留一點星星",
		"story": "夢門前有 10 顆星星。小夢魔需要一個書包（4 顆）和一份午餐（3 顆），也想買玩具（3 顆）。哪個安排最穩妥？",
		"hint": "先把每天需要的東西放進計畫，再為目標存一些，最後留一點預備金。想要的東西可以等一等。",
		"choices": [
			"買書包和午餐，再買玩具；今天全部用完。",
			"買書包和午餐，存下 2 顆，還留 1 顆應付臨時需要。",
			"把 10 顆都存起來，今天不吃午餐也不帶書包。"
		],
		"answer": 1,
		"success": "安排得很棒！先顧好需要，為目標儲蓄，也留一點預備金。玩具可以等下次有計畫時再買。"
	},
	{
		"number": "02",
		"name": "月光市集",
		"title": "把風險分散，別忘了預備金",
		"story": "你有 10 顆星星，其中 2 顆要留作緊急預備金。剩下 8 顆想支持兩家小店。哪種做法不會把希望全押在一處？",
		"hint": "每家小店的生意都可能變好或變差。分散選擇能降低單一事件帶來的影響，預備金也不拿去投資。",
		"choices": [
			"8 顆全放進最近最紅的店，再把預備金也加進去。",
			"兩家各放 4 顆，另外 2 顆保留；記得生意和價值仍可能變動。",
			"8 顆全放在第一家店，因為認識老闆就保證不會虧。"
		],
		"answer": 1,
		"success": "你沒有把星星全押在一家店，也保留了預備金。分散能減少單一變化的影響，但不能保證不會虧損。"
	}
]

const NIGHT := Color("#071317")
const PANEL := Color("#102328")
const GOLD := Color("#f4c86b")
const PAPER := Color("#f4f0e2")
const MUTED := Color("#c0ccc5")
const GOOD := Color("#9ed9ad")
const BAD := Color("#ffc3aa")

var game_font: Font
var background: TextureRect
var shade: ColorRect
var avatar_container: SubViewportContainer
var avatar_model: Node3D
var momo_portrait: TextureRect
var sound_button_ref: Button
var summary_copy_button: Button
var score_label: Label
var feedback_label: Label
var answer_buttons: Array[Button] = []
var current_screen := "home"
var current_stage := 0
var selected_choice := -1
var quiz_index := 0
var quiz_choice := -1
var quiz_buttons: Array[Button] = []
var pre_answers: Array[bool] = []
var post_answers: Array[bool] = []
var mistakes: Array[int] = [0, 0]
var hints_used: Array[bool] = [false, false]
var stage_scores: Array[int] = [0, 0]
var sound_enabled := false
var sound_player: AudioStreamPlayer


func _ready() -> void:
	game_font = load("res://assets/NotoSansTC-subset.ttf") as Font
	_build_background()
	_build_3d_avatar()
	_build_momo_portrait()
	sound_player = AudioStreamPlayer.new()
	add_child(sound_player)
	show_home()


func _process(_delta: float) -> void:
	if avatar_model == null or not avatar_container.visible:
		return
	var elapsed := float(Time.get_ticks_msec()) / 1000.0
	avatar_model.rotation.y = deg_to_rad(-5.0 + sin(elapsed * 1.2) * 5.0)
	avatar_model.position.y = 0.08 + sin(elapsed * 2.0) * 0.035


func _build_background() -> void:
	background = TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture = load(BANK_ART)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	shade = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.07, 0.08, 0.43)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)


func _build_3d_avatar() -> void:
	avatar_container = SubViewportContainer.new()
	avatar_container.name = "DreamSprite3D"
	avatar_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar_container.stretch = true
	avatar_container.anchor_left = 0.70
	avatar_container.anchor_top = 0.45
	avatar_container.anchor_right = 0.98
	avatar_container.anchor_bottom = 0.96
	avatar_container.offset_left = -20
	avatar_container.offset_right = 0
	avatar_container.offset_top = 0
	avatar_container.offset_bottom = 0
	add_child(avatar_container)
	var view := SubViewport.new()
	view.size = Vector2i(360, 440)
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view.own_world_3d = true
	avatar_container.add_child(view)
	var model := Node3D.new()
	model.name = "MomoBlenderModel"
	view.add_child(model)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.0
	camera.position = Vector3(0.0, 1.15, 5.4)
	model.add_child(camera)
	camera.look_at(Vector3(0.0, 1.02, 0.0))
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-24, -28, 0)
	key_light.light_color = Color("#ffe4a0")
	key_light.light_energy = 1.3
	model.add_child(key_light)
	var fill_light := OmniLight3D.new()
	fill_light.position = Vector3(-2, 2.3, 2.3)
	fill_light.light_color = Color("#68bfc0")
	fill_light.light_energy = 0.7
	fill_light.omni_range = 8
	model.add_child(fill_light)
	var model_scene := load("res://assets/momo.glb") as PackedScene
	avatar_model = model_scene.instantiate() as Node3D
	avatar_model.name = "MomoBlenderCharacter"
	avatar_model.position.y = 0.08
	model.add_child(avatar_model)


func _build_momo_portrait() -> void:
	momo_portrait = TextureRect.new()
	momo_portrait.name = "MomoPortraitArt"
	momo_portrait.texture = load("res://assets/momo-cutout.png")
	momo_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	momo_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	momo_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	momo_portrait.anchor_left = 0.68
	momo_portrait.anchor_top = 0.19
	momo_portrait.anchor_right = 0.98
	momo_portrait.anchor_bottom = 0.95
	momo_portrait.modulate = Color(1.08, 1.04, 0.92, 1)
	add_child(momo_portrait)


func _clear_ui() -> void:
	for child in get_children():
		if child != background and child != shade and child != avatar_container and child != momo_portrait and child != sound_player:
			remove_child(child)
			child.queue_free()


func _set_art(path: String, dark: float = 0.50) -> void:
	background.texture = load(path)
	shade.color = Color(0.02, 0.07, 0.08, dark)


func _base_header(show_home_button: bool = false) -> void:
	var header := HBoxContainer.new()
	header.anchor_right = 1.0
	header.offset_left = 34
	header.offset_top = 24
	header.offset_right = -34
	header.offset_bottom = 77
	header.add_theme_constant_override("separation", 14)
	add_child(header)
	var brand := _label("✦  小小夢魔", 17, PAPER, true)
	brand.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(brand)
	var subtitle := _label("星星存錢夢", 12, MUTED)
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(subtitle)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	if show_home_button:
		var home_button := _button("回到夢境", false)
		home_button.pressed.connect(show_home)
		header.add_child(home_button)
	sound_button_ref = _button("音效：" + ("開" if sound_enabled else "關"), false)
	sound_button_ref.pressed.connect(_toggle_sound)
	header.add_child(sound_button_ref)


func _label(text: String, size: int = 16, color: Color = PAPER, bold: bool = false) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	if game_font != null:
		result.add_theme_font_override("font", game_font)
	if bold:
		result.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.35))
		result.add_theme_constant_override("outline_size", 1)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return result


func _button(text: String, primary: bool = true) -> Button:
	var result := Button.new()
	result.text = text
	result.focus_mode = Control.FOCUS_ALL
	result.custom_minimum_size = Vector2(0, 46)
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.add_theme_font_size_override("font_size", 15)
	if game_font != null:
		result.add_theme_font_override("font", game_font)
	var normal := StyleBoxFlat.new()
	normal.bg_color = GOLD if primary else Color(0.11, 0.17, 0.18, 0.94)
	normal.border_color = GOLD if primary else Color(0.72, 0.79, 0.75, 0.45)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(9)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#ffdc91") if primary else Color("#19353a")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#d7a949") if primary else Color("#0b1719")
	result.add_theme_stylebox_override("normal", normal)
	result.add_theme_stylebox_override("hover", hover)
	result.add_theme_stylebox_override("pressed", pressed)
	result.add_theme_stylebox_override("focus", hover)
	result.add_theme_color_override("font_color", Color("#291d0b") if primary else PAPER)
	result.add_theme_color_override("font_hover_color", Color("#291d0b") if primary else PAPER)
	result.add_theme_color_override("font_pressed_color", Color("#291d0b") if primary else PAPER)
	return result


func _panel(left: float, top: float, right: float, bottom: float) -> VBoxContainer:
	var card := PanelContainer.new()
	card.anchor_left = left
	card.anchor_top = top
	card.anchor_right = right
	card.anchor_bottom = bottom
	card.offset_left = 0
	card.offset_top = 0
	card.offset_right = 0
	card.offset_bottom = 0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.085, 0.095, 0.94)
	style.border_color = Color(0.96, 0.78, 0.42, 0.43)
	style.set_border_width_all(1)
	style.set_corner_radius_all(15)
	style.shadow_color = Color(0, 0, 0, 0.42)
	style.shadow_size = 20
	card.add_theme_stylebox_override("panel", style)
	add_child(card)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 23)
	margin.add_theme_constant_override("margin_right", 23)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	return column


func _spacer(height: int = 0) -> Control:
	var result := Control.new()
	result.custom_minimum_size.y = height
	result.size_flags_vertical = Control.SIZE_EXPAND_FILL if height == 0 else Control.SIZE_SHRINK_CENTER
	return result


func show_home() -> void:
	current_screen = "home"
	_clear_ui()
	_set_art(BANK_ART, 0.52)
	avatar_container.visible = false
	momo_portrait.visible = true
	avatar_container.anchor_left = 0.68
	avatar_container.anchor_top = 0.39
	avatar_container.anchor_right = 0.98
	avatar_container.anchor_bottom = 0.91
	_base_header()
	var compact := get_viewport_rect().size.x < 760.0
	var panel := _panel(0.055 if not compact else 0.035, 0.20 if not compact else 0.28, 0.53 if not compact else 0.965, 0.87 if not compact else 0.91)
	panel.add_child(_label("一場關於選擇與勇氣的夢", 12, GOLD, true))
	var title := _label("小小夢魔\n星星存錢夢", 37 if not compact else 29, PAPER, true)
	title.custom_minimum_size.y = 96 if not compact else 82
	panel.add_child(title)
	panel.add_child(_label("午夜鐘聲響起，星星銀行的大門悄悄鎖上了。陪著披黃斗篷的小夢魔，找回兩把星星鑰匙。", 16, MUTED))
	var tags := _label("2 段夢境　・　2 個互動挑戰　・　1 份成長紀錄", 12, Color("#e4d3a8"))
	tags.custom_minimum_size.y = 26
	panel.add_child(tags)
	panel.add_child(_spacer(6))
	var start := _button("走進夢境　✦")
	start.pressed.connect(_start_warmup)
	panel.add_child(start)
	panel.add_child(_label("遊戲星星是虛構教學點數。真實投資可能有損失。", 11, MUTED))
	var footer := _label("使用滑鼠、觸控，或鍵盤 1–3 遊玩", 11, Color("#ecdfc1"))
	footer.anchor_left = 0.06
	footer.anchor_top = 0.94
	footer.anchor_right = 0.9
	footer.anchor_bottom = 0.995
	add_child(footer)


func _start_warmup() -> void:
	pre_answers.clear()
	post_answers.clear()
	mistakes = [0, 0]
	hints_used = [false, false]
	stage_scores = [0, 0]
	quiz_index = 0
	quiz_choice = -1
	_render_quiz(false)


func _render_quiz(review: bool) -> void:
	current_screen = "review" if review else "warmup"
	_clear_ui()
	_set_art(MARKET_ART if review else BANK_ART, 0.69)
	avatar_container.visible = false
	momo_portrait.visible = false
	_base_header()
	var compact := get_viewport_rect().size.x < 760.0
	var panel := _panel(0.22 if not compact else 0.035, 0.15 if not compact else 0.16, 0.78 if not compact else 0.965, 0.88 if not compact else 0.92)
	panel.add_child(_label("冒險後的小回顧" if review else "出發前的小暖身", 12, GOLD, true))
	panel.add_child(_label("再回答一次，看看你的新想法" if review else "先看看你已經知道多少", 27 if not compact else 22, PAPER, true))
	panel.add_child(_label("這不是考試。" + ("想一想剛才學到的線索，選出你現在認為最好的做法。" if review else "答錯也沒關係，完成兩關後會再回答相同的問題，看看自己多學會了什麼。"), 13, MUTED))
	var progress := _label(("●　" if quiz_index == 0 else "✦　") + ("●" if quiz_index == 1 else "○") + "　　題目 %d / 2" % (quiz_index + 1), 12, Color("#ecd69a"))
	panel.add_child(progress)
	var item: Dictionary = QUIZ_ITEMS[quiz_index]
	panel.add_child(_label(str(item["prompt"]), 17, PAPER, true))
	quiz_buttons.clear()
	for index in range((item["choices"] as Array).size()):
		var option := _button("%s　%s" % [String.chr(65 + index), item["choices"][index]], false)
		option.custom_minimum_size.y = 58 if not compact else 53
		option.pressed.connect(_select_quiz_answer.bind(index, review))
		panel.add_child(option)
		quiz_buttons.append(option)
	feedback_label = _label("", 12, MUTED)
	feedback_label.custom_minimum_size.y = 33
	panel.add_child(feedback_label)
	var next := _button("繼續", true)
	next.disabled = true
	next.pressed.connect(_advance_quiz.bind(review))
	panel.add_child(next)
	panel.add_child(_label("選一個最接近你想法的答案，再按「繼續」。", 10, MUTED))


func _select_quiz_answer(index: int, review: bool) -> void:
	if quiz_choice >= 0:
		return
	quiz_choice = index
	var item: Dictionary = QUIZ_ITEMS[quiz_index]
	var correct := index == int(item["answer"])
	if review:
		post_answers.append(correct)
		feedback_label.text = ("答對了！" if correct else "這次沒有選中最合適的做法。") + str(item["explain"])
		feedback_label.add_theme_color_override("font_color", GOOD if correct else BAD)
	else:
		pre_answers.append(correct)
		feedback_label.text = "已記下你的想法。完成夢境後會再回答一次，看看新學到什麼。"
	for button_index in range(quiz_buttons.size()):
		quiz_buttons[button_index].disabled = true
	var column := feedback_label.get_parent() as VBoxContainer
	var next_button := column.get_child(column.get_child_count() - 2) as Button
	next_button.disabled = false
	_play_tone(660 if correct else 230)


func _advance_quiz(review: bool) -> void:
	if quiz_index < QUIZ_ITEMS.size() - 1:
		quiz_index += 1
		quiz_choice = -1
		_render_quiz(review)
		return
	if review:
		_show_summary()
	else:
		_show_stage(0)


func _show_stage(index: int) -> void:
	current_screen = "game"
	current_stage = index
	selected_choice = -1
	_clear_ui()
	_set_art(MARKET_ART if index == 1 else BANK_ART, 0.52)
	var compact := get_viewport_rect().size.x < 760.0
	avatar_container.visible = true
	momo_portrait.visible = false
	avatar_container.anchor_left = 0.70 if not compact else 0.70
	avatar_container.anchor_top = 0.03 if compact else 0.39
	avatar_container.anchor_right = 0.98
	avatar_container.anchor_bottom = 0.30 if compact else 0.91
	_base_header(true)
	var stage: Dictionary = STAGES[index]
	var panel := _panel(0.055 if not compact else 0.035, 0.16 if not compact else 0.31, 0.51 if not compact else 0.965, 0.93 if not compact else 0.99)
	panel.add_child(_label("夢境 %s　・　互動單元 %d / 2" % [stage["number"], index + 1], 11, GOLD, true))
	panel.add_child(_label(str(stage["name"]), 23 if not compact else 21, PAPER, true))
	var score_row := HBoxContainer.new()
	score_row.add_child(_label("本關星星分數", 12, MUTED))
	var score_spacer := Control.new()
	score_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_row.add_child(score_spacer)
	score_label = _label("100", 21, GOLD, true)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_row.add_child(score_label)
	panel.add_child(score_row)
	panel.add_child(_label(str(stage["title"]), 18, PAPER, true))
	panel.add_child(_label(str(stage["story"]), 13, MUTED))
	answer_buttons.clear()
	for option_index in range((stage["choices"] as Array).size()):
		var answer := _button("%s　%s" % [String.chr(65 + option_index), stage["choices"][option_index]], false)
		answer.custom_minimum_size.y = 55 if not compact else 47
		answer.pressed.connect(_select_stage_answer.bind(option_index))
		panel.add_child(answer)
		answer_buttons.append(answer)
	feedback_label = _label("鑰匙還沒出現，再想一想。選好答案後按下確認。", 11, MUTED)
	feedback_label.custom_minimum_size.y = 32
	panel.add_child(feedback_label)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	var hint := _button("給我一點提示", false)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.pressed.connect(_use_hint)
	actions.add_child(hint)
	var submit := _button("確認選擇", true)
	submit.disabled = true
	submit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	submit.pressed.connect(_submit_stage_answer)
	actions.add_child(submit)
	panel.add_child(actions)
	var keys := _label("夢門鑰匙　%s　　 %s" % ["★" if index > 0 else "◇", "◇"], 13, Color("#e7cf91"))
	panel.add_child(keys)
	var hint_button := hint
	hint_button.set_meta("action_row", actions)
	var continue_button := _button("收下鑰匙，繼續前進", true)
	continue_button.visible = false
	continue_button.pressed.connect(_continue_from_stage)
	panel.add_child(continue_button)
	panel.set_meta("hint_button", hint)
	panel.set_meta("submit_button", submit)
	panel.set_meta("continue_button", continue_button)
	panel.set_meta("keys_label", keys)
	

func _select_stage_answer(index: int) -> void:
	selected_choice = index
	for option_index in range(answer_buttons.size()):
		answer_buttons[option_index].disabled = answer_buttons[option_index].has_meta("solved")
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color("#283c39") if option_index == index else Color(0.11, 0.17, 0.18, 0.94)
		normal_style.border_color = GOLD if option_index == index else Color(0.72, 0.79, 0.75, 0.45)
		normal_style.set_border_width_all(2 if option_index == index else 1)
		normal_style.set_corner_radius_all(9)
		normal_style.content_margin_left = 15
		normal_style.content_margin_right = 15
		normal_style.content_margin_top = 7
		normal_style.content_margin_bottom = 7
		answer_buttons[option_index].add_theme_stylebox_override("normal", normal_style)
	var panel := answer_buttons[0].get_parent() as VBoxContainer
	var submit: Button = panel.get_meta("submit_button")
	submit.disabled = false


func _use_hint() -> void:
	if hints_used[current_stage]:
		return
	hints_used[current_stage] = true
	var stage: Dictionary = STAGES[current_stage]
	feedback_label.text = "提示：" + str(stage["hint"]) + "（使用提示，本關最高 90 分。）"
	feedback_label.add_theme_color_override("font_color", Color("#ecd69a"))
	_update_stage_score()
	var panel := answer_buttons[0].get_parent() as VBoxContainer
	(panel.get_meta("hint_button") as Button).disabled = true
	_play_tone(460)


func _update_stage_score() -> int:
	var score := maxi(40, 100 - mistakes[current_stage] * 20 - (10 if hints_used[current_stage] else 0))
	if score_label != null and is_instance_valid(score_label):
		score_label.text = str(score)
	return score


func _submit_stage_answer() -> void:
	if selected_choice < 0:
		return
	var stage: Dictionary = STAGES[current_stage]
	var panel := answer_buttons[0].get_parent() as VBoxContainer
	if selected_choice != int(stage["answer"]):
		mistakes[current_stage] += 1
		var score := _update_stage_score()
		feedback_label.text = "這個安排還有一點可以再想想。本關目前 %d 分，試著找出需要和想要。" % score
		feedback_label.add_theme_color_override("font_color", BAD)
		_play_tone(220)
		return
	stage_scores[current_stage] = _update_stage_score()
	feedback_label.text = str(stage["success"])
	feedback_label.add_theme_color_override("font_color", GOOD)
	for answer in answer_buttons:
		answer.disabled = true
		answer.set_meta("solved", true)
	var hint: Button = panel.get_meta("hint_button")
	var submit: Button = panel.get_meta("submit_button")
	var continue_button: Button = panel.get_meta("continue_button")
	hint.visible = false
	submit.visible = false
	continue_button.visible = true
	continue_button.text = "收下鑰匙，" + ("前往月光市集" if current_stage == 0 else "看看成長成果")
	var keys: Label = panel.get_meta("keys_label")
	keys.text = "夢門鑰匙　★　　 %s" % ("◇" if current_stage == 0 else "★")
	_play_tone(720)


func _continue_from_stage() -> void:
	if current_stage == 0:
		_show_stage(1)
	else:
		quiz_index = 0
		quiz_choice = -1
		post_answers.clear()
		_render_quiz(true)


func _show_summary() -> void:
	current_screen = "summary"
	_clear_ui()
	_set_art(MARKET_ART, 0.66)
	avatar_container.visible = false
	momo_portrait.visible = false
	_base_header()
	var compact := get_viewport_rect().size.x < 760.0
	var panel := _panel(0.08 if not compact else 0.035, 0.15 if not compact else 0.12, 0.92 if not compact else 0.965, 0.91 if not compact else 0.94)
	panel.add_child(_label("夢境冒險完成", 12, GOLD, true))
	panel.add_child(_label("你讓星星有了方向。", 32 if not compact else 24, PAPER, true))
	panel.add_child(_label("兩把鑰匙都找到了！真正的寶藏，是你現在會多想一步。", 13, MUTED))
	var score_row := HBoxContainer.new()
	score_row.add_theme_constant_override("separation", 12)
	for index in range(2):
		var result := PanelContainer.new()
		result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color(1, 1, 1, 0.07)
		card_style.border_color = Color(1, 1, 1, 0.14)
		card_style.set_border_width_all(1)
		card_style.set_corner_radius_all(10)
		result.add_theme_stylebox_override("panel", card_style)
		var card_margin := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			card_margin.add_theme_constant_override("margin_" + side, 13 if not compact else 8)
		result.add_child(card_margin)
		var card_column := VBoxContainer.new()
		card_column.add_theme_constant_override("separation", 3)
		card_margin.add_child(card_column)
		card_column.add_child(_label("夢境 %d・%s" % [index + 1, STAGES[index]["name"]], 11, MUTED))
		card_column.add_child(_label("%d 分" % stage_scores[index], 28, GOLD, true))
		card_column.add_child(_label("先顧需要，再儲蓄。" if index == 0 else "分散風險，不保證獲利。", 10, PAPER))
		score_row.add_child(result)
	panel.add_child(score_row)
	var before := _quiz_accuracy(pre_answers)
	var after := _quiz_accuracy(post_answers)
	var progress := after - before
	var progress_card := _label("理財想法的進步　　暖身 %d%% → 回顧 %d%%　　%s%d 個百分點" % [before, after, "+" if progress > 0 else "", progress], 14, GOOD, true)
	progress_card.custom_minimum_size.y = 42
	panel.add_child(progress_card)
	panel.add_child(_label("帶著這三個問題回家：這是需要還是想要？結果不確定時，可以怎麼分散風險？我有留下一些錢應付臨時需要嗎？", 12, MUTED))
	panel.add_child(_label("虛構的理財學習遊戲，不構成投資建議。真實投資可能損失本金。", 10, MUTED))
	var again := _button("再做一次夢境")
	again.pressed.connect(_start_warmup)
	panel.add_child(again)
	summary_copy_button = _button("複製我的冒險成果", false)
	summary_copy_button.pressed.connect(_copy_result)
	panel.add_child(summary_copy_button)
	var config := ConfigFile.new()
	config.set_value("progress", "best_scores", stage_scores)
	config.set_value("progress", "warmup", before)
	config.set_value("progress", "review", after)
	config.save("user://little_dream_progress.cfg")


func _quiz_accuracy(answers: Array[bool]) -> int:
	if answers.is_empty():
		return 0
	var correct := 0
	for answer in answers:
		if answer:
			correct += 1
	return roundi(float(correct) / float(QUIZ_ITEMS.size()) * 100.0)


func _copy_result() -> void:
	var before := _quiz_accuracy(pre_answers)
	var after := _quiz_accuracy(post_answers)
	var progress := after - before
	DisplayServer.clipboard_set("小小夢魔成果：需要與儲蓄 %d 分；分散與風險 %d 分；理財想法 %d%% → %d%%（%s%d 個百分點）。" % [stage_scores[0], stage_scores[1], before, after, "+" if progress > 0 else "", progress])
	summary_copy_button.text = "成果已複製！"
	_play_tone(600)


func _toggle_sound() -> void:
	sound_enabled = not sound_enabled
	sound_button_ref.text = "音效：" + ("開" if sound_enabled else "關")
	_play_tone(480)


func _play_tone(frequency: float) -> void:
	if not sound_enabled:
		return
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050
	stream.buffer_length = 0.15
	sound_player.stream = stream
	sound_player.play()
	var playback := sound_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	for frame in range(2600):
		var time := float(frame) / stream.mix_rate
		var envelope := 1.0 - float(frame) / 2600.0
		var sample := sin(TAU * frequency * time) * 0.06 * envelope
		playback.push_frame(Vector2(sample, sample))


func _unhandled_key_input(event: InputEvent) -> void:
	if current_screen != "game" or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_3:
		_select_stage_answer(event.keycode - KEY_1)
