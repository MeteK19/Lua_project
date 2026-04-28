push = require 'lib.push'
Gamestate = require 'lib.hump.gamestate'

require 'states.Menu'
require 'states.Play'
require 'states.Pause'
require 'states.Win'
require 'states.GameOver'
require 'states.HighScore'
require 'objects.Player'
require 'objects.Bullet'
require 'objects.Enemy'
require 'objects.Boss'

VIRTUAL_WIDTH = 320
VIRTUAL_HEIGHT = 180
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720
GROUND_Y = VIRTUAL_HEIGHT - 20

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
    love.window.setTitle('The Dimensional Traveler')

    gFonts = {
        small = love.graphics.newFont(8),
        medium = love.graphics.newFont(16),
        large = love.graphics.newFont(32)
    }
    

    -- Sprite'ları yükle
    gSprites = {
        player   = love.graphics.newImage('assets/sprites/player.png'),   -- oyuncu (yeşil robot)
        enemy    = love.graphics.newImage('assets/sprites/enemy.png'),    -- düşman (turuncu robot)
        boss     = love.graphics.newImage('assets/sprites/boss.png'),     -- boss (mavi robot)
        bg1      = love.graphics.newImage('assets/sprites/sky.png'),-- arka plan katman 1 (gökyüzü)
        bg2      = love.graphics.newImage('assets/sprites/tree.png'),-- arka plan katman 2 (ağaçlar)
        bg3      = love.graphics.newImage('assets/sprites/ground.png'),-- arka plan katman 3 (zemin detay)
    }

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true
    })

    Gamestate.switch(Menu)
end

function love.resize(w, h)
    push:resize(w, h)
end

function love.update(dt)
    Gamestate.update(dt)
end

function love.keypressed(key)
    Gamestate.keypressed(key)
end

function love.draw()
    push:start()
        Gamestate.draw()
    push:finish()
end
