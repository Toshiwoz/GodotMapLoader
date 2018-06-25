# Licensed under the MIT License.
# Copyright (c) 2018 Leonardo (Toshiwo) Araki

tool
extends Spatial

var smf = preload("res://TerrainLoader/slippy_map_functions.gd")
var tsh = preload("res://TerrainLoader/TerrainShaper.tscn")

export(String) onready var access_token
export(float, -180, 180) onready var lon setget _set_lon
export(float, -85.0511, 85.0511) onready var lat setget _set_lat
export(int, 1, 15, 1) onready var zoom_level setget _setZoom
export(float, 0.1, 50, 0.1) onready var HeighMultiplier
export(int) var tilex = 0 setget _set_tilex
export(int) var tiley = 0 setget _set_tiley
export(int) var pxlx = 0 setget , _get_pxlx
export(int) var pxly = 0 setget , _get_pxly
export(bool) onready var ArrangeTiles = false setget _set_arrangetile

var TerrainHeightMap
var TerrainTexture
var ThreadML = Thread.new()

func _set_tilex(_newval):
	if(tilex != _newval):
		tilex = _newval
		pxlx = 1
		pxly = 1
		_setTiles(tilex, tiley, zoom_level)
	
func _set_tiley(_newval):
	if(tiley != _newval):
		tiley = _newval
		pxlx = 1
		pxly = 1
		_setTiles(tilex, tiley, zoom_level)

func _get_pxlx():
	return pxlx
	
func _get_pxly():
	return pxly

func _setZoom(_newval):
	if(zoom_level != _newval):
		zoom_level = _newval
		_setCoords(lon, lat, zoom_level)

func _set_lon(_newval):
	if(lon != _newval):
		lon = _newval
		_setCoords(lon, lat, zoom_level)

func _set_lat(_newval):
	if(lat != _newval):
		lat = _newval
		_setCoords(lon, lat, zoom_level)

func _set_arrangetile(_newval):
	ArrangeTilesInGrid()	

func _setCoords(_lon = 0, _lat = 0, _zoom = 1):
	if(self.is_inside_tree() && _lat != null && _lon != null && _zoom != null):
		print("Setting coords")
		TerrainHeightMap = Image.new()
		TerrainTexture = Image.new()
		var tile = smf.latlon_to_tile_pxl(_lat, _lon, _zoom)
		tilex = tile.tilex
		tiley = tile.tiley
		pxlx = tile.pxlx
		pxly = tile.pxly
		if(getTilexyz(tilex, tiley, _zoom) != null):
			print("this tile already exists, remove it first")
		else:
			_request_map(tilex, tiley, zoom_level, false)
			_request_map(tilex, tiley, zoom_level, true)
		
func _setTiles(_tilex = 0, _tiley = 0, _zoom = 1):
	if(self.is_inside_tree() && _tilex != null && _tiley != null && _zoom != null):
		print("Setting coords")
		TerrainHeightMap = Image.new()
		TerrainTexture = Image.new()
		var latlon = smf.tile_to_latlon(_tilex, _tiley, _zoom)
		lat = latlon.lat
		lon = latlon.lon
		if(getTilexyz(_tilex, _tiley, _zoom) != null):
			print("this tile already exists, remove it first")
		else:
			_request_map(tilex, tiley, zoom_level, false)
			_request_map(tilex, tiley, zoom_level, true)
	
func _request_map(_tilex = 0, _tiley = 0, _zoom = 1, _isheightmap = true):
	if(self.is_inside_tree()):
		if(has_node("MapLoaderTexture")
			&& has_node("MapLoaderHeightMap")):
			if(access_token.length() == 0):
				print("Access token is not set")
			else:				
				var map_type = "terrain-rgb"
				var double_size = ""
				if(!_isheightmap):
					map_type = "satellite"
					double_size = "@2x"
				print("Requesting %s tile x/y/z %d/%d/%d" % [map_type, _tilex, _tiley, _zoom])
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

func get_image_from_bytes(_bytes, _save_path = null):
	var resp_image = Image.new()
	resp_image.create(256, 256, true, Image.FORMAT_L8)
	var png_error = 0
	if(_bytes.size() > 33):
		png_error = resp_image.load_png_from_buffer(_bytes)
	else:
		print("No heightmap tile found, using default...")
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
					
			var terrain = find_node("terrain")
			if(terrain == null):
				terrain = Spatial.new()
				terrain.name = "terrain"
				self.add_child(terrain)
				terrain.set_owner(scene_root)
					
			for tile in terrain.get_children():
				if(tile.Zoom == self.zoom_level && tile.TileX == self.tilex && tile.TileY == self.tiley):
					print("replacing tile " + tile.name)
					tile.free()
			var subdivide = 1 #TerrainHeightMap.get_size().x / 256 #For now no subdivision
			var total_tiles = subdivide * subdivide
			for tile_number in range(1, total_tiles + 1):
				var terr_node = tsh.instance()
				terr_node.name = "xyz_%s_%s_%s" % [tilex, tiley, zoom_level]
				terrain.add_child(terr_node)
				terr_node.set_owner(scene_root)
				terr_node.SubsetShift = true
				terr_node.initialize_map(zoom_level, tilex, tiley, HeighMultiplier, subdivide, tile_number, TerrainHeightMap, TerrainTexture)
#				ThreadML = Thread.new()
#				ThreadML.start(terr_node, "SetMapShapeAndCollision", null)
				terr_node.SetMapShapeAndCollision()
				
				# Check if we have contiguous tiles, then generate junction meshes
			for tile in terrain.get_children():
				var next_tile_x = getTilexyz(tile.TileX + 1, tile.TileY, tile.Zoom)
				var next_tile_y = getTilexyz(tile.TileX, tile.TileY + 1, tile.Zoom)

func ArrangeTilesInGrid():
	var terrain = find_node("terrain")
	if(terrain != null):
		for tile in terrain.get_children():
			var tileAABB = tile.get_node("TerrainMesh").get_aabb()
			print("Size x%f/y%f/z%f" % [tileAABB.position.x, tileAABB.position.y, tileAABB.position.z])
			print("Size w/h: %f/%f" % [tileAABB.size.x, tileAABB.size.z])
			var next_tile_x = getTilexyz(tile.TileX + 1, tile.TileY, tile.Zoom)
			var next_tile_y = getTilexyz(tile.TileX, tile.TileY + 1, tile.Zoom)
			if(next_tile_x != null):
				next_tile_x.translation.x = tile.translation.x + tileAABB.size.x
				next_tile_x.translation.y = tile.translation.y
				next_tile_x.translation.z = tile.translation.z
			if(next_tile_y != null):
				next_tile_y.translation.x = tile.translation.x
				next_tile_y.translation.y = tile.translation.y
				next_tile_y.translation.z = tile.translation.z + tileAABB.size.z

func getTilexyz(_x, _y, _z):
	var terrain = find_node("terrain")
	if(terrain != null):
		for tile in terrain.get_children():
			if(tile.TileX == _x && tile.TileY == _y && tile.Zoom == _z):
				return tile
	return null
	
func handleResponse(result, response_code, headers, body, _IsHeightmap):
	if(result == HTTPRequest.RESULT_SUCCESS):
		print("Download successful, Body Size: " + var2str(body.size()))
		if(_IsHeightmap):
			TerrainHeightMap = get_image_from_bytes(body)
		else:
			TerrainTexture = get_image_from_bytes(body)
		if(TerrainHeightMap.get_size().length() > 0
			&& TerrainTexture.get_size().length() > 0):
			generate_terrain_meshes()
	else:
		print("Error/Warning code: " + var2str(result))
		print("Response code: " + var2str(response_code))

func _on_MapLoaderHeightMap_request_completed(result, response_code, headers, body):
	handleResponse(result, response_code, headers, body, true)

func _on_MapLoaderTexture_request_completed(result, response_code, headers, body):
	handleResponse(result, response_code, headers, body, false)