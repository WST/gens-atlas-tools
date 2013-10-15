-- Sega Atlas video encoding
-- Gens Lua script by the members of Youtube Sonic TAS community <http://ystc.ru>
-- (c) 2013 Ilya Averkov <WST>

-- Configuration
viewport_width = 1280
viewport_height = 720
camera_x_address = 0xFFF700
camera_y_address = 0xFFF704

-- Initializing
local gd = require "gd"
local frame = 0
local prev_x = 0
local prev_y = 0
local diff_x = viewport_width / 2 - 160
local diff_y = viewport_height / 2 - 112
local map = {}
local path = string.gsub(debug.getinfo(1).short_src, '[\\/]atlas.lua', '')

-- Current viewport
local viewport = gd.createTrueColor(viewport_width, viewport_height)

-- TODO: ROM auto detection
-- TODO: direct video rendering from the script (if possible?)
-- TODO: custom HUD

function loadMap(level)
	local maps = {
		-- Map file, X offset, Y offset, default camera Y
		{'maps/ghz1.png', -3, 1, 768},
		{'maps/ghz2.png', 0, 0, 156},
		{'maps/ghz3.png', 0, 0, 768},
		{'maps/mz1.png', 0, 0, 464},
		{'maps/mz2.png', 0, 0, 518},
		{'maps/mz3.png', 0, 0, 262},
	}
	local filename = maps[level][1]
	print("Loading map: " .. filename)
	image = gd.createFromPng(path .. '/' .. filename)
	assert(image, 'Failed to load map file <' .. filename .. '>. Note that you should download the maps manually.')
	return {image, image:sizeX(), image:sizeY(), maps[level][2], maps[level][3], maps[level][4]}
end

function setCamera()
	-- Current camera positions
	local camera_x = memory.readword(camera_x_address)
	local camera_y = memory.readword(camera_y_address)
	
	if (0 == camera_x) and (0 == camera_y) then
		camera_y = map[6]
		prev_y = camera_y
	end
	
	-- Viewport wanted X and Y positions
	local viewport_x = prev_x - diff_x
	local viewport_y = prev_y - diff_y
	
	-- Updating the previous camera positions
	prev_x = camera_x
	prev_y = camera_y
	
	local offset_x = map[4]
	local offset_y = map[5]
	
	-- We do not want negative viewport positions
	if viewport_x < 0 then
		offset_x = map[4] + viewport_x
		viewport_x = 0
	end
	if viewport_y < 0 then
		offset_y = map[5] + viewport_y
		viewport_y = 0
	end
	
	-- We also do not want them to go outside the map from the opposite side
	if (viewport_x + viewport_width) > map[2] then
		fix = map[2] - viewport_width
		offset_x = map[4] + (viewport_x - fix)
		viewport_x = fix
	end
	if (viewport_y + viewport_height) > map[3] then
		fix = map[3] - viewport_height
		offset_y = map[5] + (viewport_y - fix)
		viewport_y = fix;
	end
	
	return viewport_x, viewport_y, offset_x, offset_y
end

function process()
	-- Calculating camera and viewport positions
	local viewport_x, viewport_y, offset_x, offset_y = setCamera()
	
	-- Current screenshot
	local screenshot = gd.createFromGdStr(gui.gdscreenshot())
	
	-- Current viewport image
	viewport:copy(map[1], 0, 0, viewport_x, viewport_y, viewport_width, viewport_height)
	viewport:copy(screenshot, diff_x + offset_x, diff_y + offset_y, 0, 0, 320, 224)
	viewport:png(path .. '/results/img-' .. frame .. '.png')
	
	frame = frame + 1
	
	-- TODO: get rid of this ugliness
	if (frame == 3304) then
		map = loadMap(2)
	end
	if (frame == 5664) then
		map = loadMap(3)
	end
	if (frame == 8643) then
		map = loadMap(4)
	end
	if (frame == 12118) then
		map = loadMap(5)
	end
	if (frame == 15990) then
		map = loadMap(6)
	end
end

print('Sega Atlas script is running')
map = loadMap(1)
emu.registerafter(process)
