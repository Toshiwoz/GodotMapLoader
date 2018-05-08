tool
extends Spatial

var earth_mat = preload("res://TerrainLoader/TerrainMaterial.tres")
var smf = preload("res://TerrainLoader/slippy_map_functions.gd")
var earth_circ = smf.radius_to_circ(smf.EARTH_RADIUS)

func _init():
	smf = preload("res://TerrainLoader/slippy_map_functions.gd")

#	_subset should be from 1 to _divideinto * _divideinto
#	_divideinto should be from 1 to 100
#	(considering an image of max 512x512px)
func GenerateHeightMap(_hm_img, _txtr_img, _subset, _divideinto):
	var hm = []
	var coords = _subsetToXYCoords(_subset, _divideinto)
	var lastvalx = 1
	if(coords["x"] == _divideinto):
		lastvalx = -1
	var lastvaly = 1
	if(coords["y"] == _divideinto):
		lastvaly = -1
	if(!_hm_img.is_empty() && !_txtr_img.is_empty()):
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
				if(altitude < minh):
					minh = altitude
				if(altitude > maxh):
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
	
static func _subsetToXYCoords(_subset, _divideinto):
	var subsetX = 1
	var subsetY = 1
	for ss in range(1, _subset):
		subsetX += 1
		if(subsetX > _divideinto):
			subsetY += 1
			subsetX = 1
	
#	print("Subset: " + var2str(_subset) + " - Divide into: " + var2str(_divideinto)
#	+ " | Y:" + var2str(subsetY) + " - X:" + var2str(subsetX))
	return {"x":subsetX, "y":subsetY}
	
static func GetPixelDistance(_heightMap, _totalSize):
	var dist = 0
	if(_heightMap != null):
		var hmSize = float(_heightMap.size())
		var tileSize = hmSize
		if(_totalSize == null):
			_totalSize = 0
		if(_totalSize > 0):
			tileSize = _totalSize
		dist = float (tileSize / hmSize)
	return dist
	
static func GetHeightFromPxl(_pxl):
	return -10000 + ((_pxl.r8 * 256 * 256 + _pxl.g8 * 256 + _pxl.b8) * 0.1)

func createMesh(ht, total_size = 0, height_multiplier = 1, Zoom = 1, _subset = 1, _divideinto = 4, _trimheight = false, _mesh_path = null):
	if(_mesh_path != null):
		var _stored_mesh = ResourceLoader(_mesh_path)
		if(_stored_mesh != null):
			return _stored_mesh
	if(ht.size() > 0):
		var startt = float(OS.get_ticks_msec())
		var surf_tool = SurfaceTool.new()
		var width = ht.size()
		var lenght = ht[0].size()
		print("Length %d - Width %d" % [lenght, width])
		var pxl_mtrs = smf.adjust_dist_from_latzoom(earth_circ, 0, Zoom)
		var size = float(ht.size())
		if(total_size == null):
			total_size = 0
		if(total_size > 0):
			size = total_size
		var half_size = size /2.0
		var dist = float (size / width)
		var minh = 0
		var maxh = 0
		# Altitude should be proportional to size
		# Height multiplier is used to enhace altitudes,
		# a value of 1 maintain real altitudes
		var altitude_multiplier =  float(height_multiplier * dist / pxl_mtrs)
		var x = 0
		if(ht):
			surf_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			for i in range (width-1):
				for j in range (lenght-1):
					if(maxh < ht[i][j]["height"] * altitude_multiplier):
						maxh = ht[i][j]["height"] * altitude_multiplier
					if(minh > ht[i][j]["height"] * altitude_multiplier):
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
#		var mesh_path = "res://mesh_lat" + var2str(latitude) + "_lon" + var2str(longitude) + "_tile" + var2str(Subset) + ".tres"
#		ResourceSaver.save(mesh_path, mesh)
#		$TerrainMesh.mesh = ResourceLoader.load(mesh_path)
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

func createMeshFromImage(_hm_img = Image.new(), _txtr_img = Image.new(), total_size = 0, height_multiplier = 1, Zoom = 1, _tilex = 0, _tiley = 0, _subset = 1, _divideinto = 4, _remove_offset = false, _mesh_path = null):
	var color_vertices = false
	var coords = _subsetToXYCoords(_subset, _divideinto)
	var lastvalx = 1
	if(coords["x"] == _divideinto):
		lastvalx = -1
	var lastvaly = 1
	if(coords["y"] == _divideinto):
		lastvaly = -1
	if(!_hm_img.is_empty() && !_txtr_img.is_empty()):
		var surf_tool = SurfaceTool.new()
		var startt = float(OS.get_ticks_msec())
		var hm_sbs_img = GetImageSubset(_hm_img, _divideinto, _subset, Vector2(lastvalx, lastvaly))
		var txtr_sbs_img = GetImageSubset(_txtr_img, _divideinto, _subset, Vector2(lastvalx, lastvaly))
		hm_sbs_img.lock()
		txtr_sbs_img.lock()
		var width = hm_sbs_img.get_width()
		var heigth = hm_sbs_img.get_height()
		var rangeX = range(width - 1)
		var rangeY = range(heigth - 1)
		var minh = 999999
		var maxh = 0
				
		var lat_lon_t = smf.tile_to_latlon(_tilex, _tiley, Zoom)
		var lat_lon_b = smf.tile_to_latlon(_tilex, _tiley, Zoom)
		var pxl_mtrs_max = smf.adjust_dist_from_latzoom(earth_circ, 0, Zoom)
		var pxl_mtrs_t = smf.adjust_dist_from_latzoom(earth_circ, lat_lon_t["lat"], Zoom)
		var pxl_mtrs_b = smf.adjust_dist_from_latzoom(earth_circ, lat_lon_b["lat"], Zoom)
		var size = float(heigth)
		if(total_size == null):
			total_size = 0
		if(total_size > 0):
			size = total_size
		var half_size = size /2.0
		var dist = float (size / width)
		var dist_proportion_t = dist * pxl_mtrs_t / pxl_mtrs_max
		var dist_proportion_b = dist * pxl_mtrs_b / pxl_mtrs_max
		# Altitude should be proportional to size
		# Height multiplier is used to enhace altitudes,
		# a value of 1 maintain real altitudes
		var altitude_multiplier =  float(height_multiplier * dist / pxl_mtrs_t)
		surf_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
#		surf_tool.add_color(Color(1,1,1))
		
		var txr_tl = Color()
		var txr_tr = Color()
		var txr_bl = Color()
		var txr_br = Color()
		var alt_tl = float(0)
		var alt_tr = float(0)
		var alt_bl = float(0)
		var alt_br = float(0)

		var bottomleft = Vector3()
		var upperleft = Vector3()
		var upperright = Vector3()
		var bottomright = Vector3()
				
		for y in rangeY:
			for x in rangeX:
				alt_tl = GetHeightFromPxl(hm_sbs_img.get_pixel(x, y))
				if(alt_tl < minh):
					minh = alt_tl
				if(alt_tl > maxh):
					maxh = alt_tl
		for y in rangeY:
			# getting adjusted distances
			# as it should change only on latitute change, we adjust it here
			lat_lon_t = smf.tile_to_latlon(_tilex, float(_tiley) + float(y)/float(width), Zoom)
			lat_lon_b = smf.tile_to_latlon(_tilex, float(_tiley) + float(y + 1)/float(width), Zoom)
			pxl_mtrs_t = smf.adjust_dist_from_latzoom(earth_circ, lat_lon_t["lat"], Zoom)
			pxl_mtrs_b = smf.adjust_dist_from_latzoom(earth_circ, lat_lon_b["lat"], Zoom)
			altitude_multiplier =  float(height_multiplier * dist / pxl_mtrs_max)
			dist_proportion_t = dist * pxl_mtrs_t / pxl_mtrs_max
			dist_proportion_b = dist * pxl_mtrs_b / pxl_mtrs_max
			print("For Tile x=%f y=%f Dist T: %f, b: %f" % [_tilex, float(_tiley) + float(y)/float(width), dist_proportion_t, dist_proportion_b])
			for x in rangeX:
				if(color_vertices):
					txr_tl = txtr_sbs_img.get_pixel(x, y)
					txr_tr = txtr_sbs_img.get_pixel(x + 1, y)
					txr_bl = txtr_sbs_img.get_pixel(x, y + 1)
					txr_br = txtr_sbs_img.get_pixel(x + 1, y + 1)
				if(_remove_offset):
					alt_tl = GetHeightFromPxl(hm_sbs_img.get_pixel(x, y)) - minh
					alt_tr = GetHeightFromPxl(hm_sbs_img.get_pixel(x + 1, y)) - minh
					alt_bl = GetHeightFromPxl(hm_sbs_img.get_pixel(x, y + 1)) - minh
					alt_br = GetHeightFromPxl(hm_sbs_img.get_pixel(x + 1, y + 1)) - minh
				else:
					alt_tl = GetHeightFromPxl(hm_sbs_img.get_pixel(x, y))
					alt_tr = GetHeightFromPxl(hm_sbs_img.get_pixel(x + 1, y))
					alt_bl = GetHeightFromPxl(hm_sbs_img.get_pixel(x, y + 1))
					alt_br = GetHeightFromPxl(hm_sbs_img.get_pixel(x + 1, y + 1))

				bottomleft = Vector3((x - half_size) * dist_proportion_b, alt_bl * altitude_multiplier, (y + 1) * dist - half_size)
				upperleft = Vector3((x - half_size) * dist_proportion_t, alt_tl * altitude_multiplier, (y) * dist - half_size)
				upperright = Vector3((x + 1 - half_size) * dist_proportion_t, alt_tr * altitude_multiplier, (y) * dist - half_size)
				bottomright = Vector3((x + 1 - half_size) * dist_proportion_b, alt_br * altitude_multiplier, (y + 1) * dist - half_size)
				if(color_vertices):
					surf_tool.add_color(txr_tl)
				surf_tool.add_smooth_group(true)
				surf_tool.add_uv(Vector2(float(x)/float(width), float(y)/float(heigth)))
				surf_tool.add_vertex(upperleft)
				if(color_vertices):
					surf_tool.add_color(txr_tr)
				surf_tool.add_smooth_group(true)
				surf_tool.add_uv(Vector2(float(x+1)/float(width), float(y)/float(heigth)))
				surf_tool.add_vertex(upperright)
				
				if(color_vertices):
					surf_tool.add_color(txr_br)
				surf_tool.add_smooth_group(true)
				surf_tool.add_uv(Vector2(float(x+1)/float(width), float(y+1)/float(heigth)))
				surf_tool.add_vertex(bottomright)
				
				if(color_vertices):
					surf_tool.add_color(txr_tl)
				surf_tool.add_smooth_group(true)
				surf_tool.add_uv(Vector2(float(x)/float(width), float(y)/float(heigth)))
				surf_tool.add_vertex(upperleft)

				if(color_vertices):
					surf_tool.add_color(txr_tr)
				surf_tool.add_smooth_group(true)
				surf_tool.add_uv(Vector2(float(x+1)/float(width), float(y+1)/float(heigth)))
				surf_tool.add_vertex(bottomright)
				
				if(color_vertices):
					surf_tool.add_color(txr_bl)
				surf_tool.add_smooth_group(true)
				surf_tool.add_uv(Vector2(float(x)/float(width), float(y+1)/float(heigth)))
				surf_tool.add_vertex(bottomleft)
			
		hm_sbs_img.unlock()
		txtr_sbs_img.unlock()
		surf_tool.generate_normals()
		surf_tool.index()
		
		var imgtxtr = ImageTexture.new()
		var mat = earth_mat.duplicate() #SpatialMaterial.new()
		imgtxtr.create_from_image(txtr_sbs_img)
		mat.albedo_texture = imgtxtr
#		material.albedo_texture = imgtxtr
		surf_tool.set_material(mat)
		var mesh = surf_tool.commit()
		var endtt = float(OS.get_ticks_msec())
		print("Mesh generation"
		+ " Tile " + var2str(_subset) + "/" + var2str(_divideinto * _divideinto)
		+ " X/Y: " + var2str(coords["x"]) + "/" + var2str(coords["y"])
		+ " Size: " + var2str(size)
		+ " Dist: " + var2str(dist)
		+ " Meters/Pixel: " + var2str(pxl_mtrs_max)
		+ " Min/Max Alt.: " + var2str(minh) + "/" + var2str(maxh)
		+ " finished in %.2f seconds" % ((endtt - startt)/1000))
		return mesh

func GetImageSubset(_image, _divideinto, _subset, _addpixel = Vector2(0, 0)):
	if(_image != null):
		var coords = _subsetToXYCoords(_subset, _divideinto)
		var imgsswidth = _image.get_width() / _divideinto
		var imgssheight = _image.get_height() / _divideinto
		var imgstart = Vector2( imgsswidth * (coords["x"] - 1),
								imgssheight * (coords["y"] - 1))
		var imgssize = Vector2(imgsswidth + _addpixel.x, imgssheight + _addpixel.y)
		var imgsbst = _image.get_rect(Rect2(imgstart, imgssize))
		return imgsbst

func SetPixelVertices(_hmPicture = Image.new(), _xpxl = 0, _ypxl = 0, _meshdatatool = MeshDataTool.new(), _altitude_multiplier = 1):
		var imgw = _hmPicture.get_width()
		var vidx = 0
		var rng = 6
		if(_xpxl == imgw - 2):
			rng = 3
		elif(_xpxl > 0 && _xpxl < imgw):
			rng = 4
		vidx = ((imgw) * 4 + 11) * _ypxl + _xpxl * rng - rng
		print(vidx)
		var vtx = Vector3()
		var pxl_tl = _hmPicture.get_pixel(_xpxl, _ypxl)
		var pxl_tr = _hmPicture.get_pixel(_xpxl + 1, _ypxl)
		var pxl_bl = _hmPicture.get_pixel(_xpxl, _ypxl + 1)
		var pxl_br = _hmPicture.get_pixel(_xpxl + 1, _ypxl + 1)
		for vx in range(rng):
			vtx = _meshdatatool.get_vertex(vidx + vx)
			match vx:
				0:
					vtx.y = smf.get_height_from_color(pxl_tl) * _altitude_multiplier
				1:
					vtx.y = smf.get_height_from_color(pxl_tr) * _altitude_multiplier
				2:
					vtx.y = smf.get_height_from_color(pxl_bl) * _altitude_multiplier
				3:
					vtx.y = smf.get_height_from_color(pxl_tr) * _altitude_multiplier
				4:
					vtx.y = smf.get_height_from_color(pxl_br) * _altitude_multiplier
				5:
					vtx.y = smf.get_height_from_color(pxl_bl) * _altitude_multiplier
			_meshdatatool.set_vertex(vidx + vx, vtx)
		return smf.get_height_from_color(pxl_tl)
