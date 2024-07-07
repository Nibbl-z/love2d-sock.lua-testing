sock = require "sock"

local world = {}

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

    client:connect()
end

function love.keypressed()
	client:send("greeting", "Hello, my name is Inigo Montoya.")
end

local movementDirections = {
	w = {0,-1}, a = {-1,0}, s = {0,1}, d = {1,0}
}

function love.update(dt)
    for k, v in pairs(movementDirections) do
		if love.keyboard.isDown(k) then
			client:send("move", v)
		end
	end

    client:update()
end

function love.draw()
	for k, player in pairs(world) do
		love.graphics.rectangle("fill", player.x, player.y, 20, 20)
	end
end