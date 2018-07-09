extends Button

func _ready():
	pass


func _on_Button_pressed():
	var pva = PoolVector3Array()
	pva.append(Vector3(1, 2, 3))
	print(pva)
	pva.resize(0)
	print(pva)
#	get_tree().change_scene("res://assets/himalaya.tscn")
	
