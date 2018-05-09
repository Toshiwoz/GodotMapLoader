extends SurfaceTool

func _init():
	pass

func add_rectangle(_vertices = PoolVector3Array(), _uvs = PoolVector3Array(), _colors = PoolColorArray(), _color_vertices = false, _smooth = false):
	self.add_smooth_group(_smooth)
	if(_color_vertices):
		self.add_triangle_fan(_vertices, _uvs, _colors)
	else:
		self.add_triangle_fan(_vertices, _uvs)
#	for idx in range(_vertices.size()):
#		if(_color_vertices):
#			self.add_color(_colors[idx])
#		self.add_smooth_group(_smooth)
#		self.add_uv(_uvs[idx])
#		self.add_vertex(_vertices[idx])
