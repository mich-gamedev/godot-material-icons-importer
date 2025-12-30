@tool
extends HBoxContainer

var data: Dictionary
var settings: Dictionary

@onready var label: Label = $Label
@onready var preview_button: Button = %PreviewButton
@onready var icon_preview: TextureRect = %IconPreview
@onready var icon_request: HTTPRequest = %IconRequest
@onready var import_checkbox: CheckBox = %ImportCheckbox

var types := ["materialicons", "materialiconsoutlined", "materialiconsround", "materialiconssharp", "materialiconstwotone"]
var types_alt := ["baseline", "outline", "round", "sharp", "twotone"]

const EntryVbox = preload("uid://cpffujb3a2cxf")
const MISSING_RESOURCE = preload("uid://cb0xh0kdkgxn1")

func update_entry(reset_preview: bool = true, _settings: Dictionary = {}) -> void:
	if _settings:
		settings = _settings
	label.text = "%s (%s)" % [String(data.name).capitalize(), String(data.name)]
	label.remove_theme_color_override(&"font_color")
	import_checkbox.disabled = false
	preview_button.disabled = false
	preview_button.text = "Preview"
	preview_button.show()
	icon_preview.hide()

func preview() -> void:
	icon_request.cancel_request()
	preview_button.disabled = true
	preview_button.text = "Loading..."
	icon_request.request(
		"https://raw.githubusercontent.com/google/material-design-icons/refs/heads/master/png/{category}/{name}/{type}/{resolution}/{scale}/{type_alt}_{name}_black_{resolution}.png".format({
			"category": (get_parent() as EntryVbox).data.name,
			"name": data.name,
			"type": types[settings.type],
			"resolution": str(settings.resolution) + "dp",
			"scale": "2x" if settings.double_res else "1x",
			"type_alt": types_alt[settings.type]
		})
	)

func _request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var img := Image.new()
	var err := img.load_png_from_buffer(body)
	if err:
		print("├┄ Error from ", data.name)
		print("├┄ response code: ", response_code)
		print("├┄ response text: ", body.get_string_from_utf8())
		print("└┄ Request link: https://raw.githubusercontent.com/google/material-design-icons/refs/heads/master/png/{category}/{name}/{type}/{resolution}/{scale}/{type_alt}_{name}_black_{resolution}.png".format({
			"category": (get_parent() as EntryVbox).data.name,
			"name": data.name,
			"type": types[settings.type],
			"resolution": str(settings.resolution) + "dp",
			"scale": "2x" if settings.double_res else "1x",
			"type_alt": types_alt[settings.type]
		}))
		label.text = "%s (%s) (Preview failed. Likely no version of selected type.)" % [String(data.name).capitalize(), String(data.name)]
		label.add_theme_color_override(&"font_color", Color.INDIAN_RED)
		icon_preview.texture = MISSING_RESOURCE
		import_checkbox.disabled = true
		preview_button.disabled = false
		preview_button.text = "Retry"
	else:
		for i in img.get_size().x:
			for j in img.get_size().y:
				var color = img.get_pixel(i, j)
				color.v = 1
				img.set_pixel(i, j, color)
		var tex := ImageTexture.create_from_image(img)
		icon_preview.texture = tex
		icon_preview.show()
		preview_button.hide()
		preview_button.disabled = false
		preview_button.text = "Preview"


func _on_gui_input(event: InputEvent) -> void:
	if import_checkbox.disabled: return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			import_checkbox.button_pressed = !import_checkbox.button_pressed

func search(term: String) -> void:
	term = term.capitalize()
	if term:
		var pattern := ""
		for i in term.split(" "):
			pattern += "(?=.*%s)" % i
		var regex := RegEx.new() ; regex.compile(pattern)
		visible = regex.search(String(data.name).capitalize()) != null
		print("---")
		print(String(data.name).capitalize())
		print(regex.search(String(data.name).capitalize()))
		print(pattern)
		get_parent().get_child(get_index() + 1).visible = visible # hides the HSeparator below the entry.

	else:
		visible = true
		get_parent().get_child(get_index() + 1).visible = true

func save(to_dir: String) -> void:
	if !icon_preview.visible:
		preview()
		await icon_request.request_completed
		await get_tree().process_frame
	icon_preview.texture.get_image().save_png(to_dir.path_join(String(data.name).to_camel_case()) + ".png")
	await get_tree().create_timer(.33).timeout # save_png is not blocking and there probably isnt a way to callback to when it's finished
	EditorInterface.get_resource_filesystem().scan()

func _on_import_checkbox_toggled(toggled_on: bool) -> void:
	if toggled_on:
		if !icon_preview.visible:
			preview()
			await icon_request.request_completed
			await get_tree().process_frame
		add_to_group(&"material_icons_import")
		var btn := Button.new()
		btn.icon = icon_preview.texture
		btn.tooltip_text = "%s > %s (Click to deselect)" % [(get_parent() as EntryVbox).data.name, data.name]
		btn.name = data.name
		btn.expand_icon = true
		btn.custom_minimum_size = Vector2.ONE * 48
		get_window().get_node(^"%SelectedContainer").add_child(btn, true)
		btn.pressed.connect(deselect_entry)

	else:
		remove_from_group(&"material_icons_import")
		get_window().get_node("%SelectedContainer/" + data.name).queue_free()

func deselect_entry() -> void:
	import_checkbox.button_pressed = false
