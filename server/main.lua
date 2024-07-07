sock = require "sock"

local world = {}

function love.load()
    server = sock.newServer("*", 22122)
    
    server:on("connect", function(data, client)
        print(client:getIndex())
        world[tostring(client:getIndex())] = {
            x = 0,
            y = 0
        }
    end)
    
    server:on("move", function (data, client)
        local plr = world[tostring(client:getIndex())]
        plr.x = plr.x + data[1]
        plr.y = plr.y + data[2]

        print(plr.x)
    end)
    
    server:on("greeting", function (data, client)
        print(data)
    end)

    print("server is up and running")
end

function love.update(dt)
    server:update()
    server:sendToAll("updatePlayers", world)
end