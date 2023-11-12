@tool
extends PopupPanel

@onready var label = $"%Label"
var text := ""

func _ready() -> void :
	var _err = connect("popup_hide", on_hidden)
	label.text = text
	call_deferred("popup_centered")


func on_hidden() -> void :
	queue_free()


func _on_CloseButton_pressed():
	hide()


