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

Download this repo, run it in your godot 3.0 version (I am currently using 3.0.3 RC1),
create a scene with directional light, a camera, etc.
Then drag in it the TerrainLoader scene (so an instance of it).
And then in the node's properties set latitude, longitude and zoom level (sorry, it loads every time you change each of those values.. will resolve that once it will become an actual Addon.

## TODOs

I am trying to take into account also earth curvature,
so very soon the renderer will have that option too
(probably will be optionally disabled, as there's not need at higher zoom levels).

Mesh size is still too big (15MB per tile generated),
need some logic to skip unnecessary vertices.

Dinalically generated normal maps would come handy too.
