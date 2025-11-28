-- written by groverbuger for g3d
-- september 2021
-- MIT license

local g3d = require "g3d"
local earth = g3d.newModel("assets/sphere.obj", "assets/earth.png", {4,0,0})
local moon = g3d.newModel("assets/sphere.obj", "assets/moon.png", {4,5,0}, nil, 0.5)
local background = g3d.newModel("assets/sphere.obj", "assets/starfield.png", nil, nil, 500)
local timer = 0

local apollo = g3d.newModel("assets/apollo.obj", nil, {0, 0, 10})
local ambientShader = love.graphics.newShader("g3d/lights.glsl")
ambientShader:send("ambientBase", 0.5)
ambientShader:send("ambientBrightness", 1.0)
ambientShader:send("ambientDirection", {1, 1, 1})
ambientShader:send("ambientColor", {1, 1, 1})
ambientShader:send("shake", 1)

function love.update(dt)
    timer = timer + dt
    moon:setTranslation(math.cos(timer)*5 + 4, math.sin(timer)*5, 0)
    moon:setRotation(0, 0, timer - math.pi/2)
    g3d.camera.firstPersonMovement(dt)
    if love.keyboard.isDown "escape" then
        love.event.push "quit"
    end
	ambientShader:send("distTime", timer)
	ambientShader:send("shake", math.sin(timer / 5) * 0.01)
end

function love.draw()
    earth:draw()
    moon:draw()
    background:draw()
	apollo:draw(ambientShader)
end

function love.mousemoved(x,y, dx,dy)
    g3d.camera.firstPersonLook(dx,dy)
end
