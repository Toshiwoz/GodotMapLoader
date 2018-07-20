extends Spatial

func _ready():
	pass


func _on_Button_himalaya_pressed():
	$TerrainLoader.deleteTiles()
	$TerrainLoader.coordinates = Vector3(86.925278,27.988056,12)


func _on_Button_cotopaxy_pressed():
	$TerrainLoader.deleteTiles()
	$TerrainLoader.coordinates = Vector3(-78.437778,-0.680556,12)


func _on_MapboxLink_pressed():
	OS.shell_open("https://www.mapbox.com/about/maps/")


func _on_OpenStreetMapLink_pressed():
	OS.shell_open("http://www.openstreetmap.org/about/")


func _on_ImproveLink_pressed():
	OS.shell_open("https://www.mapbox.com/map-feedback/#/%d/%d/%d" % [$TerrainLoader.coordinates.x,$TerrainLoader.coordinates.y,$TerrainLoader.coordinates.z])
	
