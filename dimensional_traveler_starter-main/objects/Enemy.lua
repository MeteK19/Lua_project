Enemy = {}
Enemy.__index = Enemy

function Enemy.create(x, y)
    local self = setmetatable({}, Enemy)
    self.x = x
    self.y = y
    self.width = 16
    self.height = 28
    self.health = 3          -- 3 mermiye ölür
    self.fireTimer = 0
    self.fireRate = 2        -- kaç saniyede bir ateş eder
    self.speed = 40
    self.direction = 1       -- başlangıç patrol yönü
    self.patrolTimer = 0     -- yön değiştirme sayacı
    return self
end

function Enemy:update(dt, player, enemyBullets)
    --TAKİP SİSTEMİ
    if self:canSeePlayer(player) then
        -- Oyuncu menzildeyse: patrol bırak, oyuncuya doğru yürü
        local dir = player.x > self.x and 1 or -1
        self.x = self.x + self.speed * dir * dt
        self.direction = dir  -- yönü de güncelle (draw için kullanılabilir)
    else
        -- Oyuncu uzaktaysa: normal patrol 1.5 saniyede yön değiştirir
        self.patrolTimer = self.patrolTimer + dt
        if self.patrolTimer >= 1.5 then
            self.direction = -self.direction
            self.patrolTimer = 0
        end
        self.x = self.x + self.speed * self.direction * dt
    end
    

    -- ekran sınırları aşılmasın
    self.x = math.max(0, math.min(VIRTUAL_WIDTH - self.width, self.x))

    -- menzil içinde oyuncuya ateş et
    if self:canSeePlayer(player) then
        self.fireTimer = self.fireTimer + dt
        if self.fireTimer >= self.fireRate then
            self.fireTimer = 0
            local dir = player.x > self.x and 1 or -1
            local bx = dir == 1 and (self.x + self.width) or self.x
            -- düşman mervisini enemyBullets tablosuna ekle
            table.insert(enemyBullets, Bullet.create(bx, self.y + self.height / 2, dir))
        end
    end
end

function Enemy:canSeePlayer(player)
    return math.abs(player.x - self.x) < 300
end

function Enemy:draw()
    love.graphics.setColor(1, 1, 1)

    -- sprite'ı düşmanın hitbox boyutuna ölçekle
    local sprW = gSprites.enemy:getWidth()
    local sprH = gSprites.enemy:getHeight()
    local scaleX = self.width  / sprW
    local scaleY = self.height / sprH

    -- sola bakıyorsa sprite'ı yatay çevir
    if self.direction == -1 then
        -- yatay çevirme: x'i sağa kaydır, scaleX negatif yap
        love.graphics.draw(gSprites.enemy, self.x + self.width, self.y, 0, -scaleX, scaleY)
    else
        love.graphics.draw(gSprites.enemy, self.x, self.y, 0,  scaleX, scaleY)
    end
end

return Enemy
