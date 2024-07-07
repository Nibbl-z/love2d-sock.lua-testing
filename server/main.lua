sock = require("sock")
physicsInstance = require("yan.instance.physics_instance")

local playersInstances = {}
local players = {}
local environment = {}

function love.load()
    server = sock.newServer("*", 22122)
    
    world = love.physics.newWorld(0,1000,true)

    server:on("connect", function(data, client)
        print(client:getIndex())
        
        playersInstances[tostring(client:getIndex())] = physicsInstance:New(nil, world, "dynamic", "rectangle", {X = 50, Y = 50}, 0, 1)
    end)
    
    server:on("move", function (data, client)
        local plr = playersInstances[tostring(client:getIndex())]
        plr:ApplyLinearImpulse(data[1] * 10000, data[2] * 10000, 200, 200)
    end)
    
    server:on("getEnvironment", function (data, client)
        print("gup!!!")
        client:send("environment", environment)
    end)

    ground = physicsInstance:New(nil, world, "static", "rectangle", {X = 30000, Y = 50}, 0, 1)
    ground.body:setY(300)
    ground:Update()
    
    table.insert(environment, {
        pX = ground.Position.X,
        pY = ground.Position.Y,
        sX = ground.Size.X,
        sY = ground.Size.Y
    })
    print("server is up and running")
end

function love.update(dt)
    world:update(dt)
    for k, v in pairs(playersInstances) do
        v:Update()
        players[k] = {
            x = v.Position.X,
            y = v.Position.Y
        }
    end

    server:update()
    server:sendToAll("updatePlayers", players)
end