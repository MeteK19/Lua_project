Play = {}

function Play:enter()
    self.player = Player.create(40, GROUND_Y - 32)
    self.playerBullets = {} --oyuncunun mermileri
    self.enemyBullets = {} --düşman mermisi
    self.enemies = {
        Enemy.create(160, GROUND_Y - 28),
        Enemy.create(230, GROUND_Y - 28),
        Enemy.create(285, GROUND_Y - 28)
    }
    self.boss = Boss.create(240, GROUND_Y - 40)
    self.highScores = HighScore.loadScores()
end

function Play:keypressed(key)
    if key == 'p' then
        Gamestate.switch(Pause, self)
    elseif key == 'escape' then
        Gamestate.switch(Menu)
    elseif key == 'space' then
        --oyuncu baktığı yöne ateş et
        local dir = self.player.direction
        local bx = dir == 1 and (self.player.x + self.player.width) or self.player.x
        local _, hy, _, hh = self.player:getHitbox()
        table.insert(self.playerBullets, Bullet.create(bx, hy + hh / 2, dir))
    end
end

--iki dikdörtgenin çakışıp çakışmadığını kontrol etme
local function aabb(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx and
           ay < by + bh and ay + ah > by
end

function Play:update(dt)
    self.player:update(dt)

    -- Mevcut bullet güncellemesi
    for i = #self.playerBullets, 1, -1 do
        local bullet = self.playerBullets[i]
        bullet:update(dt)
        if bullet.dead then
            table.remove(self.playerBullets, i)
        else
            --düşmanlarla çarpışma
            for j = #self.enemies, 1, -1 do
                local enemy = self.enemies[j]
                if aabb(bullet.x, bullet.y, bullet.width, bullet.height,
                        enemy.x, enemy.y, enemy.width, enemy.height) then
                    bullet.dead = true
                    enemy.health = enemy.health - 1
                    if enemy.health <= 0 then
                        self.player.score = self.player.score + 100
                        table.remove(self.enemies, j)
                    end
                    break
                end
            end

            --boss ile çarpışma
            if not bullet.dead and self.boss.health > 0 and
               aabb(bullet.x, bullet.y, bullet.width, bullet.height,
                    self.boss.x, self.boss.y, self.boss.width, self.boss.height) then
                bullet.dead = true
                self.boss.health = self.boss.health - 1
                self.player.score = self.player.score + 50
            end
        end
    end

    --düşman mermi hareket + oyuncu çarpışma kontrolü
    local px, py, pw, ph = self.player:getHitbox()
    for i = #self.enemyBullets, 1, -1 do
        local b = self.enemyBullets[i]
        b:update(dt)
        if b.dead then
            table.remove(self.enemyBullets, i)
        elseif aabb(b.x, b.y, b.width, b.height, px, py, pw, ph) then
            b.dead = true
            self.player:takeDamage()
        end
    end

    for _, enemy in ipairs(self.enemies) do
        enemy:update(dt, self.player, self.enemyBullets)
    end

    if self.boss.health > 0 then
        self.boss:update(dt, self.player, self.enemyBullets)
    end

    --Temas hasarı: player düşmana değiyorsa takeDamage
    -- (player.iframes zaten spam'i önler)
    px, py, pw, ph = self.player:getHitbox()
    for _, enemy in ipairs(self.enemies) do
        if aabb(px, py, pw, ph, enemy.x, enemy.y, enemy.width, enemy.height) then
            self.player:takeDamage()
            break
        end
    end

    if self.boss.health > 0 and
       aabb(px, py, pw, ph, self.boss.x, self.boss.y, self.boss.width, self.boss.height) then
        self.player:takeDamage()
    end

    --skoru kaydet ve Win'e geç
    if self.boss.health <= 0 then
        self:saveScore(self.player.score)
        Gamestate.switch(Win, self.player.score)
    end
end

--yeni skoru top 3 listesine ekler ve diske kaydeder
function Play:saveScore(newScore)
    local scores = HighScore.loadScores()
    table.insert(scores, newScore)
    table.sort(scores, function(a, b) return a > b end)
    while #scores > 3 do table.remove(scores) end
    HighScore.saveScores(scores)
end

-- 3 katmanlı parallax arka planı çizer
-- Her katman farklı hızda kayarak derinlik hissi verir
function Play:drawBackground()
    local tileW = gSprites.bg1:getWidth()    -- 18 piksel
    local tileH = gSprites.bg1:getHeight()   -- 18 piksel
    local px    = self.player.x              -- oyuncu konumu = scroll referansı

    love.graphics.setColor(1, 1, 1)

    -- Katman 1: Gökyüzü %10 hızda kayar
    local off1 = (px * 0.1) % tileW
    for col = -1, math.ceil(VIRTUAL_WIDTH / tileW) + 1 do
        for row = 0, math.ceil((GROUND_Y) / tileH) do
            love.graphics.draw(gSprites.bg1, col * tileW - off1, row * tileH)
        end
    end

    -- Katman 2: Ağaçlar  %30 hızda kayar, sadece alt yarıda
    local off2 = (px * 0.3) % tileW
    local layer2Y = GROUND_Y - tileH * 3  -- zemine yakın bölge
    for col = -1, math.ceil(VIRTUAL_WIDTH / tileW) + 1 do
        for row = 0, 2 do
            love.graphics.draw(gSprites.bg2, col * tileW - off2, layer2Y + row * tileH)
        end
    end

    -- Katman 3: Yakın zemin detayı (en hızlı, %60 hızda kayar, sadece 1 satır)
    local off3 = (px * 0.6) % tileW
    local layer3Y = GROUND_Y - tileH  -- zemin çizgisinin hemen üstü
    for col = -1, math.ceil(VIRTUAL_WIDTH / tileW) + 1 do
        love.graphics.draw(gSprites.bg3, col * tileW - off3, layer3Y)
    end
end

function Play:draw()
    love.graphics.clear(0.53, 0.81, 0.98)  -- açık mavi gökyüzü tonu

    -- 3 katmanlı parallax arka plan
    self:drawBackground()

    -- Zemin şeridi (GROUND_Y'den ekranın altına)
    love.graphics.setColor(0.35, 0.55, 0.25)
    love.graphics.rectangle('fill', 0, GROUND_Y, VIRTUAL_WIDTH, VIRTUAL_HEIGHT - GROUND_Y)
    love.graphics.setColor(1, 1, 1)

    for _, enemy in ipairs(self.enemies) do
        enemy:draw()
    end

    if self.boss.health > 0 then
        self.boss:draw()
    end

    self.player:draw()

    --oyuncu mermisi sarı
    for _, b in ipairs(self.playerBullets) do
        b:draw()
    end

    --düşman mermileri: kırmızı
    love.graphics.setColor(1, 0.2, 0.2)
    for _, b in ipairs(self.enemyBullets) do
        love.graphics.rectangle('fill', b.x, b.y, b.width, b.height)
    end
    love.graphics.setColor(1, 1, 1)

    self:drawHUD()
end

function Play:drawHUD()
    love.graphics.setFont(gFonts.small)

    --OYUNCU CAN BARI
    local hpBarW  = 50          -- barın tam genişliği 
    local hpBarH  = 6           -- barın yüksekliği
    local hpBarX  = 8           -- sol kenardan uzaklık
    local hpBarY  = 8           -- üst kenardan uzaklık
    local maxHP   = 5           -- maksimum can 

    -- etiket
    love.graphics.setColor(1, 1, 1)
    love.graphics.print('HP', hpBarX, hpBarY - 1)

    -- arka plan 
    love.graphics.setColor(0.4, 0.1, 0.1)
    love.graphics.rectangle('fill', hpBarX + 12, hpBarY, hpBarW, hpBarH)

    -- can tam ise yeşil, yarıdan az ise sarı, 1 ise kırmızı
    local ratio = self.player.healthLevel / maxHP
    if ratio > 0.5 then
        love.graphics.setColor(0.2, 0.9, 0.2)   -- yeşil
    elseif ratio > 0.2 then
        love.graphics.setColor(1.0, 0.8, 0.0)   -- sarı
    else
        love.graphics.setColor(1.0, 0.2, 0.2)   -- kırmızı
    end
    love.graphics.rectangle('fill', hpBarX + 12, hpBarY, hpBarW * ratio, hpBarH)

    -- çerçeve
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle('line', hpBarX + 12, hpBarY, hpBarW, hpBarH)
    

    -- can sayısı ve skor 
    love.graphics.setColor(1, 1, 1)
    love.graphics.print('Lives: '  .. self.player.lives, 8, 18)
    love.graphics.print('Score: '  .. self.player.score, 8, 28)

    -- Boss can barı 
    if self.boss.health > 0 then
        love.graphics.printf('BOSS', 0, 4, VIRTUAL_WIDTH, 'center')
        local barW, barH = 80, 6
        local barX = (VIRTUAL_WIDTH - barW) / 2
        love.graphics.setColor(0.3, 0.3, 0.3) --boş kısım gri
        love.graphics.rectangle('fill', barX, 14, barW, barH)

        --dolu kısım faz1 mor faz 2 pembe
        love.graphics.setColor(self.boss.phase == 2 and {1, 0.1, 0.5} or {0.7, 0.2, 0.9})
        love.graphics.rectangle('fill', barX, 14, barW * (self.boss.health / 10), barH)
        love.graphics.setColor(1, 1, 1)
    end
end