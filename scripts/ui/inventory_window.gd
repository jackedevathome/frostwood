class_name InventoryWindow
extends Control
## Inventory: item grid, the 3 hotbar slots (drag items onto them), item details and crafting.

const COLS := 7
const ROWS := 3
const CELL := 64.0

var game: Node
var player: Player
var selected_item := ""
var hovered_item := ""

var _grid: GridContainer
var _slots: Array = []
var _hotbar_slots: Array = []
var _name: Label
var _desc: Label
var _actions: HBoxContainer
var _worn: Label
var _craft_rows: VBoxContainer
var _signature := ""


## One cell of the inventory grid. Drag it onto a hotbar slot to equip.
class InvSlot extends Control:
	var win: InventoryWindow
	var item := ""

	func _ready() -> void:
		custom_minimum_size = Vector2(CELL, CELL)
		mouse_entered.connect(func(): win.hovered_item = item)
		mouse_exited.connect(_on_exit)

	func _on_exit() -> void:
		if win.hovered_item == item:
			win.hovered_item = ""

	func _draw() -> void:
		var hov := win.hovered_item == item and item != ""
		HUD.draw_slot(self, Rect2(Vector2.ZERO, size), item, win.player, item != "" and win.selected_item == item, "", hov)
		if item != "" and win.player.hotbar.has(item):
			var idx := win.player.hotbar.find(item)
			draw_circle(Vector2(size.x - 11, 11), 8, Color(0.58, 0.82, 0.96))
			HUD.text(self, Vector2(size.x - 19, 16), str(idx + 1), 12, Color(0.05, 0.08, 0.12), HORIZONTAL_ALIGNMENT_CENTER, 16)

	func _gui_input(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and item != "":
			if ev.button_index == MOUSE_BUTTON_LEFT:
				win.select_item(item)
				if ev.double_click:
					win.use_item(item)
			elif ev.button_index == MOUSE_BUTTON_RIGHT:
				win.use_item(item)

	func _get_drag_data(_pos: Vector2) -> Variant:
		if item == "" or not Items.is_equippable(item):
			return null
		set_drag_preview(InventoryWindow.make_preview(item))
		return {"item": item}

	func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.has("slot")

	func _drop_data(_pos: Vector2, data: Variant) -> void:
		win.player.hotbar[data.slot] = ""
		Audio.play("ui_click", -8)


## One of the 3 hotbar slots inside the inventory window. Accepts drops.
class HotbarSlot extends Control:
	var win: InventoryWindow
	var index := 0

	func _ready() -> void:
		custom_minimum_size = Vector2(CELL + 8, CELL + 8)

	func _draw() -> void:
		var p := win.player
		HUD.draw_slot(self, Rect2(Vector2.ZERO, size), p.hotbar[index], p, index == p.selected, str(index + 1))

	func _gui_input(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			if ev.button_index == MOUSE_BUTTON_LEFT:
				win.player.select(index)
				if win.player.hotbar[index] != "":
					win.select_item(win.player.hotbar[index])
			elif ev.button_index == MOUSE_BUTTON_RIGHT:
				win.player.hotbar[index] = ""
				Audio.play("ui_click", -8)

	func _get_drag_data(_pos: Vector2) -> Variant:
		var id: String = win.player.hotbar[index]
		if id == "":
			return null
		set_drag_preview(InventoryWindow.make_preview(id))
		return {"item": id, "slot": index}

	func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.has("item") and Items.is_equippable(data.item)

	func _drop_data(_pos: Vector2, data: Variant) -> void:
		if data.has("slot"):
			var a: int = data.slot
			var tmp: String = win.player.hotbar[index]
			win.player.hotbar[index] = win.player.hotbar[a]
			win.player.hotbar[a] = tmp
			Audio.play("ui_click", -8)
		else:
			win.player.assign_slot(index, data.item)


static func make_preview(id: String) -> Control:
	var c := Control.new()
	c.size = Vector2(CELL, CELL)
	c.draw.connect(func(): Items.draw_icon(c, id, Vector2.ZERO, 20.0, 0.85))
	return c


func setup(g: Node) -> void:
	game = g
	player = g.player
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.05, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 28)
	panel.add_child(h)

	# --- left: inventory
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	h.add_child(left)
	var title_row := HBoxContainer.new()
	left.add_child(title_row)
	var title := UITheme.heading("Inventory", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	_worn = UITheme.label("", 15, UITheme.WARM)
	title_row.add_child(_worn)
	_grid = GridContainer.new()
	_grid.columns = COLS
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	left.add_child(_grid)
	for i in COLS * ROWS:
		var s := InvSlot.new()
		s.win = self
		_grid.add_child(s)
		_slots.append(s)

	left.add_child(UITheme.label("Hotbar  —  drag items here, or hover an item and press 1-3", 15, UITheme.MUTED))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	left.add_child(hb)
	for i in Player.SLOTS:
		var s := HotbarSlot.new()
		s.win = self
		s.index = i
		hb.add_child(s)
		_hotbar_slots.append(s)

	var details := PanelContainer.new()
	details.add_theme_stylebox_override("panel", UITheme.box(Color(0.05, 0.07, 0.1, 0.8), Color(0.4, 0.55, 0.65, 0.35), 1, 8, 12))
	details.custom_minimum_size = Vector2(COLS * (CELL + 6), 150)
	left.add_child(details)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 6)
	details.add_child(dv)
	_name = UITheme.label("", 22, Color.WHITE)
	dv.add_child(_name)
	_desc = UITheme.label("", 16, UITheme.MUTED)
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.custom_minimum_size.x = COLS * (CELL + 6) - 30
	dv.add_child(_desc)
	_actions = HBoxContainer.new()
	_actions.add_theme_constant_override("separation", 8)
	dv.add_child(_actions)

	# --- right: crafting
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	h.add_child(right)
	right.add_child(UITheme.heading("Crafting", 28))
	right.add_child(UITheme.ornament(320))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(344, 470)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	_craft_rows = VBoxContainer.new()
	_craft_rows.add_theme_constant_override("separation", 6)
	scroll.add_child(_craft_rows)
	for rec in Items.RECIPES:
		var b := Button.new()
		b.custom_minimum_size = Vector2(326, 52)
		for st in ["normal", "hover", "pressed", "disabled"]:
			var sb := UITheme.button_box(st)
			sb.content_margin_left = 58
			b.add_theme_stylebox_override(st, sb)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.set_meta("rec", rec)
		b.pressed.connect(_craft_pressed.bind(rec))
		b.draw.connect(_draw_recipe_icon.bind(b))
		b.add_theme_font_size_override("font_size", 16)
		_craft_rows.add_child(b)
	var close_hint := UITheme.label("%s / Esc to close" % Settings.key_name("inventory"), 14, UITheme.MUTED)
	close_hint.name = "CloseHint"
	right.add_child(close_hint)
	Audio.hook_buttons(self)
	hide()


func open() -> void:
	show()
	(find_child("CloseHint", true, false) as Label).text = "%s / Esc to close" % Settings.key_name("inventory")
	if selected_item != "" and player.count(selected_item) <= 0:
		selected_item = ""
	_refresh(true)


func focus_crafting() -> void:
	pass  # crafting is always visible on the right


func _items() -> Array:
	var ids := player.inventory.keys().filter(func(k): return player.count(k) > 0)
	ids.sort_custom(func(a, b): return Items.sort_key(a) < Items.sort_key(b))
	return ids


func _process(_delta: float) -> void:
	if visible:
		_refresh(false)


func _refresh(force: bool) -> void:
	var ids := _items()
	var sig := ",".join(ids)
	if force or sig != _signature:
		_signature = sig
		for i in _slots.size():
			_slots[i].item = ids[i] if i < ids.size() else ""
		if selected_item == "" or not ids.has(selected_item):
			selected_item = ids[0] if ids.size() > 0 else ""
		_update_details()
	for s in _slots:
		s.queue_redraw()
	for s in _hotbar_slots:
		s.queue_redraw()
	var worn := []
	for w in ["bear_cloak", "fur_cloak", "fox_hat"]:
		if player.count(w) > 0 and not (w == "fur_cloak" and player.count("bear_cloak") > 0):
			worn.append(Items.item_name(w))
	_worn.text = ("Wearing: " + ", ".join(worn)) if worn.size() > 0 else ""
	for b in _craft_rows.get_children():
		var rec: Dictionary = b.get_meta("rec")
		var owned: bool = rec.id in Items.UNIQUE and player.count(rec.id) > 0
		var amt := ("  x%d" % rec.amount) if rec.amount > 1 else ""
		var cost := "Owned" if owned else Items.cost_text(rec.cost)
		var fire_needed: bool = not owned and game.needs_fire(rec)
		if fire_needed:
			cost += "  ·  needs a campfire"
		b.text = "%s%s\n%s" % [Items.item_name(rec.id), amt, cost]
		b.disabled = owned or not game.can_afford(rec.cost) or fire_needed
		b.tooltip_text = Items.DATA[rec.id].get("desc", "")


func select_item(id: String) -> void:
	selected_item = id
	_update_details()


func _update_details() -> void:
	for c in _actions.get_children():
		c.queue_free()
	var id := selected_item
	if id == "":
		_name.text = "Your pack is empty"
		_desc.text = "Chop trees and break rocks to gather materials."
		return
	_name.text = "%s   x%d" % [Items.item_name(id), player.count(id)]
	_desc.text = Items.describe(id)
	if Items.is_equippable(id):
		for i in Player.SLOTS:
			var b := UITheme.button("Slot %d" % (i + 1), 90)
			b.custom_minimum_size.y = 36
			b.add_theme_font_size_override("font_size", 16)
			b.focus_mode = Control.FOCUS_NONE
			b.pressed.connect(func():
				player.assign_slot(i, id)
				_refresh(true))
			_actions.add_child(b)
	var kind: String = Items.DATA[id].kind
	if kind in ["food", "place", "consumable"]:
		var use := UITheme.button({"food": "Eat", "place": "Place", "consumable": "Use"}[kind], 100)
		use.custom_minimum_size.y = 36
		use.add_theme_font_size_override("font_size", 16)
		use.focus_mode = Control.FOCUS_NONE
		use.pressed.connect(use_item.bind(id))
		_actions.add_child(use)
	Audio.hook_buttons(_actions)


func use_item(id: String) -> void:
	match Items.DATA[id].kind:
		"food":
			player.eat(id)
			_refresh(true)
		"consumable":
			player.consume(id)
			_refresh(true)
		"place":
			game.hud.close_windows()
			player.start_placing(id)


func _draw_recipe_icon(b: Button) -> void:
	var rec: Dictionary = b.get_meta("rec")
	Items.draw_icon(b, rec.id, Vector2(30, b.size.y / 2), 16, 1.0 if not b.disabled else 0.4)


func _craft_pressed(rec: Dictionary) -> void:
	game.craft(rec)
	_refresh(true)


func _input(event: InputEvent) -> void:
	if not visible or hovered_item == "" or not Items.is_equippable(hovered_item):
		return
	for i in range(1, Player.SLOTS + 1):
		if event.is_action_pressed("slot_%d" % i):
			player.assign_slot(i - 1, hovered_item)
			get_viewport().set_input_as_handled()
			_refresh(true)
