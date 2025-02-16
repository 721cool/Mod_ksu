-- 参考泰拉光棱剑

local radian = math.pi/180
local auto = false
local TERRAPRISMA_CIRCLE = false     -- 环绕
local flydamage = 4



local i20cap = Class(function(self,inst)
    self.inst=inst
    self.player=nil
    self.weapon=nil
    self.status="pre_shoot"
    self.start_time=0
    self.follow_time=0
    self.last_hit_time=0
    self.circle_angle=0
    self.cd_time=0
    self.offset=0
    self.circle_angle=0
    self.clockwise=1

end)


function i20cap:Init(player,offset,weapon,id, target)
    self.inst.AnimState:PlayAnimation("idle")
    self.inst.AnimState:SetOrientation( ANIM_ORIENTATION.OnGround )
  
    self.offset=offset
    self.player=player
    self.weapon=weapon
    self.id=id

    local x,_,z = self.player.Transform:GetWorldPosition()
    --self.inst.Transform:SetPosition(x,_,z)
    -- if TERRAPRISMA_CIRCLE then
    --     self.inst.Transform:SetPosition(x,0,z)
    -- else
    --     --v2弃用
        -- local angle = self.player.Transform:GetRotation()
        -- local x1=x-math.cos(angle*radian)*(1+self.offset)
        -- local z1=z+math.sin(angle*radian)*(1+self.offset)
        -- self.inst.Transform:SetPosition(x1,_,z1)
        local angle = self.player.Transform:GetRotation() 
        local random = math.random()
        if random<0.25 then
            angle = angle+150
        elseif random<0.5 then
            angle = angle-150
        elseif random<0.75 then
            angle = angle+120
        else
            angle = angle-120
        end
        self.inst.Transform:SetRotation(angle)
        local x1=x+math.cos(angle*radian)*(4+self.offset)
        local z1=z-math.sin(angle*radian)*(4+self.offset)
        self.inst.Transform:SetPosition(x1,_,z1)

    -- end
    
    self.inst:StartUpdatingComponent(self)
    self.cd_time= -1

    if player and player:IsValid() then
        self.inst:ListenForEvent("i20tp", function(inst, data)
            if self.weapon and self.weapon:IsValid() and self.weapon.components.i20carrier then
                self.weapon.components.i20carrier:CSJS()
            end
            --self:SXPOS()  --v2弃用
        end, player)
    end

    if target then
        self:Shoot(target)
    end
    --self.inst:Hide()

end

function i20cap:SXPOS() --瞬移补丁
    if self.status~="follow" and self.status~="idle"
    then return end
    -- local x,_,z = self.player.Transform:GetWorldPosition()
    -- local i20carrier = self.weapon and self.weapon.components.i20carrier
    -- if not i20carrier then return end 
    -- self.inst.Transform:SetPosition(i20carrier.positions[self.id].x,_,i20carrier.positions[self.id].z)

    -- self.follow_time=GetTime()

    -- local angle = self.player.Transform:GetRotation()
    -- local x1=x-math.cos(angle*radian)*(1+self.offset)
    -- local z1=z+math.sin(angle*radian)*(1+self.offset)
    -- local x2,_,z2=self.inst.Transform:GetWorldPosition()

    -- -- if TERRAPRISMA_CIRCLE then
    -- --     local speed=((z2-i20carrier.positions[self.id].z)^2+(x2-i20carrier.positions[self.id].x)^2)*5
    -- --     self.inst.Physics:SetMotorVel(speed,0,0)
    -- --     self:RotateToTarget(Vector3(i20carrier.positions[self.id].x,0,i20carrier.positions[self.id].z))
    -- -- else
    --     --self.inst.Physics:SetMotorVel(self.player.components.locomotor:GetRunSpeed(),0,0)
    --     --self:RotateToTarget(Vector3(x1,0,z1))
    --     --if (x2-x1)*(x2-x1)+(z2-z1)*(z2-z1)<=0.1 then
    --         self.status="idle"
    --         self.inst.Physics:Stop()
    --         self.inst.Transform:SetPosition(x1,_,z1)
    --     --end
    -- --end
    local i20carrier = self.weapon and self.weapon.components.i20carrier
    if not i20carrier then return end 
    self.inst.Physics:Teleport(i20carrier.positions[self.id].x,0,i20carrier.positions[self.id].z)
    self.status="idle"
    self.inst.Physics:Stop()
    
end

function i20cap:GetFollowPosition()
    if TERRAPRISMA_CIRCLE then
        return Vector3(self.weapon.components.i20carrier.positions[self.id].x,0,self.weapon.components.i20carrier.positions[self.id].z)
    else
        local x,_,z = self.player.Transform:GetWorldPosition()
        local angle = self.player.Transform:GetRotation()
        local x1=x-math.cos(angle*DEGREES)*(1+self.offset)
        local z1=z+math.sin(angle*DEGREES)*(1+self.offset)
        return Vector3(x1,0,z1)
    end
end

function i20cap:OnUpdate(dt)
    if  self.player==nil or not self.player:IsValid() 
        or self.player.components.health:IsDead()
        or self.weapon==nil or not self.weapon:IsValid() then
        self.inst:Remove()
        return
    end

    local x,_,z = self.player.Transform:GetWorldPosition()
    if self.status~="idle" and self.status~="follow" then
        if self.target==nil or not self.target:IsValid() or self.target.components.health==nil
        or self.target.components.health:IsDead() then
            self.status="back"
        end
    elseif auto then
        self:FindEnemy(x,z)
    end

    if self.status=="idle" then
        if TERRAPRISMA_CIRCLE then
            self.follow_time=GetTime()
            self.status="follow"
        else
            local angle = self.player.Transform:GetRotation()
            local x1=x-math.cos(angle*radian)*(1+self.offset)
            local z1=z+math.sin(angle*radian)*(1+self.offset)
            local x2,_,z2=self.inst.Transform:GetWorldPosition()
            if (x2-x1)*(x2-x1)+(z2-z1)*(z2-z1)>=0.2 then
                self.follow_time=GetTime()
                self.status="follow"
            end
        end
    elseif self.status=="follow" then
        ----v2弃用
        -- if GetTime()>=self.follow_time+0.1 then
        --     local angle = self.player.Transform:GetRotation()
        --     local x1=x-math.cos(angle*radian)*(1+self.offset)
        --     local z1=z+math.sin(angle*radian)*(1+self.offset)
        --     local x2,_,z2=self.inst.Transform:GetWorldPosition()
        --     if TERRAPRISMA_CIRCLE then
        --         -- local speed=((z2-self.weapon.components.i20carrier.positions[self.id].z)^2+(x2-self.weapon.components.i20carrier.positions[self.id].x)^2)*5
        --         -- --self.inst.Physics:Teleport(self.weapon.components.i20carrier.positions[self.id].x,0,self.weapon.components.i20carrier.positions[self.id].z)
        --         -- --self:RotateToTarget(Vector3(self.weapon.components.i20carrier.positions2[self.id].x,0,self.weapon.components.i20carrier.positions2[self.id].z))
        --         -- self:RotateToTarget(Vector3(self.weapon.components.i20carrier.positions[self.id].x,0,self.weapon.components.i20carrier.positions[self.id].z))
        --         -- self.inst.Physics:SetMotorVel(speed,0,0)
            
        --         local pos = self.inst:GetPosition()
        --         local dest = self:GetFollowPosition()
        --         local distsq = pos:DistSq(dest)
        --         local speed = distsq*5
        --         self.inst.Physics:SetMotorVel(speed,0,0)
        --         self.inst:FacePoint(dest)
        --     else
        --         local speed = self.player.components.locomotor:GetRunSpeed()
        --         local dest = self:GetFollowPosition()
        --         self.inst.Physics:SetMotorVel(speed,0,0)
        --         self.inst:FacePoint(dest)

        --         if (x2-x1)*(x2-x1)+(z2-z1)*(z2-z1)<=0.1 then
        --             self.status="idle"
        --             self.inst.Physics:Stop()
        --             self.inst.Transform:SetPosition(x1,_,z1)
        --         end
        --     end
        -- end
        --v3
        --self.inst.Transform:SetPosition(x,_,z)
        self.inst:Remove()
    elseif self.status=="pre_shoot" then
        local Dt=GetTime()-self.start_time
        local x1,_,z1=self.inst.Transform:GetWorldPosition()
        self.inst.Transform:SetPosition(x1,1,z1)
        if Dt>= math.random()/5 + .2 then 
            self.status="shoot"
            self.inst:Show()
        end
    elseif self.status=="shoot" then
        self.inst.Physics:SetMotorVel(60, 0, 0)
        local dest=self.target:GetPosition()
        self:RotateToTarget(dest)
        local x1,_,z1=self.inst.Transform:GetWorldPosition()
        self.inst.Transform:SetPosition(x1,1,z1)
        if self:CheckHit() then
            self.last_hit_time=GetTime()
            self.circle_angle=self.inst:GetRotation()
            self.clockwise=math.random()>0.5 and 1 or -1
            self.status="circle"
        end
    elseif self.status=="circle" then
        if GetTime()>=self.last_hit_time+0.2 then
            self.inst.Physics:SetMotorVel(15, 0, 0)
            self.circle_angle=self.circle_angle+dt*300*self.clockwise
            if self.circle_angle>180 then
                self.circle_angle=self.circle_angle-360
            elseif self.circle_angle<-180 then
                self.circle_angle=self.circle_angle+360
            end
            self.inst.Transform:SetRotation(self.circle_angle)
            local x1,_,z1 = self.inst.Transform:GetWorldPosition()
            local x2,_,z2 = self.target.Transform:GetWorldPosition()
            local angle=math.atan2(z1-z2,x2-x1)/radian
            if math.abs(angle-self.circle_angle)<=12
            or(angle-self.circle_angle>0 and math.abs(angle-360-self.circle_angle)<=12)
            or(angle-self.circle_angle<0 and math.abs(self.circle_angle-360-angle)<=12) then
                self.status="shoot"
            end
        end
    elseif self.status=="back" then
        if self:CheckBack() then
            self.inst:Remove()
            return
        else
            local dest=self.player:GetPosition()
            self:RotateToTarget(dest)
            local x1,_,z1=self.inst.Transform:GetWorldPosition()
            self.inst.Transform:SetPosition(x1,1,z1)
            if (x1-x)*(x1-x)+(z1-z)*(z1-z)<=16 then
                self.inst.Physics:SetMotorVel(20,0,0)
            else
                self.inst.Physics:SetMotorVel(40,0,0)
            end
        end
        
        --v2弃用
        -- if TERRAPRISMA_CIRCLE then
        --     if self:CheckBack() then
        --         self.status="follow"
        --             self.inst:Hide()
        --         self.inst.AnimState:PlayAnimation("idle")
        --         self.inst.AnimState:SetOrientation( ANIM_ORIENTATION.BillBoard )
        --         self.inst.Transform:SetPosition(self.weapon.components.i20carrier.positions[self.id].x,0,self.weapon.components.i20carrier.positions[self.id].z)
        --         self.inst.Physics:Stop()
        --         self.cd_time=GetTime()
        --     else
        --         local dest=Vector3(self.weapon.components.i20carrier.positions[self.id].x,0,self.weapon.components.i20carrier.positions[self.id].z)
        --         self:RotateToTarget(dest)
        --         local x1,_,z1=self.inst.Transform:GetWorldPosition()
        --         self.inst.Transform:SetPosition(x1,1,z1)
        --         if (x1-x)*(x1-x)+(z1-z)*(z1-z)<=16 then
        --             self.inst.Physics:SetMotorVel(20,0,0)
        --         else
        --             self.inst.Physics:SetMotorVel(40,0,0)
        --         end
        --     end
        -- else
        --     if self:CheckBack() then
        --         self.status="idle"
        --             self.inst:Hide()
        --         self.inst.AnimState:PlayAnimation("idle")
        --         self.inst.AnimState:SetOrientation(ANIM_ORIENTATION.BillBoard)
        --         local angle = self.player.Transform:GetRotation()
        --         local x1=x-math.cos(angle*radian)*(1+self.offset)
        --         local z1=z+math.sin(angle*radian)*(1+self.offset)
        --         self.inst.Transform:SetPosition(x1,_,z1)
        --         self.inst.Physics:Stop()
        --         self.cd_time=GetTime()
        --     else
        --         local dest=self.player:GetPosition()
        --         self:RotateToTarget(dest)
        --         local x1,_,z1=self.inst.Transform:GetWorldPosition()
        --         self.inst.Transform:SetPosition(x1,1,z1)
        --         if (x1-x)*(x1-x)+(z1-z)*(z1-z)<=16 then
        --             self.inst.Physics:SetMotorVel(20,0,0)
        --         else
        --             self.inst.Physics:SetMotorVel(40,0,0)
        --         end
        --     end
        -- end
        self.cd_time=GetTime()
    end

    local x1,_,z1=self.inst.Transform:GetWorldPosition()
    local sqdistance=(x1-x)*(x1-x)+(z1-z)*(z1-z)
    if sqdistance>=1600 then
        self.status="back"
        if sqdistance>=3600 then
            self.inst.Transform:SetPosition(x,0,z)
        end
    end

end

function i20cap:Shoot(target)
    if not self.player or not self.player:IsValid() or self.player.components.health:IsDead() then return end 

    if self.status=="idle" or self.status=="follow" then
        if GetTime()<self.cd_time+0.1 then
            return
        end
        self.cd_time = GetTime()
        self.start_time=GetTime()
        self.target = target
        local facing_angle = self.player.Transform:GetRotation()
        local random = math.random()
        --v2弃用
        -- if self.id then
        --     if self.id == 1 then
        --         self.inst.Transform:SetRotation(facing_angle+150)
        --     elseif self.id == 2 then
        --         self.inst.Transform:SetRotation(facing_angle+120)
        --     elseif self.id == 3 then
        --         self.inst.Transform:SetRotation(facing_angle-120)
        --     else
        --         self.inst.Transform:SetRotation(facing_angle-150)
        --     end
        -- else
            if random<0.25 then
                self.inst.Transform:SetRotation(facing_angle+150)
            elseif random<0.5 then
                self.inst.Transform:SetRotation(facing_angle-150)
            elseif random<0.75 then
                self.inst.Transform:SetRotation(facing_angle+120)
            else
                self.inst.Transform:SetRotation(facing_angle-120)
            end
        --end
        -- local dest=self.target:GetPosition()
        -- self:RotateToTarget(dest)
            --self.inst:Show()
        self.inst.Physics:SetMotorVel(45, 0, 0)
        self.inst:PushEvent("onshoot", {thrower = self.player, target = self.target})
        self.status="pre_shoot"
    else
        self.target = target
    end
end

function i20cap:CheckHit()
    local start = self.inst:GetPosition()
    local dest = self.target:GetPosition()
    if start:DistSq(dest)<=6 then
        if not self.target.components.health or self.target.components.health:IsDead() then
            return true
        end
        if self.target.components.combat then
            if self.target.i20batktask ~= nil then  --标记
                self.target.i20batktask:Cancel()
                self.target.i20batktask = nil
            end
            self.target.i20batktask = self.target:DoTaskInTime(5, function()
                self.target.i20batktask = nil
            end)

            local realattk = self.player.components.combat.defaultdamage or 10
            local qwatk = flydamage
            local dmg, spdmg = self.player.components.combat:CalcDamage(self.target)
            local mult = dmg / realattk

            self.target.components.combat:GetAttacked(self.inst, qwatk * mult, nil, nil, spdmg)

            if self.target 
            and self.target:IsValid()
            and self.player
            and not self.target.i20killed
            and self.target.components.health 
            and self.target.components.health:IsDead() then
                self.target.i20killed = true

                self.player:PushEvent("killed", { victim = self.target, attacker = self.player })
                if self.target.components.combat and self.target.components.combat.onkilledbyother ~= nil then
                    self.target.components.combat.onkilledbyother(self.target, self.player)
                end
            end
        end
        local x,_,z=self.target.Transform:GetWorldPosition()
        SpawnPrefab("electrichitsparks").Transform:SetPosition(x,_,z)
        return true
    end
end

function i20cap:CheckBack()
    if TERRAPRISMA_CIRCLE then
        local x1,_,z1 = self.inst.Transform:GetWorldPosition()
        local x=self.weapon.components.i20carrier.positions[self.id].x
        local z=self.weapon.components.i20carrier.positions[self.id].z
        if (x1-x)*(x1-x)+(z1-z)*(z1-z)<=6 then
            return true
        end
    else
        local x,_,z = self.player.Transform:GetWorldPosition()
        local x1,_,z1 = self.inst.Transform:GetWorldPosition()
        if (x1-x)*(x1-x)+(z1-z)*(z1-z)<=6 then
            return true
        end
    end
end

function i20cap:RotateToTarget(dest)
    self.inst:FacePoint(dest)
end

function i20cap:FindEnemy(x,z)
    local ents = TheSim:FindEntities(x,0,z,16,{"_combat","_health" }, { "playerghost", "INLIMBO", "player","companion","wall" })
    for k, v in pairs(ents) do
        if  v.components.combat and v.components.combat.target==self.player
        and v.components.health and not v.components.health:IsDead() then
            if math.random()>0.6 then
                self:Shoot(v)
                return
            end
        end
    end
end

return i20cap
