sock = require("sock")

local world = nil
local bullets = nil
local enemies = nil
local index = 0

function love.load()
    client = sock.newClient("localhost", 22122)

    client:on("connect", function(data)
        print("Client connected to the server.")
    end)

    client:on("disconnect", function(data)
        print("Client disconnected from the server.")
    end)

    client:on("getGame", function (data)
        world = data[1]
        bullets = data[2]
        enemies = data[3]
    end)

    client:on("updatePlayers", function(msg)
        if tonumber(msg[1]) ~= index and world ~= nil then
            print("moving "..msg[1].. "!!")
            world[msg[1]] = msg[2]
        end
    end)
    
    client:on("updateBullets", function (data)
        bullets = data
    end)

    client:on("updateEnemies", function (data)
        enemies = data
    end)

    client:on("getIndex", function (data)
        index = data
    end)

    client:connect()

end

local movementDirections = {
	a = -1, d = 1
}

function love.keypressed(key)
    if key == "space" then
        client:send("shoot")
    end
end

function love.update(dt)

    if world == nil or bullets == nil then
        client:send("getGame")
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
    
    
    if bullets ~= nil then
        for _, v in ipairs(bullets) do
            love.graphics.rectangle("fill", v.x, v.y, 5, 20)
        end
    end

    if enemies ~= nil then
        for _, v in ipairs(enemies) do
            love.graphics.rectangle("line", v.x, v.y, 40, 40)
        end
    end

end