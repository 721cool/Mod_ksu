-- 参考泰拉光棱剑
local radian = math.pi/180
local R = 3 --环绕半径

local mikasacarrier = Class(function (self,inst)
    self.inst=inst

    self.num=3
    self.circle=0
    self.circle_angle=self.circle*radian
    self.circle_angle2=self.circle_angle*2
    self.per_angle=2*math.pi/self.num
    
    self.positions={
        [1]={},
        [2]={},
        [3]={},
    }
    -- self.positions2={   --计算下一个旋转目标位置
    --     [1]={},
    --     [2]={},
    --     [3]={},
    -- }
    self.cdtime = 0
    self:Init()
    self.inst:StartUpdatingComponent(self)
end)

local function cal_velocity(old_pos,pos,dt)
    local dx = pos.x - old_pos.x
    local dz = pos.z - old_pos.z
    local speed = math.sqrt(dx*dx+dz*dz)/dt
    return speed
end
local function cal_angle(start, dest)
    local x1 = start.x
    local z1 = start.z
    local x2 = dest.x
    local z2 = dest.z
    local angle=math.atan2(z1-z2,x2-x1)/DEGREES
    return angle--角度制单位
end


function mikasacarrier:OnUpdate(dt)
    if self.cdtime > 0 then
        self.cdtime = self.cdtime - dt 
        return
    end
    -- local x,_,z=self.inst.Transform:GetWorldPosition()
    -- self.circle=self.circle+dt*120
    -- if self.circle>180 then
    --     self.circle=self.circle-360
    -- end
    -- self.circle_angle=self.circle*radian
    -- for i = 0, self.num-1 do
    --     self.positions[i+1].x=x+R*math.sin(self.circle_angle+self.per_angle*i)
    --     self.positions[i+1].z=z+R*math.cos(self.circle_angle+self.per_angle*i)

    --     -- self.positions2[i+1].x=x+R*math.sin(self.circle_angle2+self.per_angle*i)
    --     -- self.positions2[i+1].z=z+R*math.cos(self.circle_angle2+self.per_angle*i)
    -- end

    --根据速度预测环绕中心点，减少落后
    local clientcc = false
    local x,_,z=self.inst.Transform:GetWorldPosition()
    if self.player and self.player:IsValid() and self.player.components.i20p and self.player.components.i20p.clientpos ~= nil then
        clientcc = true
        x = self.player.components.i20p.clientpos.x
        z = self.player.components.i20p.clientpos.z
    end
    local speed = cal_velocity(self.last_pos, {x=x,z=z}, dt)
    speed = math.min(speed, 12)
    if clientcc then
        speed = speed * 2.2 --延迟补偿情况下加大预测力度 
    end
    local angle = cal_angle(self.last_pos, {x=x,z=z})
    local x1=x+math.cos(angle*DEGREES)*speed*dt*4.5
    local z1=z-math.sin(angle*DEGREES)*speed*dt*4.5
    --更新旋转基准
    self.circle=self.circle+dt*120
    if self.circle>180 then
        self.circle=self.circle-360
    end
    self.circle_angle=self.circle*DEGREES
    --更新环绕位置
    for i = 0, self.num-1 do
        self.positions[i+1].x=x1+R*math.sin(self.circle_angle+self.per_angle*i)
        self.positions[i+1].z=z1+R*math.cos(self.circle_angle+self.per_angle*i)
    end
    --记录位置，用于下一帧
    self.last_pos = {x=x,z=z}
end

function mikasacarrier:CSJS()  --瞬移后，对延迟补偿情况下的补丁
    --TheNet:Say(1)
    if self.cdtime > 0 then return end 
    self.cdtime = 0.1
    local dt = 1/30
    local x,_,z=self.inst.Transform:GetWorldPosition()
    if self.player and self.player:IsValid() and self.player.components.i20p and self.player.components.i20p.clientpos ~= nil then
        self.player.components.i20p.clientpos = nil
    end
    self.last_pos = {x=x,z=z}
    local speed = cal_velocity(self.last_pos, {x=x,z=z}, dt)
    local speedlim = 12
    speed = math.min(speed, speedlim)
    local angle = cal_angle(self.last_pos, {x=x,z=z})
    local x1=x+math.cos(angle*DEGREES)*speed*dt*4.5
    local z1=z-math.sin(angle*DEGREES)*speed*dt*4.5
    
    --更新旋转基准
    self.circle=self.circle+dt*120
    if self.circle>180 then
        self.circle=self.circle-360
    end
    self.circle_angle=self.circle*DEGREES
    --更新环绕位置
    for i = 0, self.num-1 do
        self.positions[i+1].x=x1+R*math.sin(self.circle_angle+self.per_angle*i)
        self.positions[i+1].z=z1+R*math.cos(self.circle_angle+self.per_angle*i)
    end
    --记录位置，用于下一帧
    self.last_pos = {x=x,z=z}
end

function mikasacarrier:Init()

    local x,_,z=self.inst.Transform:GetWorldPosition()
    self.last_pos = {x=x,z=z}
    for i = 0, self.num-1 do
        self.positions[i+1].x=x+R*math.sin(self.circle_angle+self.per_angle*i)
        self.positions[i+1].z=z+R*math.cos(self.circle_angle+self.per_angle*i)
        -- self.positions2[i+1].x=x+R*math.sin(self.circle_angle+self.per_angle*i)
        -- self.positions2[i+1].z=z+R*math.cos(self.circle_angle+self.per_angle*i)
    end
end

function mikasacarrier:Shoit(doer, target)
    if target:HasTag("player") then return end  --玩家不受影响
    local num = #self.inst.caps
    if num < 4 then 
        for i=num+1, 4 do
            local capsword = SpawnPrefab("lightmikasa")
            capsword.components.i20cap:Init(doer, -0.5+0.25*i, self.inst, i, target)
            table.insert(self.inst.caps, capsword)
        end
    end 

    self.inst:DoTaskInTime(0, function()
        if not target or not target:IsValid() then return end 
        for k,v in pairs(self.inst.caps) do
            v.components.i20cap:Shoot(target)
        end
    end)

end

return mikasacarrier