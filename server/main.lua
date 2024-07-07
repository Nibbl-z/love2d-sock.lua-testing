sock = require("sock")
instance = require("yan.instance.instance")

local playersInstances = {}
local players = {}
local bullets = {}
local bulletsInstances = {}
local enemies = {}

function love.load()
    server = sock.newServer("*", 22122)
    
    server:on("connect", function(data, client)
        print("Player"..tostring(client:getIndex()).." has connected")
        
        playersInstances[tostring(client:getIndex())] = instance:New(nil, "Player"..tostring(client:getIndex()))
        playersInstances[tostring(client:getIndex())].Position.Y = 500
    end)

    server:on("getIndex", function (data, client)
        client:send("getIndex", client:getIndex())
    end)

    server:on("disconnect", function (data, client)
        print("Player"..tostring(client:getIndex()).." has disconnected")
        
        playersInstances[tostring(client:getIndex())] = nil
        players[tostring(client:getIndex())] = nil
    end)
    
    server:on("move", function (data, client)
        local plr = playersInstances[tostring(client:getIndex())]
        
        plr.Position.X = data
    end)
    
    server:on("getGame", function (data, client)
        client:send("getGame", {players, bullets})
    end)

    server:on("shoot", function (data, client)
        local bullet = instance:New(nil, "Bullet"..tostring(#bullets))
        local plr = playersInstances[tostring(client:getIndex())]

        bullet.Position.X = plr.Position.X
        bullet.Position.Y = plr.Position.Y

        table.insert(bulletsInstances, bullet)
        table.insert(bullets, {
            x = bullet.Position.X + 25,
            y = bullet.Position.Y
        })
    end)
    
    print("server is up and running")
end

function love.update(dt)
    for k, v in pairs(playersInstances) do
        players[k] = {
            x = v.Position.X,
            y = v.Position.Y
        }
        
        server:sendToAll("updatePlayers", {k, players[k]})
    end

    for i, bullet in ipairs(bulletsInstances) do
        bullet.Position.Y = bullet.Position.Y - 10
        
        bullets[i] = {
            x = bullet.Position.X,
            y = bullet.Position.Y
        }
    end
    
    server:sendToAll("updateBullets", bullets)
    
    for i, bullet in ipairs(bulletsInstances) do
        if bullet.Position.Y < -100 then
            table.remove(bulletsInstances, i)
            table.remove(bullets, i)
        end
    end
    
    server:update()
end