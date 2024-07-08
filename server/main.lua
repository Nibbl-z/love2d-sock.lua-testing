sock = require("sock")
instance = require("yan.instance.instance")
utils = require("yan.utils")

local playersInstances = {}
local players = {}
local bullets = {}
local bulletsInstances = {}
local enemies = {}
local enemiesInstances = {}

local enemySpawnTimer = love.timer.getTime()

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
        client:send("getGame", {players, bullets, enemies})
    end)

    server:on("shoot", function (data, client)
        local bullet = instance:New(nil, "Bullet"..tostring(#bullets))
        local plr = playersInstances[tostring(client:getIndex())]

        bullet.Position.X = plr.Position.X + 22.5
        bullet.Position.Y = plr.Position.Y

        table.insert(bulletsInstances, bullet)
        table.insert(bullets, {
            x = bullet.Position.X + 22.5,
            y = bullet.Position.Y
        })
    end)
    
    print("server is up and running")
end

function SpawnEnemy()
    local enemy = instance:New(nil, "Enemy"..tostring(#enemies))
    enemy.Position.X = love.math.random(200, 600)
    enemy.Position.Y = 50
    enemy.Direction = 1
    
    table.insert(enemiesInstances, enemy)
    table.insert(enemies, {
        x = enemy.Position.X,
        y = enemy.Position.Y
    })
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
        bullet.Position.Y = bullet.Position.Y - 20
        
        bullets[i] = {
            x = bullet.Position.X,
            y = bullet.Position.Y
        }

        for ei, enemy in ipairs(enemiesInstances) do
            if utils:CheckCollision(
                bullet.Position.X, bullet.Position.Y, 5, 20,
                enemy.Position.X, enemy.Position.Y, 40, 40
            ) then
                table.remove(enemiesInstances, ei)
                table.remove(enemies, ei)
                table.remove(bulletsInstances, i)
                table.remove(bullets, i)
            end
        end
    end
    
    server:sendToAll("updateBullets", bullets)
    
    for i, bullet in ipairs(bulletsInstances) do
        if bullet.Position.Y < -100 then
            table.remove(bulletsInstances, i)
            table.remove(bullets, i)
        end
    end

    if love.timer.getTime() > enemySpawnTimer then
        enemySpawnTimer = love.timer.getTime() + 2
        
        SpawnEnemy()
    end
    
    for i, enemy in ipairs(enemiesInstances) do
        if enemy.Position.X > 800 then
            enemy.Direction = -1
            enemy.Position.Y = enemy.Position.Y + 20
        elseif enemy.Position.X < 0 then
            enemy.Direction = 1
            enemy.Position.Y = enemy.Position.Y + 20
        end

        enemy.Position.X = enemy.Position.X + enemy.Direction * 10

        enemies[i] = {
            x = enemy.Position.X,
            y = enemy.Position.Y
        }
    end

    server:sendToAll("updateEnemies", enemies)
    
    server:update()
end