@tool
extends EditorPlugin
## Añade el AAR de notificaciones al exportar para Android (solo con exportación Gradle y si el AAR existe:
## lo compila el CI desde android/aqua_notify).

var _export: AquaNotifyExport


func _enter_tree() -> void:
	_export = AquaNotifyExport.new()
	add_export_plugin(_export)


func _exit_tree() -> void:
	remove_export_plugin(_export)
	_export = null


class AquaNotifyExport extends EditorExportPlugin:
	const AAR := "aqua_notify/bin/aqua_notify-release.aar"

	func _get_name() -> String:
		return "AquaNotify"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		if get_option("gradle_build/use_gradle_build") and FileAccess.file_exists("res://addons/" + AAR):
			return PackedStringArray([AAR])
		return PackedStringArray()
