Bullet = {}
Bullet.__index = Bullet

function Bullet.create(x, y, dir)
    local self = setmetatable({}, Bullet)
    self.x = x
    self.y = y
    self.dx = 240 * dir
    self.dy = 0  
    self.width = 4
    self.height = 4
    self.dead = false
    return self
end

function Bullet:update(dt)
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy *dt
    
    if self.x < 0 or self.x > VIRTUAL_WIDTH then
        self.dead = true
    end

    -- ekran dışına çıkınca yok et
    if self.y < 0 or self.y > VIRTUAL_HEIGHT or
    self.x < 0 or self.x > VIRTUAL_WIDTH then self.dead = true
end
end

function Bullet:draw()
    love.graphics.setColor(1, 0.8, 0)
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
    love.graphics.setColor(1, 1, 1)
end

return Bullet