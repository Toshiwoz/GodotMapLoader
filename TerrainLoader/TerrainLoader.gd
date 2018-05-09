# Some coordinate you can use to test the script
# FLORENCE - lat: 43.771388888889 lon: 11.254166666667
# IGUAZU FALLS lat: -25.695277777778 lon: -54.436666666667
# COTOPAXI lat: -0.680556,-78.437778
# MOUNT FUJI lat: 35.36 lon: 138.73
# HIMALAYA lat: 27.988056, lon: 86.925278
tool
extends Spatial

export(String) onready var access_token = ""
export(float, -180, 180) onready var lon setget _set_lon
export(float, -90, 90) onready var lat setget _set_lat
export(int, 1, 15, 1) onready var zoom_level setget _setZoom
export(float, 0.1, 50, 0.1) onready var HeighMultiplier
export(int) var tilex = 0 setget , _get_tilex
export(int) var tiley = 0 setget , _get_tiley
export(int) var pxlx = 0 setget , _get_pxlx
export(int) var pxly = 0 setget , _get_pxly
export(Image) onready var TerrainHeightMap
export(Image) onready var TerrainTexture
var smf = preload("res://TerrainLoader/slippy_map_functions.gd")
var tsh = preload("res://TerrainLoader/TerrainShaper.tscn")

func _get_tilex():
	self._setCoords(lon, lat, zoom_level)
	return tilex
	
func _get_tiley():
	self._setCoords(lon, lat, zoom_level)
	return tiley


func _get_pxlx():
	self._setCoords(lon, lat, zoom_level)
	return pxlx
	
func _get_pxly():
	self._setCoords(lon, lat, zoom_level)
	return pxly

func _setZoom(_newval):	
	if(zoom_level != _newval):
		zoom_level = _newval
		self._setCoords(lon, lat, zoom_level)
		_request_map(tilex, tiley, zoom_level, false)
		_request_map(tilex, tiley, zoom_level, true)
			

func _set_lon(_newval):
	if(lon != _newval):
		lon = _newval
		self._setCoords(lon, lat, zoom_level)
		_request_map(tilex, tiley, zoom_level, false)
		_request_map(tilex, tiley, zoom_level, true)

func _set_lat(_newval):
	if(lat != _newval):
		lat = _newval
		self._setCoords(lon, lat, zoom_level)
		_request_map(tilex, tiley, zoom_level, false)
		_request_map(tilex, tiley, zoom_level, true)
		

func _setCoords(_lon = 0, _lat = 0, _zoom = 1):
	if(self.is_inside_tree() && _lat != null && _lon != null && _zoom != null):
		print("Setting coords")
		TerrainHeightMap = Image.new()
		TerrainTexture = Image.new()
		var tile = smf.latlon_to_tile_pxl(_lat, _lon, _zoom)
		tilex = tile["tilex"]
		tiley = tile["tiley"]
		pxlx = tile["pxlx"]
		pxly = tile["pxly"]
	
func _request_map(_tilex = 0, _tiley = 0, _zoom = 1, _isheightmap = true):
	if(self.is_inside_tree()):
		if(has_node("MapLoaderTexture") 
			&& has_node("MapLoaderHeightMap")):
			print("generating terrain...")
			var map_type = "terrain-rgb"
			var double_size = ""
			if(!_isheightmap):
				map_type = "satellite"
				double_size = "@2x"
			var url = "https://api.mapbox.com/v4/mapbox." + map_type + "/" + var2str(_zoom) + "/" + var2str(_tilex) + "/" + var2str(_tiley) + double_size + ".pngraw?access_token=" + access_token
			print(url)
			if(_isheightmap):
				$MapLoaderHeightMap.cancel_request()
				$MapLoaderHeightMap.request(url
				, PoolStringArray(), false, 0)
			else:
				$MapLoaderTexture.cancel_request()
				$MapLoaderTexture.request(url
				, PoolStringArray(), false, 0)
	
func print_response_messages(result, response_code, headers, body):
	if(result == HTTPRequest.RESULT_SUCCESS):
		print("Download successful, Body Size: " + var2str(body.size()))
	else:
		print("Error/Warning code: " + var2str(result))
		print("Response code: " + var2str(response_code))

func get_image_from_bytes(_bytes, _save_path = null):
	var resp_image = Image.new()
	var png_error = resp_image.load_png_from_buffer(_bytes)
	if(png_error !=0):
		print("Image load error code: " + var2str(png_error))
	print("Image Size: " + var2str(resp_image.get_size()))
	if(_save_path != null):
		resp_image.lock()
		var save_error = resp_image.save_png(_save_path)
		if(save_error !=0):
			print("Image load error code: " + var2str(png_error))
		resp_image.unlock()
	return resp_image
	
func generate_terrain_meshes():
		if(TerrainHeightMap != null && TerrainTexture != null):
			if(TerrainHeightMap.get_size().length() > 0
			&& TerrainTexture.get_size().length() > 0):
				print("Adding Terrain tiles...")
				var tree = self.get_tree()
				var scene_root = tree.current_scene
				if(scene_root == null):
					scene_root = tree.edited_scene_root
				for nd in self.get_children():
					if(nd.name.begins_with("terrain")):
						print("removing node " + nd.name)
						nd.free()
				var terrain = Spatial.new()
				terrain.name = "terrain"
				self.add_child(terrain)
				terrain.set_owner(scene_root)
				var subdivide = TerrainHeightMap.get_size().x / 256
				var total_tiles = subdivide * subdivide
				for tile_number in range(1, total_tiles + 1):
					var terr_node = tsh.instance()
					terr_node.name = "tile_" + var2str(tile_number)
					terrain.add_child(terr_node)
					terr_node.set_owner(scene_root)
					terr_node.SubsetShift = true
					print(TerrainHeightMap.get_size())
					print(TerrainTexture.get_size())
					terr_node.initialize_map(zoom_level, tilex, tiley, HeighMultiplier, subdivide, tile_number, TerrainHeightMap, TerrainTexture)

	
func _on_MapLoaderHeightMap_request_completed(result, response_code, headers, body):
	print_response_messages(result, response_code, headers, body)
	TerrainHeightMap = get_image_from_bytes(body)#, "res://response_hm.png")
	if(TerrainHeightMap.get_size().length() > 0):
		generate_terrain_meshes()
	else:
		print("Image is empty")

func _on_MapLoaderTexture_request_completed(result, response_code, headers, body):
	print_response_messages(result, response_code, headers, body)
	TerrainTexture = get_image_from_bytes(body)#, "res://response_txtr.png")
	if(TerrainTexture.get_size().length() > 0):
		generate_terrain_meshes()
	else:
		print("Image is empty")
