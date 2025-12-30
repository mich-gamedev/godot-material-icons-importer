@tool
extends EditorPlugin

var _context_menu: EditorContextMenuPlugin

const ContextMenu = preload("uid://cdradtvxjqewd")
const PluginWindow = preload("uid://biu7ujfl17kfo")
const WINDOW = preload("uid://c8gyhxdgrbfvr")
const SETTING_INFO = "res://addons/material_icons_importer/settings_info.json"
var editor_settings := EditorInterface.get_editor_settings()

var window: PluginWindow

func _enter_tree() -> void:
	var file = FileAccess.open(SETTING_INFO, FileAccess.READ)
	var data : Array = JSON.parse_string(file.get_as_text())
	for i: Dictionary in data:
		if "hint" in i: i.hint = int(i.hint)
		if "type" in i: i.type = int(i.type)
		var info = i.duplicate()
		info.erase("default")
		if !editor_settings.has_setting(i.name):
			editor_settings.set_setting(i.name, i.default)
		editor_settings.set_initial_value(i.name, i.default, false)
		editor_settings.add_property_info(info)
	_context_menu = ContextMenu.new()
	_context_menu.item_pressed.connect(_context_item_pressed)
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, _context_menu)

func _context_item_pressed(path: String) -> void:
	if !window:
		window = WINDOW.instantiate() as PluginWindow
		window.path = path
		add_child(window)
		window.grab_focus()
		window.update_size(get_window().size / 2.)
		window.title = "Material Icon Imporer (to: %s)" % path
	else:
		window.show()
		window.path = path
		window.grab_focus()
		window.title = "Material Icon Imporer (to: %s)" % path

func _exit_tree() -> void:
	remove_context_menu_plugin(_context_menu)
