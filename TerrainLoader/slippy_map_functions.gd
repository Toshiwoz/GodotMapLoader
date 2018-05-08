extends Object
#	The following functions are the GDScript conversion of:
#	https://help.openstreetmap.org/questions/747/given-a-latlon-how-do-i-find-the-precise-position-on-the-tile

const EARTH_RADIUS = 6371000
const MAX_LAT = 85.0511

static func radius_to_circ(_rad):
	return float(_rad) * 2 * PI

#	Metres per pixel math
#	---------------------
#	The distance represented by one pixel (S) is given by
#
#	    _circ is the (equatorial) circumference of the Earth
#	    _zoom is the zoom level
#	    _lat is the latitude of where you're interested in the scale.
static func adjust_dist_from_latzoom(_circ, _lat, _zoom):
	var s = abs(float(_circ) * cos(float(deg2rad(_lat)))/pow(2, _zoom+8))
	return s
	
static func get_height_from_color(col):
	return -10000 + ((col.r8 * 256 * 256 + col.g8 * 256 + col.b8) * 0.1)

static func calc_max_lon(_lat):
	return _lat * PI / 180
	
static func latlon_to_tile_pxl(lat_deg, lon_deg, zoom):
	if(abs(lat_deg) > MAX_LAT):
		lat_deg = sign(lat_deg) * MAX_LAT
#	if(abs(lon_deg) > MAX_LON):
#		lon_deg = sign(lon_deg) * MAX_LON
		
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

static func tile_to_latlon(_tilex, _tiley, _zoom):
	var n = pow(2.0, _zoom)
	var lon = _tilex * 360.0 / n - 180.0
	var lat = rad2deg(atan(sinh(PI * (1.0 - 2.0 * float(_tiley) / n))))
	return {"lat":lat, "lon":lon}
	
