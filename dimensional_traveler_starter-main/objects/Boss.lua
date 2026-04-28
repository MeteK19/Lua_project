Boss = {}
Boss.__index = Boss

function Boss.create(x, y)
    local self = setmetatable({}, Boss)
    self.x = x
    self.y = y
    self.width = 36
    self.height = 40
    self.health = 10
    self.phase = 1
    self.speed = 30
    self.fireTimer = 0
    self.fireRate = 3
    self.direction = -1      -- başlangıçta sola gider
    self.vy = 0              -- dikey hız (zıplama için)
    self.isGrounded = true
    self.jumpTimer = 0       -- yaklaşınca zıplamak için sayaç
    return self
end

function Boss:update(dt, player, enemyBullets)
    self:checkPhase()
    self:movePattern(dt, player)

    -- ateş sayacı
    self.fireTimer = self.fireTimer + dt
    if self.fireTimer >= self.fireRate then
        self.fireTimer = 0
        if self.phase == 2 then
            self:fireSpread(enemyBullets, player)   -- faz 2: yayılı ateş
        else
            -- faz 1: oyuncuya tek mermi
            local dir = player.x > self.x and 1 or -1
            local bx = dir == 1 and (self.x + self.width) or self.x
            table.insert(enemyBullets, Bullet.create(bx, self.y + self.height / 2, dir))
        end
    end
end

function Boss:checkPhase()
    -- can %50'nin altına düşünce faz 2'ye geç
    if self.health <= 5 and self.phase == 1 then
        self.phase = 2
        self.fireRate = 1.5   -- daha sık ateş
        self.speed = 80       -- faz 2'de daha hızlı
    end
end

function Boss:movePattern(dt, player)
    -- ── TAKİP SİSTEMİ ──────────────────────────────────────
    if self.phase == 1 then
        -- Faz 1: sağa-sola ileri geri gider, duvarda yön değiştirir
        self.x = self.x + self.speed * self.direction * dt
        if self.x <= 0 then
            self.x = 0
            self.direction = 1
        elseif self.x + self.width >= VIRTUAL_WIDTH then
            self.x = VIRTUAL_WIDTH - self.width
            self.direction = -1
        end
    else
        -- Faz 2: doğrudan oyuncuyu takip eder (daha hızlı)
        local dir = player.x > self.x and 1 or -1
        self.x = self.x + self.speed * dir * dt
        self.direction = dir  -- yönü güncelle
        -- ekran sınırları
        self.x = math.max(0, math.min(VIRTUAL_WIDTH - self.width, self.x))
    end
    -- ────────────────────────────────────────────────────────

    -- Faz 2: oyuncu çok yaklaşırsa zıpla (3 saniyede bir kontrol)
    if self.phase == 2 then
        self.jumpTimer = self.jumpTimer + dt
        if self.jumpTimer >= 3 and self.isGrounded and
           math.abs(player.x - self.x) < 60 then
            self.vy = -200        -- yukarı zıpla
            self.isGrounded = false
            self.jumpTimer = 0
        end
    end

    -- yerçekimi
    self.vy = self.vy + 500 * dt
    self.y  = self.y  + self.vy * dt
    local groundY = GROUND_Y - self.height
    if self.y >= groundY then
        self.y = groundY
        self.vy = 0
        self.isGrounded = true
    end
end

function Boss:fireSpread(enemyBullets, player)
    -- 3 mermi: yukarı eğik, düz, aşağı eğik
    local dir = player.x > self.x and 1 or -1
    local bx = dir == 1 and (self.x + self.width) or self.x
    local by = self.y + self.height / 2
    for i = 1, 3 do
        local b = Bullet.create(bx, by, dir)
        b.dy = (i - 2) * 60   -- sırasıyla: -60 (yukarı), 0 (düz), +60 (aşağı)
        table.insert(enemyBullets, b)
    end
end

function Boss:draw()
    -- faz 2'de kırmızımsı renk tonu (görsel uyarı)
    if self.phase == 2 then
        love.graphics.setColor(1.0, 0.4, 0.4)
    else
        love.graphics.setColor(1, 1, 1)
    end

    -- sprite'ı boss boyutuna ölçekle (boss düşmandan 2x büyük)
    local sprW = gSprites.boss:getWidth()
    local sprH = gSprites.boss:getHeight()
    local scaleX = self.width  / sprW
    local scaleY = self.height / sprH

    -- sola bakıyorsa sprite'ı çevir
    if self.direction == -1 then
        love.graphics.draw(gSprites.boss, self.x + self.width, self.y, 0, -scaleX, scaleY)
    else
        love.graphics.draw(gSprites.boss, self.x, self.y, 0,  scaleX, scaleY)
    end

    love.graphics.setColor(1, 1, 1)
end

return Boss
