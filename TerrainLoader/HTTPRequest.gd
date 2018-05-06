tool
extends HTTPRequest

export(String) var access_token = "pk.eyJ1IjoiZGlnaXRhbGtpIiwiYSI6ImNqNXh1MDdibTA4bTMycnAweDBxYXBpYncifQ.daSatfva2eG-95QHWC9Mig"
export(int) var zoom_level = 1 setget _setZoom
export(float) var lon = 0 setget _set_lon
export(float) var lat = 0 setget _set_lat
export(Image) var TerrainHeightMap
export(Image) var TerrainTexture
var smf = preload("res://TerrainLoader/slippy_map_functions.gd")

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

func _on_TerrainLoader_request_completed( result, response_code, headers, body ):
	if(result == HTTPRequest.RESULT_SUCCESS):
		print("Download successfull")
	else:
		print("Result code: " + var2str(result))
	print("Response code: " + var2str(response_code))
	print(headers)
	var resp_image = Image.new()
	var png_error = resp_image.load_png_from_buffer(body)
	print("Image load error code: " + var2str(png_error))
	print("Request Body Size: " + var2str(body.size()))
	print("Image Size: " + var2str(resp_image.get_size()))
	resp_image.lock()
	resp_image.save_png("res://response_hm.png")
	resp_image.unlock()
	TerrainHeightMap = resp_image

func _setCoords(_lon = 0, _lat = 0, _zoom = 1):
	var tile = smf.latlon_to_tile(_lat, _lon, _zoom)
	_request_map(_lon, _lat, _zoom)
	
func _request_map(_lon = 0, _lat = 0, _zoom = 1, _isheightmap = true):
	var tile = smf.latlon_to_tile(_lat, _lon, _zoom)
	print(tile)
	var map_type = "terrain-rgb"
	if(!_isheightmap):
		map_type = "satellite"
	var url = "https://api.mapbox.com/v4/mapbox." + map_type + "/" + var2str(_zoom) + "/" + var2str(tile["xtile"]) + "/" + var2str(tile["ytile"]) +".pngraw?access_token=" + access_token
	print(url)
	var custom_header = PoolStringArray()
	custom_header.insert("request_url", map_type)
	self.request(url
	, custom_header, false, 0)
