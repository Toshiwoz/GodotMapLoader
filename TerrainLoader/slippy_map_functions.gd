extends Node
#	The following functions are the GDScript conversion of:
#	https://help.openstreetmap.org/questions/747/given-a-latlon-how-do-i-find-the-precise-position-on-the-tile


#	Metres per pixel math
#	---------------------
#	The distance represented by one pixel (S) is given by
#
#	    _circ is the (equatorial) circumference of the Earth
#	    _zoom is the zoom level
#	    _lat is the latitude of where you're interested in the scale.
static func adjust_dist_from_latzoom(_circ, _lat, _zoom):
	var s = abs(_circ * cos(_lat)/pow(2, _zoom+8))
	return s
	
static func get_height_from_color(col):
	return -10000 + ((col.r8 * 256 * 256 + col.g8 * 256 + col.b8) * 0.1)

static func latlon_to_tile(lat_deg, lon_deg, zoom):
	var lat_rad = deg2rad(lat_deg)
	var n = pow(2.0, zoom)
	var xtile_f = float((lon_deg + 180.0) / 360.0 * n)
	var ytile_f = float((1.0 - log(tan(lat_rad) + (1 / cos(lat_rad))) / PI) / 2.0 * n)
	var tilex = int(xtile_f)
	var tiley = int(ytile_f)
	var pxlx = int(256 * (xtile_f - tilex))
	var pxly = int(256 * (ytile_f - tiley))
	return {"tilex":tilex, "tiley":tiley,
			"pxlx":pxlx, "pxly":pxly}

static func LatLongToPixelXY(latitude, longitude, zoomLevel):
	var MinLatitude = -85.05112878
	var MaxLatitude = 85.05112878
	var MinLongitude = -180
	var MaxLongitude = 180
	var mapSize = pow(2, zoomLevel) * 256
	
	latitude = Clip(latitude, MinLatitude, MaxLatitude)
	longitude = Clip(longitude, MinLongitude, MaxLongitude)
	
	var p = Vector2()
	p.x = float((longitude + 180.0) / 360.0 * (1 << zoomLevel))
	p.y = float((1.0 - log(tan(latitude * PI / 180.0) + 1.0 / cos(deg2rad(latitude))) / PI) / 2.0 * (1 << zoomLevel))
	var tilex = int(p.x)
	var tiley = int(p.y)
	var pixelX = ClipByRange((tilex * 256) + ((p.x - tilex) * 256), mapSize - 1)
	var pixelY = ClipByRange((tiley * 256) + ((p.y - tiley) * 256), mapSize - 1)
	var result = {"tilex":tilex, "tiley":tiley, "x":pixelX, "y":pixelY}
	print(p)
	print((tilex * 256) + ((p.x - tilex) * 256))
	print((tiley * 256) + ((p.y - tiley) * 256))
	print(mapSize - 1)
	print(result)
	return result

static func PixelXYToLatLong(pixelX, pixelY, zoomLevel):
	var mapSize = pow(2, zoomLevel) * 256
	var tileX = round(pixelX / 256)
	var tileY = round(pixelY / 256)
	
	var n = PI - ((2.0 * PI * (ClipByRange(pixelY, mapSize - 1) / 256)) / pow(2.0, zoomLevel))
	
	var longitude = float(((ClipByRange(pixelX, mapSize - 1) / 256) / pow(2.0, zoomLevel) * 360.0) - 180.0)
	var latitude = float(180.0 / PI * atan(sinh(n)))
	return {"lon":longitude, "lat":latitude}

static func ClipByRange(n, _range):
	return fmod(n, _range)

static func Clip(n, minValue, maxValue):
	return min(max(n, minValue), maxValue)
