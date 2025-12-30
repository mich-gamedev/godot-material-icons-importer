@tool
extends EditorContextMenuPlugin

const ICON_GOOGLE_FONTS = preload("uid://wk4ufdg8t3o5")

signal item_pressed(path: String)

func _popup_menu(paths: PackedStringArray) -> void:
	if paths.size() == 1 and paths[0].ends_with("/"):
		add_context_menu_item("Import Material Icon", _pressed.bind(paths[0]), ICON_GOOGLE_FONTS)

func _pressed(_arr: Array, path: String) -> void:
	item_pressed.emit(path) # See `plugin.gd` : lines 20 & 22
