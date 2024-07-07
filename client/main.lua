sock = require("sock")

local world = {}
local environment = nil

function love.load()
    client = sock.newClient("localhost", 22122)
    
    client:on("connect", function(data)
        print("Client connected to the server.")
    end)
    
    client:on("disconnect", function(data)
        print("Client disconnected from the server.")
    end)
    
    client:on("updatePlayers", function(msg)
        world = msg
    end)

    client:on("environment", function (data)
        print(data)
        environment = data
    end)
    
    client:connect()
    
end

local movementDirections = {
	w = {0,-0.01}, a = {-1,0}, s = {0,1}, d = {1,0}
}

function love.update(dt)
    for k, v in pairs(movementDirections) do
		if love.keyboard.isDown(k) then
			client:send("move", v)
		end
	end
    if environment == nil then
        client:send("getEnvironment")
    end
    client:update()
    
    
end

function love.draw()
	for k, player in pairs(world) do
		love.graphics.rectangle("fill", player.x, player.y, 50, 50)
	end
    
    if environment ~= nil then
        for _, v in ipairs(environment) do
            love.graphics.rectangle("fill", v.pX, v.pY, v.sX, v.sY)
        end
    end
    
end