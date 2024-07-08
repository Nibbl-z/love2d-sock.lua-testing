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
local enemySpawnTime = 2.5
local enemySpeed = 6

local health = 100
local scores = {}

local restartTimer = 0
local restarting = false

function love.load()
    server = sock.newServer("*", 22122)
    
    server:on("connect", function(data, client)
        print("Player"..tostring(client:getIndex()).." has connected")
        
        playersInstances[tostring(client:getIndex())] = instance:New(nil, "Player"..tostring(client:getIndex()))
        playersInstances[tostring(client:getIndex())].Position.Y = 500
        
        scores[tostring(client:getIndex())] = 0
    end)
    
    server:on("getIndex", function (data, client)
        client:send("getIndex", client:getIndex())
    end)
    
    server:on("disconnect", function (data, client)
        print("Player"..tostring(client:getIndex()).." has disconnected")
        
        playersInstances[tostring(client:getIndex())] = nil
        players[tostring(client:getIndex())] = nil
        scores[tostring(client:getIndex())] = nil
    end)
    
    server:on("move", function (data, client)
        local plr = playersInstances[tostring(client:getIndex())]
        
        plr.Position.X = data
        plr.ShootDebounce = 0
    end)
    
    server:on("getGame", function (data, client)
        client:send("getGame", {players, bullets, enemies, health})
    end)
    
    server:on("shoot", function (data, client)
        if health == 0 then return end
        local plr = playersInstances[tostring(client:getIndex())]
        if love.timer.getTime() > plr.ShootDebounce then
            plr.ShootDebounce = love.timer.getTime() + 0.2

            local bullet = instance:New(nil, "Bullet"..tostring(#bullets))
        
            bullet.Position.X = plr.Position.X + 22.5
            bullet.Position.Y = plr.Position.Y
            bullet.Owner = client:getIndex()
            
            table.insert(bulletsInstances, bullet)
            table.insert(bullets, {
                x = bullet.Position.X + 22.5,
                y = bullet.Position.Y
            })
            
            server:sendToAll("sfx", "Shoot")
        end
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
        bullet.Position.Y = bullet.Position.Y - (2000) * dt
        
        bullets[i] = {
            x = bullet.Position.X,
            y = bullet.Position.Y
        }

        for ei, enemy in ipairs(enemiesInstances) do
            if utils:CheckCollision(
                bullet.Position.X, bullet.Position.Y, 10, 30,
                enemy.Position.X, enemy.Position.Y, 80, 80
            ) then
                scores[tostring(bullet.Owner)] = scores[tostring(bullet.Owner)] + 1000
                
                server:sendToAll("enemyDeath", {x = enemy.Position.X + 40, y = enemy.Position.Y + 40})
                
                table.remove(enemiesInstances, ei)
                table.remove(enemies, ei)
                table.remove(bulletsInstances, i)
                table.remove(bullets, i)
                
                server:sendToAll("sfx", "Explosion")
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
        enemySpawnTimer = love.timer.getTime() + enemySpawnTime
        
        enemySpawnTime = utils:Clamp(enemySpawnTime - 0.2, 0.7, 100)
        enemySpeed = utils:Clamp(enemySpeed + 0.25, 0, 15)
        
        SpawnEnemy()
    end
    
    for i, enemy in ipairs(enemiesInstances) do
        if enemy.Position.X > 720 then
            enemy.Direction = -1
            enemy.Position.Y = enemy.Position.Y + 20
        elseif enemy.Position.X < 0 then
            enemy.Direction = 1
            enemy.Position.Y = enemy.Position.Y + 20
        end
        
        enemy.Position.X = enemy.Position.X + enemy.Direction * enemySpeed * dt * 50

        enemies[i] = {
            x = enemy.Position.X,
            y = enemy.Position.Y
        }

        if enemy.Position.Y > 500 then
            table.remove(enemies, i)
            table.remove(enemiesInstances, i)

            health = utils:Clamp(health - 10, 0, 100)
            
            server:sendToAll("updateHealth", health)

            server:sendToAll("sfx", "Damage")
            
            if health <= 0 then
                if not restarting then
                    server:sendToAll("sfx", "Death")
                    restartTimer = love.timer.getTime() + 4
                    restarting = true
                end
                
            end
        end
    end

    if health == 0 and love.timer.getTime() > restartTimer and restarting then
        enemies = {}
        enemiesInstances = {}
        bullets = {}
        bulletsInstances = {}

        for k, v in pairs(scores) do
            scores[k] = 0
        end
        
        health = 100
        restarting = false

        enemySpawnTime = 4
        enemySpeed = 6

        server:sendToAll("updateHealth", health)
    end

    server:sendToAll("updateEnemies", enemies)
    server:sendToAll("updateScores", scores)
    
    server:update()
end