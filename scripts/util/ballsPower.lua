local ballsPower = {}
ballsPower.balldata = {
    star = {
        speed = 13,
        backspeed = 7,
        range = 10,
        damage = 24,
        jumpspeed = 24,
        finiteuses = 100

    },
    mikasa = {
        speed = 13,
        backspeed = 9,
        range = 10,
        damage = 24,
        jumpspeed = 20,
        finiteuses = 100
    },
    moteng = {
        speed = 13,
        backspeed = 7,
        range = 10,
        damage = 24,
        jumpspeed = 20,
        finiteuses = 100

    },
    oball = {
        speed = 13,
        backspeed = 6,
        range = 10,
        damage = 24,
        jumpspeed = 20,
        finiteuses = 100
    }
}
ballsPower.ballseffects = {

    ["star"] = function(target)
        --目标当前血量*0.01+11
        if not target or not target:IsValid() or not target.components.health then return end
        local currentflood = target.components.health.currenthealth
        target.components.health:DoDelta(-(0.01 * currentflood + 23))
        --星星弹起特效  爆炸+范围随机击退效果
        SpawnPrefab("star_fx").entity:SetParent(target.entity)
        target:DoTaskInTime(0.4, function()
            SpawnPrefab("explosivehit").Transform:SetPosition(target.Transform:GetWorldPosition())
        end)
        local x, y, z = target.Transform:GetWorldPosition()
        target:DoTaskInTime(0.6, function()
            local ents = TheSim:FindEntities(x, y or 0, z, 4, { "_combat", "_health" }, { "companion" }, nil)
            for k, v in pairs(ents) do
                if v and v:IsValid() then
                    local a = math.random(1, 3)
                    local b = math.random(1, 2)
                    local c = math.random(1, 3)
                    v.Transform:SetPosition(x + a, y + b, z + c)
                end
            end
        end)
    end,
    ["mikasa"] = function(target)
        --目标攻击力*1.7 or 50
        --伤害类型为电击+0.35位面
        local damage = target.components.combat.defaultdamage * 1.7 or 51
        target.components.combat:GetAttacked(nil, damage, nil, "electric", { ["planar"] = 0.35 * damage })
        --电击特效
        SpawnPrefab("electrichitsparks").entity:SetParent(target.entity)
        target:DoTaskInTime(.7, function()
            SpawnPrefab("sparks").entity:SetParent(target.entity)
            local pos = target:GetPosition()
            SpawnPrefab("sparks").Transform:SetPosition(pos.x + 1, pos.y - 1, pos.z + 1)
            SpawnPrefab("sparks").Transform:SetPosition(pos.x - 1, pos.y - 1, pos.z + 1)
        end)
        --麻痹眩晕1.3s
        if target.brain and target.components.combat and target.components.locomotor then
            SpawnPrefab("lightning_rod_fx").Transform:SetPosition(target.Transform:GetWorldPosition())
            target.components.locomotor:Stop()
            target.brain:Stop()
            target:DoTaskInTime(1.3, function(target)
                target.brain:Start()
            end)
        end
    end,
    ["moteng"] = function(target)
        --4 段（15+10）伤害
        --召唤亮茄触手袭击
        if target.motemgtimestask ~= nil then
            target.motemgtimestask:Cancel()
            target.motemgtimestask = nil
        end
        target.motemgtimestask = target:DoPeriodicTask(1.5, function()
            if target and target:IsValid() and target.components.combat then
                target.components.combat:GetAttacked(nil, 15, nil, nil, { ["planar"] = 10 })
            end
        end)
        target:DoTaskInTime(6, function()
            if target.motemgtimestask ~= nil then
                target.motemgtimestask:Cancel()
                target.motemgtimestask = nil
            end
        end)
        --钻地亮茄攻击造成5s减速20%，10%概率再召唤一个亮茄
        SpawnPrefab("lunarthrall_plant_vine_end").Transform:SetPosition(target.Transform:GetWorldPosition())

        local pos = target:GetPosition()
        local a = math.random(10, 20) / 10
        local b = math.random(10, 20) / 10
        if not pos then return end
        SpawnPrefab("lunarthrall_plant_vine_end").Transform:SetPosition(pos.x + a, pos.y, pos.z + b)
        SpawnPrefab("lunarthrall_plant_vine_end").Transform:SetPosition(pos.x - b, pos.y, pos.z + a)
        if math.random(1, 100) <= 10 then
            local OP = SpawnPrefab("lunarthrall_plant")
            OP.Transform:SetPosition(pos.x, pos.y, pos.z)
            OP.components.combat:SetTarget(target)
            OP.task = OP:DoTaskInTime(25, function()
                if OP and OP:IsValid() then
                    OP:Remove()
                end
            end)
        end
        if target.components.locomotor then
            target.components.locomotor:SetExternalSpeedMultiplier(target, "moteng_slow1", 0.8)
        end
        target.SeriousTask = target:DoTaskInTime(5, function()
            if target and target:IsValid() and target.components.locomotor then
                target.components.locomotor:RemoveExternalSpeedMultiplier(target, "moteng_slow1")
            end
        end)
    end,
    ["oball"] = function(target)
        --5%概率生一个球
        if math.random(1, 100) <= 95 then return end
        local item = SpawnPrefab("oball")
        local tar = target
        local pt = Vector3(tar.Transform:GetWorldPosition()) + Vector3(0, 4.5, 0)
        item.Transform:SetPosition(pt:Get())
        local down = TheCamera:GetDownVec()
        local angle = math.atan2(down.z, down.x) + (math.random() * 60 - 30) * DEGREES
        local sp = math.random() * 4 + 2
        item.Physics:SetVel(sp * math.cos(angle), math.random() * 2 + 8, sp * math.sin(angle))
    end
}
function ballsPower.ballseffect(target, kind)
    local effect = ballsPower.ballseffects[kind]
    if effect then
        effect(target)
    end
end

function ballsPower.targettimes(inst, owner, target)
    if not target or not target:IsValid() then return end
    if not target:HasTag("volley_target") then
        target:AddTag("volley_target")
        target:DoTaskInTime(25, function()
            if target and target:IsValid() then
                target:RemoveTag("volley_target")
            end
        end)
    end
    local kind = inst.prefab

    if not target.ballslist then
        target.ballslist = {}
    end
    if not target.ballslist[kind] then
        target.ballslist[kind] = 0
    end
    target.ballslist[kind] = target.ballslist[kind] + 1

    -- SpawnPrefab("slurperlight").Transform:SetPosition(owner.Transform:GetWorldPosition())

    if target.ballslist[kind] >= 3 then
        local points = math.floor(math.random(1, 3))
        owner:PushEvent("y_getpoint")
        ballsPower.ballseffect(target, kind)
        target.ballslist[kind] = 0
    end
end

--每次攻击的伤害在throw的时候就已经决定
function ballsPower.extradamage(owner, target)
    if not owner or not target then return end
    local basic = 24
    local opmul = owner.components.ppower:Getmultipul()
    local speedmul = owner.components.locomotor:GetRunSpeed() / 6
    local damage1 = basic * opmul * speedmul
    ballsPower.ballED = damage1
    ballsPower.star = 0
    ballsPower.moteng = 0
end

function ballsPower.jitui(victim, pusher)
    if not victim or not pusher:HasTag('player') or not (victim.components.health and not victim.components.health:IsDead()) then return end
   
    local dist_push = 4.56
    local dist_push_player = 0.45
    local x1, y1, z1 = victim.Transform:GetWorldPosition()
    local x2, y2, z2 = pusher.Transform:GetWorldPosition()
    local dist = math.sqrt((x1 - x2) * (x1 - x2) + (z1 - z2) * (z1 - z2))
    local x3 = (x1 - x2) / dist * dist_push_player + x1
    local z3 = (z1 - z2) / dist * dist_push_player + z1

    if dist > 0 and not victim:HasTag('player') and not victim:HasTag('companion') then
        x3 = (x1 - x2) / dist * dist_push + x1
        z3 = (z1 - z2) / dist * dist_push + z1
    elseif dist <= 0 then
        return
    end
    if victim.Physics ~= nil then
        victim.Physics:Teleport(x3, 0, z3)
    else
        victim.Transform:SetPosition(x3, 0, z3)
    end

    if victim.sg.sg.states.hit then
        victim.AnimState:PlayAnimation("hit")
        victim.AnimState:PlayAnimation("hit")
    end
end

return ballsPower
