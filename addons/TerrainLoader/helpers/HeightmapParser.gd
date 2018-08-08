# Licensed under the MIT License.
# Copyright (c) 2018 Leonardo (Toshiwo) Araki

tool
extends Spatial

var earth_mat = preload("res://addons/TerrainLoader/helpers/TerrainMaterial.tres")
var smf = preload("res://addons/TerrainLoader/helpers/slippy_map_functions.gd")
var sth = preload("res://addons/TerrainLoader/helpers/surface_tool_helper.gd")
var earth_circ = smf.radius_to_circ(smf.EARTH_RADIUS)

var sq_heights = [[0,1,2],[0,1,2],[0,1,2]]
# the heightmap image width and heigth
var width = 0
var heigth = 0
var surf_tool =  sth.new()
var max_min_height = null
var altitude_multiplier = 0.0

func _init():
	smf = preload("res://addons/TerrainLoader/helpers/slippy_map_functions.gd")

static func _subsetToXYCoords(_subset, _divideinto):
	var subsetX = 1
	var subsetY = 1
	for ss in range(1, _subset):
		subsetX += 1
		if subsetX > _divideinto:
			subsetY += 1
			subsetX = 1
	
#	print("Subset: " + var2str(_subset) + " - Divide into: " + var2str(_divideinto)
#	+ " | Y:" + var2str(subsetY) + " - X:" + var2str(subsetX))
	return {"x":subsetX, "y":subsetY}
	
static func GetPixelDistance(_heightMap, _totalSize):
	var dist = 0
	if _heightMap != null:
		var hmSize = float(_heightMap.size())
		var tileSize = hmSize
		if _totalSize == null:
			_totalSize = 0
		if _totalSize > 0:
			tileSize = _totalSize
		dist = float (tileSize / hmSize)
	return dist
	
static func GetMaxMinHight(_img = Image.new()):
	var MaxMin = {minh=999999999, maxh=-1}
	var alt_tl = 0
	_img.lock()
	for y in range(_img.get_height()):
		for x in range(_img.get_width()):
			alt_tl = GetHeightFromPxl(_img.get_pixel(x, y))
			if alt_tl < MaxMin.minh:
				MaxMin.minh = alt_tl
			if alt_tl > MaxMin.maxh:
				MaxMin.maxh = alt_tl
	_img.unlock()
	return MaxMin

# This is the formula that MapBox provides to convert HM image into meters
static func GetHeightFromPxl(_pxl):
	return -10000 + ((_pxl.r8 * 256 * 256 + _pxl.g8 * 256 + _pxl.b8) * 0.1)

func GetImageSubset(_image, _divideinto, _subset, _addpixel = Vector2(0, 0)):
	if _image != null:
		var coords = _subsetToXYCoords(_subset, _divideinto)
		var imgsswidth = _image.get_width() / _divideinto
		var imgssheight = _image.get_height() / _divideinto
		var imgstart = Vector2( imgsswidth * (coords["x"] - 1),
								imgssheight * (coords["y"] - 1))
		var imgssize = Vector2(imgsswidth + _addpixel.x, imgssheight + _addpixel.y)
		var imgsbst = _image.get_rect(Rect2(imgstart, imgssize))
		return imgsbst

func SetMaterialTexture(_txtr_img):
	var imgtxtr = ImageTexture.new()
	imgtxtr.create_from_image(_txtr_img)
	var mat = earth_mat.duplicate() #This way it clones the material for each instance
	mat.albedo_texture = imgtxtr
	return mat

#	_subset should be from 1 to _divideinto * _divideinto
#	_divideinto should be from 1 to 100
#	(considering an image of max 512x512px)
func GenerateHeightMap(_hm_img, _txtr_img, _subset, _divideinto):
	var hm = []
	var coords = _subsetToXYCoords(_subset, _divideinto)
	var lastvalx = 1
	if coords["x"] == _divideinto:
		lastvalx = -1
	var lastvaly = 1
	if coords["y"] == _divideinto:
		lastvaly = -1
	if !_hm_img.is_empty() && !_txtr_img.is_empty():
		var startt = float(OS.get_ticks_msec())
		var TerrainImage = _hm_img
		TerrainImage.lock()
		var TerrainTextureImage = _txtr_img
		TerrainTextureImage.lock()
		var width = TerrainImage.get_width() / _divideinto
		var heigth = TerrainImage.get_height() / _divideinto
		var rangeX = range(width + lastvalx)
		var rangeY = range(heigth + lastvaly)
		var minh = 999999
		var maxh = 0
		for y in rangeY:
			hm.append([])
			for x in rangeX:
				hm[y].append(x)
				var pxlX = (coords["x"] - 1) * width + (width + lastvalx - x)
				var pxlY = (coords["y"] - 1) * heigth + y + lastvaly
				var pxl = TerrainImage.get_pixel(pxlX, pxlY)
				var pxlTexture = TerrainTextureImage.get_pixel(pxlX, pxlY)
				var altitude = -10000 + ((pxl.r8 * 256 * 256 + pxl.g8 * 256 + pxl.b8) * 0.1)
				hm[y][x] =  {"height":altitude, "color":pxlTexture}
				if altitude < minh:
					minh = altitude
				if altitude > maxh:
					maxh = altitude
#			print(rngX)
		TerrainImage.unlock()
		TerrainTextureImage.unlock()
		var endtt = float(OS.get_ticks_msec())
		print("Heightmap of"
		+ " W/H: " + var2str(width) + "/" + var2str(heigth) 
		+ ", Min/Max height: " + var2str(minh) + "/" + var2str(maxh)
		+ " generated in %.2f seconds" % ((endtt - startt)/1000))
	return hm

func createMesh(ht, total_size = 0, height_multiplier = 1, Zoom = 1, _subset = 1, _divideinto = 4, _trimheight = false, _mesh_path = null):
	if _mesh_path != null:
		var _stored_mesh = ResourceLoader(_mesh_path)
		if _stored_mesh != null:
			return _stored_mesh
	if ht.size() > 0:
		var startt = float(OS.get_ticks_msec())
		var surf_tool = SurfaceTool.new()
		var width = ht.size()
		var lenght = ht[0].size()
		print("Length %d - Width %d" % [lenght, width])
		var pxl_mtrs = smf.adjust_dist_from_latzoom(earth_circ, 0, Zoom)
		var size = float(ht.size())
		if total_size == null:
			total_size = 0
		if total_size > 0:
			size = total_size
		var half_size = size /2.0
		var dist = float (size / width)
		var minh = 0
		var maxh = 0
		# Altitude should be proportional to size
		# Height multiplier is used to enhace altitudes,
		# a value of 1 maintain real altitudes
		altitude_multiplier =  float(height_multiplier * dist / pxl_mtrs)
		var x = 0
		if ht:
			surf_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			for i in range (width-1):
				for j in range (lenght-1):
					if maxh < ht[i][j]["height"] * altitude_multiplier:
						maxh = ht[i][j]["height"] * altitude_multiplier
					if minh > ht[i][j]["height"] * altitude_multiplier:
						minh = ht[i][j]["height"] * altitude_multiplier
						
					var bottomleft = Vector3(i * dist - half_size, ht[i][j]["height"] * altitude_multiplier, j * dist - half_size)
					var bl_color = ht[i][j]["color"]
					var upperleft = Vector3(i * dist - half_size, ht[i][j + 1]["height"] * altitude_multiplier, (j + 1) * dist - half_size)
					var ul_color = bl_color.linear_interpolate(ht[i][j + 1]["color"], 0.5)
					var upperright = Vector3((i + 1) * dist - half_size, ht[i + 1][j + 1]["height"] * altitude_multiplier, (j + 1) * dist - half_size)
					var ur_color = bl_color.linear_interpolate(ht[i+1][j+1]["color"], 0.5)
					var bottomright = Vector3((i + 1) * dist - half_size, ht[i + 1][j]["height"] * altitude_multiplier, (j) * dist - half_size)
					var br_color = bl_color.linear_interpolate(ht[i+1][j]["color"], 0.5)
					
					surf_tool.add_color(bl_color)
					surf_tool.add_vertex(bottomleft)
	
					surf_tool.add_color(br_color)
					surf_tool.add_vertex(bottomright)
	
					surf_tool.add_color(ul_color)
					surf_tool.add_vertex(upperleft)
					
					surf_tool.add_color(br_color)
					surf_tool.add_vertex(bottomright)
	
					surf_tool.add_color(ur_color)
					surf_tool.add_vertex(upperright)
	
					surf_tool.add_color(ul_color)
					surf_tool.add_vertex(upperleft)
		
		surf_tool.generate_normals()
		surf_tool.index()
		var material = ResourceLoader.load("res://TerrainLoader/material_vertex_color.tres")
		surf_tool.set_material(material)
		var mesh = surf_tool.commit()
		var x_shift = 0
		var z_shift= 0
		var Coords = _subsetToXYCoords(_subset, _divideinto)
		
		var endtt = float(OS.get_ticks_msec())
		print("Mesh generation"
		+ " Tile " + var2str(_subset) + "/" + var2str(_divideinto * _divideinto)
		+ " X/Y: " + var2str(Coords["x"]) + "/" + var2str(Coords["y"])
		+ " Size: " + var2str(size)
		+ " Dist: " + var2str(dist)
		+ " Meters/Pixel: " + var2str(pxl_mtrs)
		+ " Min/Max Alt.: " + var2str(minh) + "/" + var2str(maxh)
		+ " Shift X/Z: " + var2str(x_shift) + "/" + var2str(z_shift)
		+ " finished in %.2f seconds" % ((endtt - startt)/1000))
		return mesh

# Sets the heights array for the triangle fan to draw
# the sq_heights is a global varialbe, in order to avoid allocating at every cycle
func set_squareHeights(hm_sbs_img = Image.new(), x = 0, y = 0, x_limiter = 0, y_limiter = 0, _offset = 0):
	sq_heights[0][0] = GetHeightFromPxl(hm_sbs_img.get_pixel(x, y)) - _offset
	sq_heights[1][0] = GetHeightFromPxl(hm_sbs_img.get_pixel(x + 1, y)) - _offset
	sq_heights[2][0] = GetHeightFromPxl(hm_sbs_img.get_pixel(x + 2 - x_limiter, y)) - _offset
	sq_heights[0][1] = GetHeightFromPxl(hm_sbs_img.get_pixel(x, y + 1)) - _offset
	sq_heights[0][2] = GetHeightFromPxl(hm_sbs_img.get_pixel(x, y + 2 - y_limiter)) - _offset
	sq_heights[1][1] = GetHeightFromPxl(hm_sbs_img.get_pixel(x + 1, y + 1)) - _offset
	sq_heights[1][2] = GetHeightFromPxl(hm_sbs_img.get_pixel(x + 1, y + 2 - y_limiter)) - _offset
	sq_heights[2][1] = GetHeightFromPxl(hm_sbs_img.get_pixel(x + 2 - x_limiter, y + 1)) - _offset
	sq_heights[2][2] = GetHeightFromPxl(hm_sbs_img.get_pixel(x + 2 - x_limiter, y + 2 - y_limiter)) - _offset
	
func setTriangleFanVertex(_x, _y, _xr, _yr, _dist, _height_scale, _half, _sq_heights):
	 return Vector3((_x+_xr - _half) * _dist, _sq_heights[_xr][_yr] * _height_scale , (_y+_yr - _half) * _dist)

func set_vertex_uv(_x, _y, _xr, _yr):
	return Vector2(float(_x+_xr)/float(width), float(_y+_yr)/float(heigth))
	
func generate_surface_from_array(_vertices, _uvs, _texture, _existing_mesh = null):
	surf_tool.clear()
	surf_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surf_tool.add_smooth_group(true)
	for i in range(_vertices.size()):
		surf_tool.add_rectangle(_vertices[i], _uvs[i])
	surf_tool.prepare_to_commit(SetMaterialTexture(_texture))
	return surf_tool.commit(_existing_mesh)
	
func set_mesh_fan(x, y, dist_proportion_b, height_scale, half_size, sq_heights, uv_offset_x = 0, uv_offset_y = 0):
	surf_tool.add_fan_element(setTriangleFanVertex(x, y, 1, 1, dist_proportion_b, height_scale, half_size, sq_heights)
							, set_vertex_uv(x + uv_offset_x, y + uv_offset_y, 1, 1))
	surf_tool.add_fan_element(setTriangleFanVertex(x, y, 0, 0, dist_proportion_b, height_scale, half_size, sq_heights)
							, set_vertex_uv(x + uv_offset_x, y + uv_offset_y, 0, 0))
	
	if sq_heights[0][0]-sq_heights[1][0] != sq_heights[1][0]-sq_heights[2][0]:
		surf_tool.add_fan_element(setTriangleFanVertex(x, y, 1, 0, dist_proportion_b, height_scale, half_size, sq_heights)
								, set_vertex_uv(x + uv_offset_x, y + uv_offset_y, 1, 0))
	
	surf_tool.add_fan_element(setTriangleFanVertex(x, y, 2, 0, dist_proportion_b, height_scale, half_size, sq_heights)
							, set_vertex_uv(x + uv_offset_x, y + uv_offset_y, 2, 0))
		
	if sq_heights[2][0]-sq_heights[2][1] != sq_heights[2][1]-sq_heights[2][2]:
		surf_tool.add_fan_element(setTriangleFanVertex(x, y, 2, 1, dist_proportion_b, height_scale, half_size, sq_heights)
								, set_vertex_uv(x + uv_offset_x, y + uv_offset_y, 2, 1))
	
	surf_tool.add_fan_element(setTriangleFanVertex(x, y, 2, 2, dist_proportion_b, height_scale, half_size, sq_heights)
							, set_vertex_uv(x + uv_offset_x, y + uv_offset_y, 2, 2))
		
	if sq_heights[2][2]-sq_heights[1][2] != sq_heights[1][2]-sq_heights[0][2]:
		surf_tool.add_fan_element(setTriangleFanVertex(x, y, 1, 2, dist_proportion_b, height_scale, half_size, sq_heights)
								, set_vertex_uv(x + uv_offset_x, y + uv_offset_y, 1, 2))
	
	surf_tool.add_fan_element(setTriangleFanVertex(x, y, 0, 2, dist_proportion_b, height_scale, half_size, sq_heights)
							, set_vertex_uv(x + uv_offset_x, y + uv_offset_y, 0, 2))
		
	if sq_heights[0][2]-sq_heights[0][1] != sq_heights[0][1]-sq_heights[0][0]:
		surf_tool.add_fan_element(setTriangleFanVertex(x, y, 0, 1, dist_proportion_b, height_scale, half_size, sq_heights)
								, set_vertex_uv(x + uv_offset_x, y + uv_offset_y, 0, 1))
	
	surf_tool.add_fan_element(setTriangleFanVertex(x, y, 0, 0, dist_proportion_b, height_scale, half_size, sq_heights)
							, set_vertex_uv(x + uv_offset_x, y + uv_offset_y, 0, 0))

func createMeshFromImage(_hm_img = Image.new(), _txtr_img = Image.new(), total_size = 0, height_multiplier = 1, Zoom = 1, _tilex = 0.0, _tiley = 0.0, _subset = 1, _divideinto = 4, _remove_offset = false, _mesh_path = null):
	var color_vertices = false
	var coords = _subsetToXYCoords(_subset, _divideinto)
	var lastvalx = 1
	if coords["x"] == _divideinto:
		lastvalx = -1
	var lastvaly = 1
	if coords["y"] == _divideinto:
		lastvaly = -1
	if !_hm_img.is_empty() && !_txtr_img.is_empty():
		var startt = float(OS.get_ticks_msec())
		var hm_sbs_img = _hm_img
		var txtr_sbs_img = _txtr_img
		if _divideinto > 1:
			hm_sbs_img = GetImageSubset(_hm_img, _divideinto, _subset, Vector2(lastvalx, lastvaly))
			txtr_sbs_img = GetImageSubset(_txtr_img, _divideinto, _subset, Vector2(lastvalx, lastvaly))
		
		max_min_height = GetMaxMinHight(hm_sbs_img)
		hm_sbs_img.lock()
		txtr_sbs_img.lock()
		width = hm_sbs_img.get_width()
		heigth = hm_sbs_img.get_height()
		var step_size = 2
		var rangeX = range(0,width, step_size)
		var rangeY = range(0,heigth, step_size)
		var x_limiter = 0
		var y_limiter = 0
		var pxl_mtrs_max = smf.adjust_dist_from_tile_zoom(earth_circ, _tilex, _tiley, Zoom)
#		if pxl_mtrs_max < smf.adjust_dist_from_tile_zoom(earth_circ, _tilex, _tiley+1, Zoom)):
#			pxl_mtrs_max = smf.adjust_dist_from_tile_zoom(earth_circ, _tilex, _tiley+1, Zoom)
		var pxl_mtrs_t = smf.adjust_dist_from_tile_zoom(earth_circ, _tilex, _tiley, Zoom)
		var pxl_mtrs_b = smf.adjust_dist_from_tile_zoom(earth_circ, _tilex, _tiley, Zoom)
		var pxl_mtrs_b2 = smf.adjust_dist_from_tile_zoom(earth_circ, _tilex, _tiley, Zoom)
		var size = float(heigth)
		if total_size == null:
			total_size = 0
		if total_size > 0:
			size = total_size
		var half_size = heigth /2.0
		var dist = float (size / width)
		var dist_proportion_t = dist * pxl_mtrs_t / pxl_mtrs_max
		var dist_proportion_b = dist * pxl_mtrs_b / pxl_mtrs_max
		var dist_proportion_b2 = dist * pxl_mtrs_b2 / pxl_mtrs_max
		# Altitude should be proportional to size
		# Height multiplier is used to enhace altitudes,
		# a value of 1 maintain real altitudes
		altitude_multiplier =  float(height_multiplier * dist / pxl_mtrs_t)
		var height_scale = altitude_multiplier * dist
		
		var txr_tl = Color()
		var txr_tr = Color()
		var txr_tr2 = Color()
		var txr_bl = Color()
		var txr_b2l = Color()
		var txr_br = Color()
		var txr_b2r = Color()
		var txr_br2 = Color()
		var txr_b2r2 = Color()
		
		var _adj_dist = false
		var side_x_vertices = []
		var side_x_uvs = []
		var side_y_vertices = []
		var side_y_uvs = []
		var side_xy_vertices = []
		var side_xy_uvs = []
		surf_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		surf_tool.add_smooth_group(true)
#		surf_tool.add_color(Color(1,1,1))
		for y in rangeY:
			if heigth-y <= 2:
				y_limiter = 1
			x_limiter = 0
			# getting adjusted distances
			# as it should change only on latitute change, 
			# we adjust it here in the y loop
			if _adj_dist:
				pxl_mtrs_t = smf.adjust_dist_from_tile_zoom(earth_circ, _tilex, float(_tiley) + float(y)/float(heigth), Zoom)
				pxl_mtrs_b = smf.adjust_dist_from_tile_zoom(earth_circ, _tilex, float(_tiley) + float(y+1)/float(heigth), Zoom)
				pxl_mtrs_b2 = smf.adjust_dist_from_tile_zoom(earth_circ, _tilex, float(_tiley) + float(y+2)/float(heigth), Zoom)
				dist_proportion_t = dist * pxl_mtrs_t / pxl_mtrs_max
				dist_proportion_b = dist * pxl_mtrs_b / pxl_mtrs_max
				dist_proportion_b2 = dist * pxl_mtrs_b2 / pxl_mtrs_max
				
			for x in rangeX:
				if width-x <= 2:
					x_limiter = 1
				set_squareHeights(hm_sbs_img, x, y, x_limiter, y_limiter, max_min_height.minh)
					
				if color_vertices:
					txr_tl = txtr_sbs_img.get_pixel(x, y)
					txr_tr = txtr_sbs_img.get_pixel(x + 1, y)
					txr_tr2 = txtr_sbs_img.get_pixel(x + 2 - x_limiter, y)
					txr_bl = txtr_sbs_img.get_pixel(x, y + 1)
					txr_b2l = txtr_sbs_img.get_pixel(x, y + 2 - y_limiter)
					txr_br = txtr_sbs_img.get_pixel(x + 1, y + 1)
					txr_b2r = txtr_sbs_img.get_pixel(x + 2 - x_limiter, y + 1)
					txr_br2 = txtr_sbs_img.get_pixel(x + 1, y + 2 - y_limiter)
					txr_b2r2 = txtr_sbs_img.get_pixel(x + 2 - x_limiter, y + 2 - y_limiter)
				
				set_mesh_fan(x, y, dist_proportion_b, altitude_multiplier, half_size, sq_heights)
				
				if x_limiter == 1 && y_limiter == 1:
					side_xy_vertices.append(surf_tool.arr_vtx)
					side_xy_uvs.append(surf_tool.arr_uvs)
					surf_tool.reset_fan()
				elif x_limiter == 1:
					side_x_vertices.append(surf_tool.arr_vtx)
					side_x_uvs.append(surf_tool.arr_uvs)
					surf_tool.reset_fan()
				elif y_limiter == 1:
					side_y_vertices.append(surf_tool.arr_vtx)
					side_y_uvs.append(surf_tool.arr_uvs)
					surf_tool.reset_fan()
				else:
					surf_tool.commit_fan()
		
		hm_sbs_img.unlock()
		txtr_sbs_img.unlock()
		surf_tool.prepare_to_commit(SetMaterialTexture(txtr_sbs_img))
		var mesh = surf_tool.commit()
		mesh.surface_set_name(mesh.get_surface_count()-1, "b")
		mesh = generate_surface_from_array(side_x_vertices, side_x_uvs, txtr_sbs_img, mesh)
		mesh.surface_set_name(mesh.get_surface_count()-1, "x")
		mesh = generate_surface_from_array(side_y_vertices, side_y_uvs, txtr_sbs_img, mesh)
		mesh.surface_set_name(mesh.get_surface_count()-1, "y")
		mesh = generate_surface_from_array(side_xy_vertices, side_xy_uvs, txtr_sbs_img, mesh)
		mesh.surface_set_name(mesh.get_surface_count()-1, "xy")
		
		var endtt = float(OS.get_ticks_msec())
		print("Mesh generation"
		+ " Tile " + var2str(_subset) + "/" + var2str(_divideinto * _divideinto)
		+ " X/Y: " + var2str(coords["x"]) + "/" + var2str(coords["y"])
		+ " Size: " + var2str(size)
		+ " Dist: " + var2str(dist)
		+ " Meters/Pixel: " + var2str(pxl_mtrs_max)
		+ " Min/Max Alt.: " + var2str(max_min_height.minh) + "/" + var2str(max_min_height.maxh)
		+ " finished in %.2f seconds" % ((endtt - startt)/1000))
		return mesh
		
func CreateMeshFromImage_sph(_hm_img = Image.new(), _txtr_img = Image.new(), total_size = 0, height_multiplier = 1, Zoom = 1, _tilex = 0, _tiley = 0, _subset = 1, _divideinto = 4, _remove_offset = false, _mesh_path = null):
	var color_vertices = false
	var coords = _subsetToXYCoords(_subset, _divideinto)
	var lastvalx = 1
	if coords["x"] == _divideinto:
		lastvalx = -1
	var lastvaly = 1
	if coords["y"] == _divideinto:
		lastvaly = -1
	if !_hm_img.is_empty() && !_txtr_img.is_empty():
		var surf_tool =  sth.new()#SurfaceTool.new()
		var startt = float(OS.get_ticks_msec())
		var hm_sbs_img = _hm_img
		var txtr_sbs_img = _txtr_img
		if _divideinto > 1:
			hm_sbs_img = GetImageSubset(_hm_img, _divideinto, _subset, Vector2(lastvalx, lastvaly))
			txtr_sbs_img = GetImageSubset(_txtr_img, _divideinto, _subset, Vector2(lastvalx, lastvaly))
		var max_min_h = GetMaxMinHight(hm_sbs_img)
		hm_sbs_img.lock()
		txtr_sbs_img.lock()
		var width = hm_sbs_img.get_width()
		var heigth = hm_sbs_img.get_height()
		var step_size = 2
		var rangeX = range(0,width, step_size)
		var rangeY = range(0,heigth, step_size)
		var x_limiter = 0
		var y_limiter = 0
		var pxl_mtrs_max = smf.adjust_dist_from_tile_zoom(earth_circ, _tilex, _tiley, Zoom)
		if pxl_mtrs_max < smf.adjust_dist_from_tile_zoom(earth_circ, _tilex, float(_tiley+1), Zoom):
			pxl_mtrs_max = smf.adjust_dist_from_tile_zoom(earth_circ, _tilex, float(_tiley+1), Zoom)
		var pxl_mtrs_t = smf.adjust_dist_from_tile_zoom(earth_circ, _tilex, float(_tiley), Zoom)
		var pxl_mtrs_b = smf.adjust_dist_from_tile_zoom(earth_circ, _tilex, float(_tiley), Zoom)
		var pxl_mtrs_b2 = smf.adjust_dist_from_tile_zoom(earth_circ, _tilex, float(_tiley), Zoom)
		var dist_proportion_t = pxl_mtrs_t / pxl_mtrs_max
		var dist_proportion_b = pxl_mtrs_b / pxl_mtrs_max
		var dist_proportion_b2 = pxl_mtrs_b2 / pxl_mtrs_max
			
		var size = float(heigth)
		if total_size == null:
			total_size = 0
		if total_size > 0:
			size = total_size
		var half_size = size /2.0
		
		var radius_factor = 5
		
		var txr_tl = Color()
		var txr_tr = Color()
		var txr_tr2 = Color()
		var txr_bl = Color()
		var txr_b2l = Color()
		var txr_br = Color()
		var txr_b2r = Color()
		var txr_br2 = Color()
		var txr_b2r2 = Color()
		
		var arr_vtx = PoolVector3Array()
		var arr_uvs = PoolVector2Array()
		var arr_cols = PoolColorArray()
		
		surf_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
#		surf_tool.add_color(Color(1,1,1))
		var ll = Vector3()
		for y in rangeY:
			if heigth-y <= 2:
				y_limiter = 1
			x_limiter = 0
			# getting adjusted distances
			# as it should change only on latitute change, 
			# we adjust it here in the y loop
			pxl_mtrs_t = smf.adjust_dist_from_tile_zoom(earth_circ, _tilex, float(_tiley) + float(y)/float(heigth), Zoom)
			pxl_mtrs_b = smf.adjust_dist_from_tile_zoom(earth_circ, _tilex, float(_tiley) + float(y+1)/float(heigth), Zoom)
			pxl_mtrs_b2 = smf.adjust_dist_from_tile_zoom(earth_circ, _tilex, float(_tiley) + float(y+2)/float(heigth), Zoom)
			dist_proportion_t = pxl_mtrs_t / pxl_mtrs_max
			dist_proportion_b = pxl_mtrs_b / pxl_mtrs_max
			dist_proportion_b2 = pxl_mtrs_b2 / pxl_mtrs_max
			for x in rangeX:
				if width-x <= 2:
					x_limiter = 1
				arr_vtx.resize(0)
				arr_uvs.resize(0)
				arr_cols.resize(0)
				set_squareHeights(hm_sbs_img, x, y, x_limiter, y_limiter, 0)
					
				if color_vertices:
					txr_tl = txtr_sbs_img.get_pixel(x, y)
					txr_tr = txtr_sbs_img.get_pixel(x + 1, y)
					txr_tr2 = txtr_sbs_img.get_pixel(x + 2 - x_limiter, y)
					txr_bl = txtr_sbs_img.get_pixel(x, y + 1)
					txr_b2l = txtr_sbs_img.get_pixel(x, y + 2 - y_limiter)
					txr_br = txtr_sbs_img.get_pixel(x + 1, y + 1)
					txr_b2r = txtr_sbs_img.get_pixel(x + 2 - x_limiter, y + 1)
					txr_br2 = txtr_sbs_img.get_pixel(x + 1, y + 2 - y_limiter)
					txr_b2r2 = txtr_sbs_img.get_pixel(x + 2 - x_limiter, y + 2 - y_limiter)
				
				ll = smf.tile_on_sphere_q2((sq_heights[1][1]*height_multiplier+smf.EARTH_RADIUS)/pxl_mtrs_max, float(_tilex), float(_tiley), float(x+1)/float(width+1), float(y+1)/float(heigth+1), Zoom)
				arr_vtx.append(ll)
				arr_uvs.append(Vector2(float(x+1)/float(width+1), float(y+1)/float(heigth+1)))
				
				ll = smf.tile_on_sphere_q2((sq_heights[0][0]*height_multiplier+smf.EARTH_RADIUS)/pxl_mtrs_max, float(_tilex), float(_tiley), float(x)/float(width+1), float(y)/float(heigth+1), Zoom)
				arr_vtx.append(ll)
				arr_uvs.append(Vector2(float(x)/float(width+1), float(y)/float(heigth+1)))
				if color_vertices:
					arr_cols.append(txr_br)
					arr_cols.append(txr_tl)
				
				if true:
					ll = smf.tile_on_sphere_q2((sq_heights[1][0]*height_multiplier+smf.EARTH_RADIUS)/pxl_mtrs_max, float(_tilex), float(_tiley), float(x+1)/float(width+1), float(y)/float(heigth+1), Zoom)
					arr_vtx.append(ll)
					arr_uvs.append(Vector2(float(x+1)/float(width+1), float(y)/float(heigth+1)))
					if color_vertices:
						arr_cols.append(txr_tr)
						
				ll = smf.tile_on_sphere_q2((sq_heights[2][0]*height_multiplier+smf.EARTH_RADIUS)/pxl_mtrs_max, float(_tilex), float(_tiley), float(x+2)/float(width+1), float(y)/float(heigth+1), Zoom)
				arr_vtx.append(ll)
				arr_uvs.append(Vector2(float(x+2)/float(width+1), float(y)/float(heigth+1)))
				if color_vertices:
					arr_cols.append(txr_tr2)
					
				if true:
					ll = smf.tile_on_sphere_q2((sq_heights[1][2]*height_multiplier+smf.EARTH_RADIUS)/pxl_mtrs_max, float(_tilex), float(_tiley), float(x+2)/float(width+1), float(y+1)/float(heigth+1), Zoom)
					arr_vtx.append(ll)
					arr_uvs.append(Vector2(float(x+2)/float(width+1), float(y+1)/float(heigth+1)))
					if color_vertices:
						arr_cols.append(txr_br2)
						
				ll = smf.tile_on_sphere_q2((sq_heights[2][2]*height_multiplier+smf.EARTH_RADIUS)/pxl_mtrs_max, float(_tilex), float(_tiley), float(x+2)/float(width+1), float(y+2)/float(heigth+1), Zoom)
				arr_vtx.append(ll)
				arr_uvs.append(Vector2(float(x+2)/float(width+1), float(y+2)/float(heigth+1)))
				if color_vertices:
					arr_cols.append(txr_b2r2)
					
				if true:
					ll = smf.tile_on_sphere_q2((sq_heights[1][2]*height_multiplier+smf.EARTH_RADIUS)/pxl_mtrs_max, float(_tilex), float(_tiley), float(x+1)/float(width+1), float(y+2)/float(heigth+1), Zoom)
					arr_vtx.append(ll)
					arr_uvs.append(Vector2(float(x+1)/float(width+1), float(y+2)/float(heigth+1)))
					if color_vertices:
						arr_cols.append(txr_b2r)
				
				ll = smf.tile_on_sphere_q2((sq_heights[0][2]*height_multiplier+smf.EARTH_RADIUS)/pxl_mtrs_max, float(_tilex), float(_tiley), float(x)/float(width+1), float(y+2)/float(heigth+1), Zoom)
				arr_vtx.append(ll)
				arr_uvs.append(Vector2(float(x)/float(width+1), float(y+2)/float(heigth+1)))
				if color_vertices:
					arr_cols.append(txr_b2l)
					
				if true:
					ll = smf.tile_on_sphere_q2((sq_heights[0][1]*height_multiplier+smf.EARTH_RADIUS)/pxl_mtrs_max, float(_tilex), float(_tiley), float(x)/float(width+1), float(y+1)/float(heigth+1), Zoom)
					arr_vtx.append(ll)
					arr_uvs.append(Vector2(float(x)/float(width+1), float(y+1)/float(heigth+1)))
					if color_vertices:
						arr_cols.append(txr_bl)
									
				ll = smf.tile_on_sphere_q2((sq_heights[0][0]*height_multiplier+smf.EARTH_RADIUS)/pxl_mtrs_max, float(_tilex), float(_tiley), float(x)/float(width+1), float(y)/float(heigth+1), Zoom)
				arr_vtx.append(ll)
				arr_uvs.append(Vector2(float(x)/float(width+1), float(y)/float(heigth+1)))
				if color_vertices:
					arr_cols.append(txr_tl)
				
				surf_tool.add_rectangle(arr_vtx, arr_uvs, arr_cols, false, true)
		
		hm_sbs_img.unlock()
		txtr_sbs_img.unlock()
		surf_tool.prepare_to_commit(SetMaterialTexture(txtr_sbs_img))
		var mesh = surf_tool.commit()
		
		var dist = float (size / width)
		
		var endtt = float(OS.get_ticks_msec())
		print("Mesh generation"
		+ " Tile " + var2str(_subset) + "/" + var2str(_divideinto * _divideinto)
		+ " X/Y: " + var2str(coords["x"]) + "/" + var2str(coords["y"])
		+ " Size: " + var2str(size)
		+ " Dist: " + var2str(dist)
		+ " Meters/Pixel: " + var2str(pxl_mtrs_max)
		+ " Min/Max Alt.: " + var2str(max_min_h.minh) + "/" + var2str(max_min_h.maxh)
		+ " finished in %.2f seconds" % ((endtt - startt)/1000))
		return mesh
		
func GetSideVertices(_mesh = ArrayMesh.new(), _side = Vector2()):
	var side_vertices = []
	var mdt = MeshDataTool.new()
	var error = mdt.create_from_surface(_mesh, 0)
	var mi = MeshInstance.new()
	mi.mesh = _mesh
	var mesh_aabb = mi.get_aabb()
	var plane_max = Vector3()
	var current_vertex = Vector3()
	for v in range(mdt.get_vertex_count()):
		current_vertex = mdt.get_vertex(v)
		if _side.x == -1):
			if current_vertex.x <= mesh_aabb.position.x):
				side_vertices.append([v, current_vertex])
				print([v, current_vertex])
		if _side.x == 1):
			if current_vertex.x >= mesh_aabb.end.x):
				side_vertices.append([v, current_vertex])
				print([v, current_vertex])
		if _side.y == -1):
			if current_vertex.z <= mesh_aabb.position.z):
				side_vertices.append([v, current_vertex])
				print([v, current_vertex])
		if _side.y == 1):
			if current_vertex.z >= mesh_aabb.end.z):
				side_vertices.append([v, current_vertex])
				print([v, current_vertex])
	return side_vertices

func AlterTerrainMesh(_mesh, _hmo, _hms, _hmb, _offset, _total_size, _height_multiplier, _txtr_sbs_img, _tilex, _tiley, _zoom):
	print("Altering terrain mesh...")
	if _mesh!= null && _hmo != null && (_hms != null || _hmb != null)):
		_hmo.lock()
		width = _hmo.get_width()
		heigth = _hmo.get_height()
		var _side = ""
		var x_limiter = 0
		var y_limiter = 0
		var pxl_mtrs_max = smf.adjust_dist_from_tile_zoom(earth_circ, _tilex, _tiley, _zoom)
#		if pxl_mtrs_max < smf.adjust_dist_from_tile_zoom(earth_circ, _tilex, _tiley+1, _zoom)):
#			pxl_mtrs_max = smf.adjust_dist_from_tile_zoom(earth_circ, _tilex, _tiley+1, _zoom)
		var size = float(heigth)
		if _total_size == null):
			_total_size = 0
		if _total_size > 0):
			size = _total_size
		var half_size = heigth /2.0
		var dist = float (size / width)
		var step_size = 2
		altitude_multiplier =  float(_height_multiplier * dist / pxl_mtrs_max)
		print(altitude_multiplier)
		print(_offset)
		var rangeX = range(0,width, step_size)
		var rangeY = range(0,heigth, step_size)
		surf_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		surf_tool.add_smooth_group(true)
		if _hms != null):
			_hms.lock()
			_side = "x"
			for y in rangeY:
				if heigth-y <= 2):
					y_limiter = 1
				sq_heights[0][0] = GetHeightFromPxl(_hmo.get_pixel(width - 2, y)) - _offset
				sq_heights[1][0] = GetHeightFromPxl(_hmo.get_pixel(width - 1, y)) - _offset
				sq_heights[2][0] = GetHeightFromPxl(_hms.get_pixel(0, y)) - _offset
				sq_heights[0][1] = GetHeightFromPxl(_hmo.get_pixel(width - 2, y + 1)) - _offset
				sq_heights[0][2] = GetHeightFromPxl(_hmo.get_pixel(width - 2, y + 2 - y_limiter)) - _offset
				sq_heights[1][1] = GetHeightFromPxl(_hmo.get_pixel(width - 1, y + 1)) - _offset
				sq_heights[1][2] = GetHeightFromPxl(_hmo.get_pixel(width - 1, y + 2 - y_limiter)) - _offset
				sq_heights[2][1] = GetHeightFromPxl(_hms.get_pixel(0, y + 1)) - _offset
				sq_heights[2][2] = GetHeightFromPxl(_hms.get_pixel(0, y + 2 - y_limiter)) - _offset
				set_mesh_fan(width-2, y, dist, altitude_multiplier, half_size, sq_heights, 0, 0)
				surf_tool.commit_fan()
			_hms.unlock()
		elif _hmb != null):
			_hmb.lock()
			_side = "y"
			for x in rangeX:
				if width-x <= 2):
					x_limiter = 1
				sq_heights[0][0] = GetHeightFromPxl(_hmo.get_pixel(x, heigth - 2)) - _offset
				sq_heights[1][0] = GetHeightFromPxl(_hmo.get_pixel(x + 1, heigth - 2)) - _offset
				sq_heights[2][0] = GetHeightFromPxl(_hmo.get_pixel(x + 2 - x_limiter, heigth - 2)) - _offset
				sq_heights[0][1] = GetHeightFromPxl(_hmo.get_pixel(x, heigth - 1)) - _offset
				sq_heights[0][2] = GetHeightFromPxl(_hmb.get_pixel(x, 0)) - _offset
				sq_heights[1][1] = GetHeightFromPxl(_hmo.get_pixel(x + 1, heigth - 1)) - _offset
				sq_heights[1][2] = GetHeightFromPxl(_hmb.get_pixel(x + 1, 0)) - _offset
				sq_heights[2][1] = GetHeightFromPxl(_hmo.get_pixel(x + 2 - x_limiter, heigth - 1)) - _offset
				sq_heights[2][2] = GetHeightFromPxl(_hmb.get_pixel(x + 2 - x_limiter, 0)) - _offset
				set_mesh_fan(x, heigth-2, dist, altitude_multiplier, half_size, sq_heights, 0, 0)
				surf_tool.commit_fan()
			_hmb.unlock()
		for s in range(_mesh.get_surface_count()):
			var surf_name = _mesh.surface_get_name(s)
			if surf_name == _side):
				print("Removing surface %s at# %d" % [surf_name, s])
				_mesh.surface_remove(s)
				break
		_hmo.unlock()
		surf_tool.prepare_to_commit(SetMaterialTexture(_txtr_sbs_img))
		_mesh = surf_tool.commit(_mesh)
		_mesh.surface_set_name(_mesh.get_surface_count()-1, _side)
		return _mesh
