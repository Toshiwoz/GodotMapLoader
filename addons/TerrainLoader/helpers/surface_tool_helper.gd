extends SurfaceTool

var arr_vtx = PoolVector3Array()
var arr_uvs = PoolVector2Array()
var arr_cols = PoolColorArray()

func _init():
	pass
	
func add_fan_element(_vtx, _uv, _col = null):
	arr_vtx.append(_vtx)
	arr_uvs.append(_uv)
	if(_col != null):
		arr_cols.append(_col)
	
func reset_fan():
	arr_vtx.resize(0)
	arr_uvs.resize(0)
	arr_cols.resize(0)
	
func commit_fan():
	add_triangle_fan(arr_vtx, arr_uvs, arr_cols)
	reset_fan()
	
func prepare_to_commit( _material, _index = true):
	if(_index):
		index()
	generate_normals()
	set_material(_material)

func add_rectangle(_vertices = PoolVector3Array(), _uvs = PoolVector3Array(), _colors = PoolColorArray(), _color_vertices = false, _smooth = false):
#	self.add_smooth_group(_smooth)
	if(_color_vertices):
		add_triangle_fan(_vertices, _uvs, _colors)
	else:
		add_triangle_fan(_vertices, _uvs)
