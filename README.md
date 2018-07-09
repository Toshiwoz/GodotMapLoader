# GodotMapLoader
Loads maps from MapBox and renders it in 3D
![alt text](https://github.com/Toshiwoz/GodotMapLoader/blob/master/mount_fuji_area_screenshot.png "Mount Fuji area")
![alt text](https://github.com/Toshiwoz/GodotMapLoader/blob/master/himalaya_mountains_screenshot.png "Himalaya")


This is still a work in progress, as it should be an addon for Godot game engine (3.0),
but for now it is just a normal project that allows to load map data from MapBox
and render that data into 3d meshes (no collision shape actually created).

The module tries to represent that data as accurate as possible and being as fast
as possible, being this way ideal to load dinamically the terrain
(imagine flight simulator that can load terrain from anywhere in the world as you go).

## Try it yourself

Download this repo, run it in your godot 3.0 version (I am currently using 3.0.4),
create a scene with directional light, a camera, etc.
Then drag in it the TerrainLoader scene (so an instance of it).
And then in the node's properties set latitude, longitude and zoom level (It's the Cordinates setting, or Tilecoords if you want to enter directly the tile X/Y/Z).
You can load multiple tiles by just changing the coordinates,
usually, once entered the first Lat/Lon/Zoom you may want to just change the tile,
so that you have contiguous tiles.
The "Arrange Tiles" checkbox will enable automatic alignment of the tiles,
based on their tile position.

###Some coordinate you can use to test the script
IGUAZU FALLS lat: -25.695277777778 lon: -54.436666666667
FLORENCE - lat: 43.771388888889 lon: 11.254166666667
COTOPAXI lat: -0.680556,-78.437778
MOUNT FUJI lat: 35.36 lon: 138.73
HIMALAYA lat: 27.988056, lon: 86.925278

## TODOs

Mesh dimensions should adapt so that lower zoom levels will result in bigger meshes, a rudimental LOD system.

The earth curvature at low zoom levels (up to 6 but should be less probably), is not rendering correctly, there should be some precision error, or I am misunderstanding someting about tile/pixel to latitute conversion.

Mesh size is still too big (approx 25MB per tile generated),
need some logic to skip unnecessary vertices (It's almos implemented, but needs a better logic).

Dinamically generated normal maps would come handy too, especially at low zooms (approx 1 to 4), as altitudes are irrelevant, but still at certain light inclinations it should project some sort of shadows.
