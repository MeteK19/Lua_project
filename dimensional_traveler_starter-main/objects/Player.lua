Player = {}
Player.__index = Player

function Player.create(x, y)
    local self = setmetatable({}, Player)
    self.x = x
    self.y = y
    self.width = 16
    self.height = 32
    self.healthLevel = 5
    self.lives = 3
    self.score = 0
    self.startX = x
    self.startY = y
    self.isCrouching = false
    self.currentHitboxHeight = self.height
    self.vy=0 --dikey hız
    self.isGrounded = true --yerde mi kontrolü
    self.direction = 1 --ateş yönü
    self.iframes =0  --hasar sonrası dokunulmazlık
    
    return self
end

function Player:update(dt)
    local speed = 90
    local gravity = 500
    local jumpforce = 220
    
    --yatay hareket
    if love.keyboard.isDown('a') or love.keyboard.isDown('left') then 
        self.x = self.x - speed *dt
        self.direction = -1 --sola bakma

    elseif love.keyboard.isDown('d') or love.keyboard.isDown('right') then 
        self.x = self.x + speed * dt
        self.direction = 1 --sağa bakma
    end

    --çömelme yerdeyken hitboxı azalt
    if self.isGrounded and (love.keyboard.isDown('s') or
    love.keyboard.isDown('down')) then
        self.isCrouching = true
        self.currentHitboxHeight = self.height /2 
    else
        self.isCrouching = false
        self.currentHitboxHeight = self.height
    end

    --zıplama yerdeyken ve eğilmiyorken
    if self.isGrounded and not self.isCrouching and (love.keyboard.isDown('w')
    or love.keyboard.isDown('up')) then 
        self.vy = -jumpforce
        self.isGrounded = false
    end

    --yerçekimi
    self.vy = self.vy + gravity * dt
    self.y = self.y + self.vy *dt

   --zemin çarpışması GROUND_y - height = oyuncunun durması gereken y
   local groundY = GROUND_Y - self.height
   if self.y >= groundY then self.y = groundY
    self.vy = 0 
    self.isGrounded = true
   end

   --Ekran yatay sınırları
    self.x = math.max(0, math.min(VIRTUAL_WIDTH - self.width, self.x))

    --dokunulmazlık geri sayımı
    if self.iframes > 0 then self.iframes = self.iframes - dt
    end
end

--çömelince hitboxı yukarıdan azalt
function Player:getHitbox()
    local hy = self.y + (self.height - self.currentHitboxHeight)
    return self.x,hy,self.width,self.currentHitboxHeight
end

function Player:takeDamage()
    if self.iframes > 0 then return end --dokunulmazken hasar almama

    self.iframes = 1.5 --1.5 samiye koruma
    self.healthLevel = self.healthLevel - 1

    if self.healthLevel <= 0 then self.lives = self.lives - 1
        if self.lives > 0 then
            
            --can kaldıysa başlangıça gönder canı yenile
            self.x, self.y = self.startX , self.startY
            self.vy = 0 
            self.isGrounded = true
            self.healthLevel = 5

        else
            --GameOver
            Gamestate.switch(GameOver,self.score)
        end

        end
    
end

function Player:draw()
    -- iframes varken yarı saydam yap (hasar efekti)
    if self.iframes > 0 and math.floor(self.iframes * 8) % 2 == 0 then
        love.graphics.setColor(1, 1, 1, 0.25)
    else
        love.graphics.setColor(1, 1, 1)
    end

    local _, hy, _, hh = self:getHitbox()

    -- sprite'ı hitbox'a sığdıracak şekilde ölçekle
    local sprW = gSprites.player:getWidth()
    local sprH = gSprites.player:getHeight()
    local scaleX = self.width / sprW
    local scaleY = hh / sprH

    -- çömelince sprite de küçülür (scaleY otomatik azalır)
    love.graphics.draw(gSprites.player, self.x, hy, 0, scaleX, scaleY)

    love.graphics.setColor(1, 1, 1)
end

return Player
