tool
extends Spatial
var hmp = preload("res://TerrainLoader/HeightmapParser.gd")

export(int, 1, 512) onready var size setget _setPlaneSize
export(int, 0, 999999) onready var vertex setget _setVertex
export(String, FILE, "*.png, *.jpg, *.jpeg") onready var MapHeight
export(String, FILE, "*.png, *.jpg, *.jpeg") onready var MapTexture
export(int, 1, 8, 1) onready var Divideinto
export(int, 1, 16, 1) onready var Subset setget _setSubset
export(int, 1, 15, 1) onready var Zoom
export(String, "Tmesh", "MeshInstance") onready var SelectedMesh

func _setVertex(_newval):
	if($MeshInstance.mesh != null
	&& $Tmesh != null):
		var mdt = MeshDataTool.new()
		var st = SurfaceTool.new()
		if(SelectedMesh == "MeshInstance"):
			mdt.create_from_surface($MeshInstance.mesh, 0)
		else:
			mdt.create_from_surface($Tmesh.mesh, 0)
	
		if(_newval >= mdt.get_vertex_count()):
			_newval = mdt.get_vertex_count() - 1
		vertex = _newval
		var vtx = mdt.get_vertex(vertex)
		var vtx_uv = mdt.get_vertex_uv(vertex)
		vtx.y = vtx.y + 1
		$Arrow.translation = vtx
		print(vtx)
		print(vtx_uv)

func GetImageSubset(_image, _divideinto, _subset):
	if(_image != null):
		var coords = _subsetToXYCoords(_subset, _divideinto)
		var imgsswidth = _image.get_width() / _divideinto
		var imgssheight = _image.get_height() / _divideinto
		var imgstart = Vector2( imgsswidth * (coords["x"] - 1),
								imgssheight * (coords["y"] - 1))
		var imgssize = Vector2(imgsswidth, imgssheight)
		var imgsbst = _image.get_rect(Rect2(imgstart, imgssize))
		return imgsbst

func _setSubset(_newval):
	if(_newval > Divideinto * Divideinto):
		Subset = Divideinto * Divideinto
	else:
		Subset = _newval
	if(MapTexture != null && MapHeight != null):
		var hmTool = hmp.new()
		var mhImage = Image.new()
		mhImage.load(MapHeight)
		var mtImage = Image.new()
		mtImage.load(MapTexture)
		var tmesh = hmTool.createMeshFromImage(mhImage, mtImage, 0, 1, Zoom, Subset, Divideinto, true)
		$Tmesh.mesh = tmesh
		
func _setPlaneSize(_newval):
	size = _newval
	print([size, _newval])
	var startt = float(OS.get_ticks_msec())
	var mdt = MeshDataTool.new()
	var st = SurfaceTool.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.subdivide_width = _newval
	plane_mesh.subdivide_depth = _newval
	plane_mesh.size = Vector2(_newval, _newval)
	st.create_from(plane_mesh, 0)
	var array_plane = st.commit()
	var error = mdt.create_from_surface(array_plane, 0)
	for i in range(mdt.get_vertex_count()):
		var vtx = mdt.get_vertex(i)
		vtx.y = randf() * 1
		mdt.set_vertex(i, vtx)
	for s in range(array_plane.get_surface_count()):
		array_plane.surface_remove(s)
	mdt.commit_to_surface(array_plane)
	st.create_from(array_plane, 0)
	st.generate_normals()
	$MeshInstance.mesh = st.commit()
	var endtt = float(OS.get_ticks_msec())
	print("Execution time: %.2f" % ((endtt - startt)/1000))

static func _subsetToXYCoords(_subset, _divideinto):
	var subsetX = 1
	var subsetY = 1
	for ss in range(1, _subset):
		subsetX += 1
		if(subsetX > _divideinto):
			subsetY += 1
			subsetX = 1
	return {"x":subsetX, "y":subsetY}

#func _ready():
#	_setTrigger(true)
