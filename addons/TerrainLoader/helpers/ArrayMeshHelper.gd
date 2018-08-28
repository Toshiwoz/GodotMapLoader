tool
extends ArrayMesh

func get_triangle_normal(a, b, c):
    # find the surface normal given 3 vertices
    var side1 = b - a
    var side2 = c - a
    var normal = side1.cross(side2)
    return normal
	
func add_single_square(_heights, sq_y, sq_x, _mt_pxl, _divide_by, _offset = 0.0):
	var sq_heights = PoolVector3Array()
	var sq_normals = PoolVector3Array()
	var sq_uvs = PoolVector3Array()
	var sq_indices = PoolIntArray()
	# if not first square we have to iterate from the previous pixels
	# so that each square is correctly joined
	var y_sq_not_first = 0
	var x_sq_not_first = 0
	if sq_y > 0:
		y_sq_not_first = 1
	if sq_x > 0:
		x_sq_not_first = 1
		
	var sq_heights_y_size = _heights.size()/_divide_by + y_sq_not_first
	var sq_heights_x_size = _heights[sq_y].size()/_divide_by + x_sq_not_first
	var heights_y_size = _heights.size()/_divide_by
	var heights_x_size = _heights[sq_y].size()/_divide_by
	# half size is used to center the geometry
	var half_y_size = sq_heights_y_size*_divide_by*_mt_pxl/2
	var half_x_size = sq_heights_x_size*_divide_by*_mt_pxl/2
	var y_heights_start = sq_y * heights_y_size- sq_y
	var x_heights_start = sq_x * heights_x_size - sq_x
	var y_heights_index = 0
	var x_height_index = 0
	var index = 0
	var indices_index = 0
	sq_heights.resize((sq_heights_y_size)*(sq_heights_x_size))
	sq_normals.resize((sq_heights_y_size)*(sq_heights_x_size))
	sq_uvs.resize((sq_heights_y_size)*(sq_heights_x_size))
	#parsing each height belonging to the square
	for h_y in range(0,sq_heights_y_size):
		y_heights_index = y_heights_start + h_y
		for h_x in range(0,sq_heights_x_size):
			x_height_index = x_heights_start + h_x
				
			#creating the vertex belonging to the MeshArray surface (the mesh is divided into _divide_by * _divide_by surfaces)
			sq_heights[index] = Vector3((x_height_index)*_mt_pxl-half_x_size, _heights[y_heights_index][x_height_index] - _offset, (y_heights_index)*_mt_pxl-half_y_size)
		
#			# Normals need to be calculated based on surrounding planes
			var normal_top_left = null
			var normal_top_right = null
			var normal_bottom_left = null
			var normal_bottom_right = null
			if h_x > 0 && h_y > 0:
				normal_top_left = get_triangle_normal(  sq_heights[(h_y) * (heights_y_size) + (h_x-1)]
														, sq_heights[(h_y-1) * (heights_y_size) + (h_x)]
														, sq_heights[(h_y) * (heights_y_size) + (h_x)])
			if h_x < sq_heights_x_size-1-x_sq_not_first && h_y > 0:
				normal_top_right = get_triangle_normal(  sq_heights[(h_y) * (heights_y_size) + (h_x)]
														, sq_heights[(h_y-1) * (heights_y_size) + (h_x)]
														, sq_heights[(h_y) * (heights_y_size) + (h_x+1)])
			if h_y < sq_heights_y_size-1-y_sq_not_first && h_x > 0:
				normal_bottom_left = get_triangle_normal(  sq_heights[(h_y) * (heights_y_size) + (h_x)]
														, sq_heights[(h_y+1) * (heights_y_size) + (h_x)]
														, sq_heights[(h_y) * (heights_y_size) + (h_x-1)])
			if h_y < sq_heights_y_size-1-y_sq_not_first && h_x < sq_heights_x_size-1-x_sq_not_first:
				normal_bottom_right = get_triangle_normal(  sq_heights[(h_y) * (heights_y_size) + (h_x)]
														, sq_heights[(h_y) * (heights_y_size) + (h_x+1)]
														, sq_heights[(h_y+1) * (heights_y_size) + (h_x)])
			if normal_top_left == null && normal_top_right == null && normal_bottom_left == null && normal_bottom_right != null:
				sq_normals[index] = normal_bottom_right
			elif normal_top_left == null && normal_top_right == null && normal_bottom_left != null && normal_bottom_right == null:
				sq_normals[index] = normal_bottom_left
			elif normal_top_left != null && normal_top_right == null && normal_bottom_left == null && normal_bottom_right == null:
				sq_normals[index] = normal_top_left
			elif normal_top_left == null && normal_top_right != null && normal_bottom_left == null && normal_bottom_right == null:
				sq_normals[index] = normal_top_right
				
			elif normal_top_left != null && normal_top_right != null && normal_bottom_left == null && normal_bottom_right == null:
				sq_normals[index] = normal_top_left.cross(normal_top_right)
			elif normal_top_left == null && normal_top_right != null && normal_bottom_left == null && normal_bottom_right != null:
				sq_normals[index] = normal_top_right.cross(normal_bottom_right)
			elif normal_top_left == null && normal_top_right == null && normal_bottom_left != null && normal_bottom_right != null:
				sq_normals[index] = normal_bottom_left.cross(normal_bottom_right)
			elif normal_top_left != null && normal_top_right == null && normal_bottom_left != null && normal_bottom_right == null:
				sq_normals[index] = normal_top_left.cross(normal_bottom_left)
			else:
				sq_normals[index] = normal_top_left.cross(normal_top_right).cross(normal_bottom_left.cross(normal_bottom_right))
			
			#Create non empty UV only if on corners
			if h_y == 0 && h_x == 0:
				sq_uvs[index] = Vector3(x_height_index/_heights[sq_y].size(), 0, y_heights_index/_heights.size())
#				print(["tile",sq_y,sq_x,"corner 00",y_heights_index, x_height_index])
			elif h_y == sq_heights_y_size-1  && h_x == 0:
				sq_uvs[index] = Vector3(x_height_index/_heights[sq_y].size(), 0, y_heights_index/_heights.size())
#				print(["corner 10",y_heights_index, x_height_index])
			elif h_y == 0  && h_x == sq_heights_x_size-1:
				sq_uvs[index] = Vector3(x_height_index/_heights[sq_y].size(), 0, y_heights_index/_heights.size())
#				print(["corner 01",y_heights_index, x_height_index])
			elif h_y == sq_heights_y_size-1  && h_x == sq_heights_x_size-1:
				sq_uvs[index] = Vector3(x_height_index/_heights[sq_y].size(), 0, y_heights_index/_heights.size())
#				print(["corner 11",y_heights_index, x_height_index])
			else:
				sq_uvs[index] = Vector3()
				
			if h_y > 0 && h_x > 0:
				# Generate the vertices index
				# drawing 2 triangles as follows
				# 1-2			  2
				# |/ 	then	 /|
				# 3  	    	1-3
				sq_indices.append((h_y-1) * sq_heights_y_size + (h_x-1))
				sq_indices.append((h_y-1) * sq_heights_y_size + (h_x))
				sq_indices.append((h_y) * sq_heights_y_size + (h_x-1))
				sq_indices.append((h_y) * sq_heights_y_size + (h_x-1))
				sq_indices.append((h_y-1) * sq_heights_y_size + (h_x))
				sq_indices.append((h_y) * sq_heights_y_size + (h_x))
				
			index += 1
	return {heights=sq_heights, normals=sq_normals, indices=sq_indices, uv=sq_uvs}

#	This function should convert the single array into groups of arrays 
#	each group is an 8th in width and height
#	heights should also be a square with a 2^x value, and a minimum size of 8x8
#	Ie. 8, 16, 32, 64, etc.
func heights_to_squares_array(_heights = Array(), _mat = Material.new(), _divide_by = 8, _mtpxl = 1.0, _offset = 0.0):
	var startt = float(OS.get_ticks_msec())
	while get_surface_count() > 0:
		surface_remove(get_surface_count()-1)
	var heights_squares = Array()
	heights_squares.resize(_divide_by)
	#parsing each of the _divide_by squares
	for sq_y in range(_divide_by):
		heights_squares[sq_y] = Array()
		heights_squares[sq_y].resize(_divide_by)
		for sq_x in range(_divide_by):
			#append the fan to the squares array
			heights_squares[sq_y][sq_x] = add_single_square(_heights, sq_y, sq_x, _mtpxl, _divide_by, _offset)
			var mesh_array = Array()
			mesh_array.resize(ArrayMesh.ARRAY_MAX)
			mesh_array[ArrayMesh.ARRAY_VERTEX] = heights_squares[sq_y][sq_x].heights
			mesh_array[ArrayMesh.ARRAY_NORMAL] = heights_squares[sq_y][sq_x].normals
			mesh_array[ArrayMesh.ARRAY_INDEX] = heights_squares[sq_y][sq_x].indices
			mesh_array[ArrayMesh.ARRAY_TEX_UV] = heights_squares[sq_y][sq_x].uv
			add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_array)
			var surfidx = get_surface_count()-1
			surface_set_name(surfidx, var2str(sq_y)+";"+var2str(sq_x))
			surface_set_material(surfidx, _mat)
	var endtt = float(OS.get_ticks_msec())
	print("Squares of heights generated in %.2f seconds" % ((endtt - startt)/1000))
	return heights_squares

#func HeightMapToRectangle(_hm = Array(), _divide_by = 8, _mat = SpatialMaterial.new()):
#	if _hm.size() > 0:
#		var fan_array = PoolVector3Array()
#		var fan_normal_array = PoolVector3Array()
#		var fan_index_array = PoolIntArray()
#		var array_mesh = Array()
#		array_mesh.resize(Mesh.ARRAY_MAX)
#		var height = _hm.size()
#		var width = _hm[0].size()
#		print("Height %d, Width %d" % [height, width])
#
#		var rangey = range(2, height, 2)
#		var rangex = range(2, width, 2)
#
#		for y in rangey:
#			for x in rangex:
#				fan_array.resize(0)
#				fan_index_array.resize(0)
#				fan_normal_array.resize(0)
#				fan_index_array.append(_hm[y][x+1])
#				fan_index_array.append(Vector3(x, _hm[y][x], y))
#				fan_index_array.append(Vector3(x+1, _hm[y][x+1-x_limiter1], y))
#				fan_index_array.append(Vector3(x+2, _hm[y][x+2-x_limiter2], y))
#				fan_index_array.append(Vector3(x+2, _hm[y+1-y_limiter1][x+2-x_limiter2], y+1))
#				fan_index_array.append(Vector3(x+2, _hm[y+2-y_limiter2][x+2-x_limiter2], y+2))
#				fan_index_array.append(Vector3(x+1, _hm[y+2-y_limiter2][x+1-x_limiter1], y+2))
#				fan_index_array.append(Vector3(x, _hm[y+2-y_limiter2][x], y+2))
#				fan_index_array.append(Vector3(x, _hm[y+1-y_limiter1][x], y+1))
#				fan_index_array.append(Vector3(x, _hm[y][x], y))
#
#				fan_normal_array.append(Vector3(0, 1, 0))
#				fan_normal_array.append(Vector3(0, 1, 0))
#				fan_normal_array.append(Vector3(0, 1, 0))
#				fan_normal_array.append(Vector3(0, 1, 0))
#				fan_normal_array.append(Vector3(0, 1, 0))
#				fan_normal_array.append(Vector3(0, 1, 0))
#				fan_normal_array.append(Vector3(0, 1, 0))
#				fan_normal_array.append(Vector3(0, 1, 0))
#				fan_normal_array.append(Vector3(0, 1, 0))
#				fan_normal_array.append(Vector3(0, 1, 0))
##				print("Fan Size: %d" % [fan_array.size()])
#				array_mesh[ARRAY_VERTEX] = fan_array
#				array_mesh[ARRAY_NORMAL] = fan_normal_array
#				array_mesh[ARRAY_INDEX] = fan_index_array
#				add_surface_from_arrays(PRIMITIVE_TRIANGLE_FAN, array_mesh)
#				var surfidx = get_surface_count()-1
#				surface_set_name(surfidx, var2str(y)+";"+var2str(x))
#				surface_set_material(surfidx, _mat)
