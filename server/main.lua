sock = require("sock")
instance = require("yan.instance.instance")

local playersInstances = {}
local players = {}
local environment = {}

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
    
    server:on("getPlayers", function (data, client)
        client:send("getPlayers", players)
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
    
    server:update()
end