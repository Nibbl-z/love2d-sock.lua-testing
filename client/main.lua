sock = require("sock")

local world = nil
local bullets = nil
local enemies = nil
local scores = {}
local index = 0
local health = 100

local screen = require("yan.instance.ui.screen")
local textinput = require("yan.instance.ui.textinput")
local textbutton = require("yan.instance.ui.textbutton")
local label = require("yan.instance.ui.label")

local client = nil
local sprites = {
    Player = "player.png",
    Enemy = "enemy.png",
    Bullet = "bullet.png",
    Square = "square.png"
}

local sounds = {
    Damage = {"damage.wav", "static"},
    Death = {"death.wav", "static"},
    Shoot = {"shoot.wav", "static"},
    Explosion = {"explosion.wav", "static"},
    Music = {"music.mp3", "stream"}
}

local connecting = false
local connectWaiting = false
local connectStartTimer = 0

local emitters = {}

function explosion(x, y)
    local particles = love.graphics.newParticleSystem(sprites.Square, 2000)

    particles:setLinearAcceleration(-3000,-3000,3000,3000)
    particles:setLinearDamping(40)
    particles:setSpread(10 * math.pi)
    particles:setParticleLifetime(0.4)
    particles:setPosition(x, y)
    particles:setSizes(1, 0)
    particles:emit(20)
    
    table.insert(emitters, particles)
end

function connect()
    connectWaiting = false
    connecting = true
    client = sock.newClient(ipInput.Text, 22122)
    
    local status, err = pcall(function() 
        client:connect()
    end)
    
    print(status, err)

    if status == false then
        connecting = false
        ipInput.Text = ""
        statusText.Text = "Failed to connect"
        client = nil
    else
        menu.Enabled = false
        connecting = false
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

        client:on("enemyDeath", function (data)
            explosion(data.x, data.y)
        end)
    end
end

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

    

    menu = screen:New(nil)

    ipInput = textinput:New(nil, menu, "Enter server IP", 32)
    ipInput:SetPosition(0.5,0,0.5,0)
    ipInput:SetSize(0.5,0,0.2,0)
    ipInput:SetColor(0,1,0,1)
    ipInput:SetTextColor(1,1,1,1)
    ipInput:SetAnchorPoint(0.5,0.5)
    ipInput:SetPlaceholderTextColor(0,0,0,1)

    statusText = label:New(nil, menu, "", 32, "center")
    statusText:SetPosition(0.5,0,0.7,10)
    statusText:SetSize(0.7,0,0.2,0)
    statusText:SetColor(0,1,0,1)
    statusText:SetAnchorPoint(0.5,0.5)

    logoText = label:New(nil, menu, "Space Defenders", 64, "center")
    logoText:SetPosition(0,0,0,10)
    logoText:SetSize(1,0,0.3,0)
    logoText:SetColor(0,1,0,1)
    logoText:SetAnchorPoint(0,0)

    menu.Enabled = true
    
    ipInput.MouseDown = function ()
        ipInput:SetColor(0,0.8,0,1)
    end
    
    ipInput.MouseEnter = function ()
        ipInput:SetColor(0,0.6,0,1)
    end
    
    ipInput.MouseLeave = function ()
        ipInput:SetColor(0,1,0,1)
    end

    ipInput.OnEnter = function ()
        statusText.Text = "Connecting..."
        connectWaiting = true
        connectStartTimer = love.timer.getTime() + 0.2
    end
end

local movementDirections = {
	a = -1, d = 1
}

function love.keypressed(key, scancode, rep)
    ipInput:KeyPressed(key, scancode, rep)
    
    if key == "space" and client ~= nil then
        client:send("shoot")
        --sounds.Shoot:clone():play()
    end
end

function love.textinput(t)
    ipInput:TextInput(t)
end

function love.update(dt)
    if connectWaiting and love.timer.getTime() > connectStartTimer then
        connect()
    end

    if client ~= nil then
        if world == nil or bullets == nil then
            client:send("getGame")
        else
            local plr = world[tostring(index)]
    
            for k, v in pairs(movementDirections) do
                if love.keyboard.isDown(k) then
                    if plr ~= nil then
                        plr.x = plr.x + v * 500 * dt
                        client:send("move", plr.x)
                    end
                end
            end
        end
        
        if index == 0 then
            client:send("getIndex")
        end
        
        client:update()
    else
        menu:Update()
    end
    
    for _, v in ipairs(emitters) do
        v:update(dt)
    end
end

function love.draw()
    menu:Draw()

    love.graphics.setColor(1,1,1,1)
    if world ~= nil then
        for k, player in pairs(world) do
            if tostring(k) == tostring(index) then
                love.graphics.setColor(1,1,1,1)
            else
                love.graphics.setColor(1,1,1,0.5)
            end
            love.graphics.draw(sprites.Player, player.x, player.y)
        end
    end
    
    love.graphics.setColor(1,1,1,1)
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
    
    for _, v in ipairs(emitters) do
        love.graphics.draw(v, 0, 0)
    end

    if world ~= nil then
        love.graphics.setFont(font)
        love.graphics.setColor(0,1,0,1)
        love.graphics.printf(tostring(totalScore), 0, 10, love.graphics.getWidth(), "center")

        love.graphics.rectangle("fill", 0, love.graphics.getHeight() - 25, (health / 100) * love.graphics.getWidth(), 25)

        if health <= 0 then
            sounds.Music:setVolume(0.4)
            
            love.graphics.setColor(1,0,0,0.5)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
            
            love.graphics.setColor(1,1,1,1)
            love.graphics.printf("GAME OVER", 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center")

            love.graphics.setColor(1,1,1,1)
            love.graphics.printf("FINAL SCORE: "..tostring(totalScore), 0, love.graphics.getHeight() / 2 + 32, love.graphics.getWidth(), "center")
        else
            sounds.Music:setVolume(1)
        end
    end

    
    
    --love.graphics.print("Health: "..tostring(health), 0, 40)
end