@tool
extends VBoxContainer

var data: Dictionary
@onready var icon_request: HTTPRequest = %IconRequest
@onready var note_label: Label = %NoteLabel
var cached: bool
var editor_settings := EditorInterface.get_editor_settings()
var settings: Dictionary
const ICON_ENTRY = preload("uid://b2qwc467g6xlt")
const IconEntry = preload("uid://6qdvlhlguahn")

signal finished_expanding

func _on_foldable_container_folding_changed(is_folded: bool) -> void:
	if (!is_folded) and (!cached):
		cached = true
		get_parent().self_modulate.a = 1.0
		icon_request.request(
			data.url,
			[
				"Accept: application/vnd.github.object",
				"Authorization: Bearer %s" % editor_settings.get_setting("plugin/material_icon_importer/github/api_token"),
				"X-GitHub-Api-Version: 2022-11-28"
			]
			if editor_settings.get_setting("plugin/material_icon_importer/github/api_token") else
			[
				"Accept: application/vnd.github.object",
				"X-GitHub-Api-Version: 2022-11-28"
			],
		)

func _on_icon_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var body_string := body.get_string_from_utf8()
	var dict := JSON.parse_string(body_string)
	for i in dict.entries:
		if i.type == "dir":
			var inst := ICON_ENTRY.instantiate() as IconEntry
			add_child(inst)
			inst.data = i
			inst.update_entry(true, settings)
			var hr := HSeparator.new()
			add_child(hr)
	note_label.queue_free()
	if editor_settings.get_setting("plugin/material_icon_importer/loading/automatically_preview_icons"): await preview_children()
	finished_expanding.emit()

func preview_children() -> void:
	var _itr: int
	for i in get_children():
		if i is IconEntry:
			_itr += 1
			i.preview()
			if _itr % 20 == 19:
				await i.icon_request.request_completed
