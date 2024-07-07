sock = require("sock")

local world = nil
local environment = nil
local index = 0

function love.load()
    client = sock.newClient("localhost", 22122)
    
    client:on("connect", function(data)
        print("Client connected to the server.")
    end)
    
    client:on("disconnect", function(data)
        print("Client disconnected from the server.")
    end)
    
    client:on("getPlayers", function (data)
        world = data
    end)
    
    client:on("updatePlayers", function(msg)
        print(msg[1], msg[2])
        if tonumber(msg[1]) ~= index and world ~= nil then
            print("moving "..msg[1].. "!!")
            world[msg[1]] = msg[2]
        end
    end)

    client:on("getIndex", function (data)
        index = data
    end)
    
    client:connect()
    
end

local movementDirections = {
	a = -1, d = 1
}

function love.update(dt)
    
    if world == nil then
        client:send("getPlayers")
    else
        local plr = world[tostring(index)]

        for k, v in pairs(movementDirections) do
            if love.keyboard.isDown(k) then
                
                if plr ~= nil then
                    plr.x = plr.x + v * 10
                    client:send("move", plr.x)
                end
            end
        end
    end
    
    if index == 0 then
        client:send("getIndex")
    end
    
    
    client:update()
    
    
end

function love.draw()
    if world ~= nil then
        for k, player in pairs(world) do
            love.graphics.rectangle("fill", player.x, player.y, 50, 50)
        end
    end
	
    
    if environment ~= nil then
        for _, v in ipairs(environment) do
            love.graphics.rectangle("fill", v.pX, v.pY, v.sX, v.sY)
        end
    end
    
end