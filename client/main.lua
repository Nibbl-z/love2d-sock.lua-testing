sock = require("sock")

local world = nil
local bullets = nil
local enemies = nil
local scores = {}
local index = 0
local health = 100

local sprites = {
    Player = "player.png",
    Enemy = "enemy.png",
    Bullet = "bullet.png"
}

local sounds = {
    Damage = {"damage.wav", "static"},
    Death = {"death.wav", "static"},
    Shoot = {"shoot.wav", "static"},
    Explosion = {"explosion.wav", "static"},
    Music = {"music.mp3", "stream"}
}

function love.load()
    font = love.graphics.newFont("/fonts/PressStart2P-Regular.ttf", 32)
    
    for k, v in pairs(sprites) do
        sprites[k] = love.graphics.newImage("/img/"..v)
    end
    
    for k, v in pairs(sounds) do
        sounds[k] = love.audio.newSource("/sound/"..v[1], v[2])
    end

    sounds.Music:setLooping(true)
    sounds.Music:play()

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
        health = data[4]
    end)

    client:on("updatePlayers", function(msg)
        if tonumber(msg[1]) ~= index and world ~= nil then
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
        print("Data", data)
        index = data
    end)

    client:on("updateScores", function (data)
        scores = data
    end)

    client:on("updateHealth", function (data)
        health = data
    end)

    client:on("sfx", function (data)
        sounds[data]:clone():play()
    end)

    client:connect()

end

local movementDirections = {
	a = -1, d = 1
}

function love.keypressed(key)
    if key == "space" then
        client:send("shoot")
        sounds.Shoot:clone():play()
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
    love.graphics.setColor(1,1,1,1)
    if world ~= nil then
        for k, player in pairs(world) do
            love.graphics.draw(sprites.Player, player.x, player.y)
        end
    end
    
    
    if bullets ~= nil then
        for _, v in ipairs(bullets) do
            love.graphics.draw(sprites.Bullet, v.x, v.y)
        end
    end

    if enemies ~= nil then
        for _, v in ipairs(enemies) do
            love.graphics.draw(sprites.Enemy, v.x, v.y)
        end
    end
    local totalScore = 0
    local myScore = 0
    
    for k, v in pairs(scores) do
        if tostring(k) == tostring(index) then
            myScore = v
        end
        
        totalScore = totalScore + v
    end
    
    love.graphics.setFont(font)
    love.graphics.setColor(0,1,0,1)
    love.graphics.printf(tostring(totalScore), 0, 10, love.graphics.getWidth(), "center")

    love.graphics.rectangle("fill", 0, love.graphics.getHeight() - 25, (health / 100) * love.graphics.getWidth(), 25)

    if health <= 0 then
        love.graphics.setColor(1,0,0,0.5)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("GAME OVER", 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center")
    end
    
    --love.graphics.print("Health: "..tostring(health), 0, 40)
end