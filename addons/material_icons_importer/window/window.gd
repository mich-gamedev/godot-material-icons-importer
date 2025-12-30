@tool
extends Window

var path: String
var editor_settings := EditorInterface.get_editor_settings()
var settings: Dictionary

const CATEGORY_ENTRY := preload("uid://0tkmxun2auvn")
const EntryVbox := preload("uid://cpffujb3a2cxf")

@onready var split: HSplitContainer = %HSplit
@onready var category_request: HTTPRequest = %CategoryRequest
@onready var category_container: VBoxContainer = %CategoryContainer

func _ready() -> void:
	%TypeOption.selected = %TypeOption.get_item_index(editor_settings.get_setting("plugin/material_icon_importer/defaults/mode"))
	%ResOption.selected = %ResOption.get_item_index(editor_settings.get_setting("plugin/material_icon_importer/defaults/resolution"))
	%DoubleRes.button_pressed = editor_settings.get_setting("plugin/material_icon_importer/defaults/double_resolution")
	settings.type = %TypeOption.get_selected_id()
	settings.resolution = %ResOption.get_selected_id()
	settings.double_res = %DoubleRes.button_pressed
	category_request.request(
		"https://api.github.com/repos/google/material-design-icons/contents/png",
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
	category_request.request_completed.connect(_category_req_completed)

func _physics_process(delta: float) -> void:
	%ImportSelected.text = "Import Selected (%d)" % get_tree().get_nodes_in_group(&"material_icons_import").size()

func _on_close_requested() -> void:
	hide.call_deferred() # the node gets reused, so not freeing it is fine.

func update_size(new_size: Vector2) -> void:
	size = new_size
	split.split_offset = (size * 3./4.).x
	move_to_center()

func _category_req_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var body_string := body.get_string_from_utf8()
	var dict := JSON.parse_string(body_string)
	for i in dict.entries:
		if i.type == "dir":
			var inst := CATEGORY_ENTRY.instantiate() as FoldableContainer
			inst.name = String(i.name)
			inst.title = String(i.name).capitalize()
			if i.name == "av": inst.title = "Audio & Visual"
			(inst.get_node("%EntryVBox") as EntryVbox).data = i
			(inst.get_node("%EntryVBox") as EntryVbox).settings = settings
			category_container.add_child(inst, true)

func _on_type_option_item_selected(index: int) -> void:
	settings.type = index
	propagate_call(&"update_entry", [true, settings])
	if editor_settings.get_setting("plugin/material_icon_importer/loading/automatically_preview_icons"): propagate_call(&"preview_children")

func _on_res_option_item_selected(index: int) -> void:
	settings.resolution = %ResOption.get_item_id(index)
	propagate_call(&"update_entry", [true, settings])
	if editor_settings.get_setting("plugin/material_icon_importer/loading/automatically_preview_icons"): propagate_call(&"preview_children")

func _on_double_res_toggled(toggled_on: bool) -> void:
	settings.double_res = toggled_on
	propagate_call(&"update_entry", [true, settings])
	if editor_settings.get_setting("plugin/material_icon_importer/loading/automatically_preview_icons"): propagate_call(&"preview_children")

func _on_search_text_submitted(new_text: String) -> void:
	propagate_call(&"search", [new_text])

func _on_import_selected_pressed() -> void:
	get_tree().call_group(&"material_icons_import", &"save", path)
	_on_deselect_pressed()

func _on_deselect_pressed() -> void:
	propagate_call(&"deselect_entry")

func _on_expand_all_pressed() -> void:
	for i in category_container.get_children():
		if i is FoldableContainer:
			i.expand()
			var vbox := i.get_node(^"%EntryVBox") as EntryVbox
			await vbox.finished_expanding
