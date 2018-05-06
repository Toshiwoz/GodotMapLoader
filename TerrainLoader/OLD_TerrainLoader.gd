extends Node

func GenerateArrayMesh(_heightMap):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)

	var width = _heightMap[0].size()
	var heigth = _heightMap.size()
	var minx = -width/2
	var miny = -heigth/2
	var AlternateVal = false
	for y in range(heigth):
		if(y < heigth - 2):
			var xRng = range(width);
			if(AlternateVal):
				xRng = range(width - 1, 0, -1)
			for x in xRng:
				var vx1 = x + minx
				var vy1 = y + miny
				var vz1 = _heightMap[y][x] * HeigthMultiplier
				var vx2 = x + minx
				var vy2 = (y + 1) + miny
				var vz2 = _heightMap[y + 1][x]  * HeigthMultiplier
				if(!AlternateVal):
					st.add_vertex(Vector3(vx1, vz1, vy1))
					st.add_vertex(Vector3(vx2, vz2, vy2))
				else:
					if(x < (width - 2)):
						st.add_vertex(Vector3(vx1, vz1, vy1))
					st.add_vertex(Vector3(vx2, vz2, vy2))
#				st.add_color(pxl1)
			#	st.add_uv(Vector2(0, 0))
			AlternateVal = !AlternateVal

	st.generate_normals()
	var material = ResourceLoader.load("res://TerrainLoader/TerrainMaterial.tres")
	st.set_material(material)
	var TerrMesh = st.commit()
	$TerrainMesh.mesh = TerrMesh

