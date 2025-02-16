local assets1 = { Asset("ANIM", "anim/starg.zip"), Asset("ANIM", "anim/swapstar.zip"), Asset("ANIM", "anim/flystar.zip"),
    Asset("IMAGE", "images/inventoryimages/star.tex"),
    Asset("ATLAS", "images/inventoryimages/star.xml"),
}
local assets2 = {
    Asset("ANIM", "anim/mikasa.zip"), Asset("ANIM", "anim/swapmikasa.zip"),
    Asset("ATLAS", "images/inventoryimages/mikasa.xml"),
    Asset("IMAGE", "images/inventoryimages/mikasa.tex"),
    Asset("SOUNDPACKAGE", "sound/sukiplay.fev"), Asset("SOUND", "sound/suki.fsb")
}
local assets3 = {
    Asset("ANIM", "anim/moteng.zip"), Asset("ANIM", "anim/swapmoteng.zip"),
    Asset("IMAGE", "images/inventoryimages/moteng.tex"),
    Asset("ATLAS", "images/inventoryimages/moteng.xml"),

}
local assets4 = {
    Asset("ANIM", "anim/oBall.zip"), Asset("ANIM", "anim/swapoBall.zip"),
    Asset("IMAGE", "images/inventoryimages/oball.tex"),
    Asset("ATLAS", "images/inventoryimages/oball.xml"),
}
local bp = require "util/ballsPower"
local Bdata = bp.balldata
local Bstar = bp.balldata.star
local Bmikasa = bp.balldata.mikasa
local Bmoteng = bp.balldata.moteng
-------------------------------------------


local function onequipcommon(inst, owner, swap)
    owner.AnimState:OverrideSymbol("swap_object", swap, "balls")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    owner.AnimState:SetMultiSymbolExchange("swap_object", "hand") --把symbol1放到symbol2前
    if not owner.components.vollproficiency then
        owner:AddComponent("vollproficiency")
    end
    if owner.components.vollproficiency:Getvollproficiency() > 200 then
        inst.components.weapon:SetRange(12, 14)
    elseif owner.components.vollproficiency:Getvollproficiency() > 100 then
        inst.components.weapon:SetRange(10, 12)
    end
    --暂时一致使用
    inst.components.projectile:SetSpeed(Bstar.speed)
end
local swapstar = "swapstar"
local swapmikasa = "swapmikasa"
local swapmoteng = "swapmoteng"
local swapoBall = "swapoBall"
local function onequipo(inst, owner)
    onequipcommon(inst, owner, swapoBall)
end
local function OnEquips(inst, owner)
    onequipcommon(inst, owner, swapstar)
end
local function OnEquipmoteng(inst, owner)
    onequipcommon(inst, owner, swapmoteng)
end
local function OnEquipm(inst, owner)
    onequipcommon(inst, owner, swapmikasa)

    inst.components.mikasacarrier.player = owner
    if inst.udcptask ~= nil then
        inst.udcptask:Cancel()
        inst.udcptask = nil
    end
    inst.udcptask = inst:DoPeriodicTask(0, inst.UpdateCap)
end
local function OnDropped(inst)
    inst.AnimState:PlayAnimation("idle")
    inst.components.inventoryitem.pushlandedevents = true
    inst:PushEvent("on_landed")
end

local function OnUnequip(inst, owner)
    owner.AnimState:SetMultiSymbolExchange("hand", "swap_object")
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end
end

local function OnUnequipM(inst, owner)
    owner.AnimState:SetMultiSymbolExchange("hand", "swap_object")
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end
    for index, value in ipairs(inst.caps) do
        if value and value:IsValid() then
            value:Remove()
        end
    end

    inst.components.mikasacarrier.player = nil

    if inst.udcptask ~= nil then
        inst.udcptask:Cancel()
        inst.udcptask = nil
    end
    -- if inst.backfx ~= nil then
    --     inst.backfx:Remove()
    --     inst.backfx = nil
    -- end
    for k, v in pairs(inst.caps) do
        if v:IsValid() then
            v:Remove()
        end
    end
    inst.caps = {}
end
local function OnThrown(inst, owner, target)
    -- 播放回旋声音
    inst.gravitytask = inst:DoPeriodicTask(0, function()
        local x, y, z = inst.Transform:GetWorldPosition()
        if y > 1 then
            y = y - 0.2
            inst.Transform:SetPosition(x, y, z)
        end
    end)
    owner.SoundEmitter:PlaySound("sukiplay/suki/hit1")

    bp.extradamage(owner, target) --记录伤害
    --直接生吃飞行物
    inst.AnimState:PlayAnimation("fly", true)
    if inst.removeprojecttask ~= nil then
        inst.removeprojecttask:Cancel()
        inst.removeprojecttask = nil
    end
    inst.removeprojecttask = inst:DoPeriodicTask(0, function()
        local projectile = FindEntity(inst, 1, nil, { "projectile" }, { "y_volleyball" })
        if projectile and projectile:IsValid() then
            projectile:Remove()
        end
    end)
    inst.components.inventoryitem.pushlandedevents = false
end

local function OnCaught(inst, catcher)
    if catcher ~= nil and catcher.components.inventory ~= nil and catcher.components.inventory.isopen then
        if inst.components.equippable ~= nil and
            not catcher.components.inventory:GetEquippedItem(inst.components.equippable.equipslot) then
            catcher.components.inventory:Equip(inst)
        else
            catcher.components.inventory:GiveItem(inst)
        end
        catcher:PushEvent("catch")
    end
end

local function ReturnToOwner(inst, owner)
    if owner ~= nil and not (inst.components.finiteuses ~= nil and inst.components.finiteuses:GetUses() < 1) then
        owner.SoundEmitter:PlaySound("dontstarve/wilson/boomerang_return")
        inst.components.projectile:Throw(owner, owner)
    end
end
----------------------------------------------攻击效果------------------------------------------------

local function OnattackCallback(inst, target, owner)
    -- 排球少年高速附加攻击
    if target ~= nil and target:IsValid() then
        if owner:HasTag("volleyplayer") and owner.components.locomotor:GetRunSpeed() >= 8 then
            local pos = target:GetPosition()
            local ice = SpawnPrefab("antlion_sinkhole") --蚁狮坑洞
            ice.Transform:SetPosition(pos.x, pos.y, pos.z)
            ice:DoTaskInTime(3, function()
                ice:Remove()
            end)
        end
    end
end

-----------------------------------------------------



local function OnHit(inst, owner, target)
    local name = inst.prefab
    if inst.gravitytask ~= nil then
        inst.gravitytask:Cancel()
        inst.gravitytask = nil
    end
    if inst.removeprojecttask ~= nil then
        inst.removeprojecttask:Cancel()
        inst.removeprojecttask = nil
    end

    inst:PushEvent("volleyattack", { owner, target })

    if inst:HasTag("MIKASA") then
        print("MIKASA击飞你！")
        inst.components.mikasacarrier:Shoit(owner, target)
    end

    owner.SoundEmitter:PlaySound("sukiplay/suki/hited1")
 --球速带来的附加伤害和击退
    local ballspeed = inst.components.projectile.speed
    if ballspeed and ballspeed > 20 then
        target.components.health:DoDelta(-(ballspeed - 13) * 2)
        print("球速带来的附加伤害和击退", ballspeed)
        bp.jitui(target, owner)
    end

    --打到自己就落地
    --5/8概率飞回
    --3/8概率直接回到手上

    if owner == target or owner:HasTag("playerghost") then
        OnDropped(inst)
    elseif --慢速飞回
        math.random(1, 8) < 5 then
        inst.components.projectile:SetSpeed(Bdata[name].backspeed)
        ReturnToOwner(inst, owner)
    elseif inst.components.equippable ~= nil and
        not owner.components.inventory:GetEquippedItem(inst.components.equippable.equipslot) then
        owner.components.inventory:Equip(inst)
    else
        owner.components.inventory:GiveItem(inst)
    end
    --------------------------------------------------------
    if target ~= nil and target:IsValid() and target.components.combat then
        local impactfx = SpawnPrefab("impact")
        if impactfx ~= nil then
            local follower = impactfx.entity:AddFollower()
            follower:FollowSymbol(target.GUID, target.components.combat.hiteffectsymbol, 0, 0, 0)
            impactfx:FacePoint(inst.Transform:GetWorldPosition())
        end
    end
    -----------------------------------------------------------------
    if target:HasTag("player") then return end --防止秒了自己
    --每次攻击附带的伤害
    local dmg1 = bp.ballED
    target.components.health:DoDelta(-dmg1)
    local op = inst.prefab
    local dmg2 = bp[op]
    if dmg2 ~= nil then
        target.components.health:DoDelta(-dmg2)
    end
    --第三下强化攻击
    bp.targettimes(inst, owner, target)
    ---------------------------------------------------------------------------
    local function IsValidTarget(target)
        if target == nil or not (target:IsValid() and target.entity:IsVisible()) then
            return false
        end

        return true
    end
end
local function OnMiss(inst, owner, target)
    if owner == target then
        OnDropped(inst)
    else
        ReturnToOwner(inst, owner)
    end
end

local function onperish(inst) -- 耐久结束生成函数
    SpawnPrefab("glommerfuel").Transform:SetPosition(inst.Transform:GetWorldPosition())
    SpawnPrefab("petals").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst:Remove()
end

local function clientcommon(inst)
    inst.entity:AddTransform()
    inst.entity:AddAnimState() -- 增加动画标签
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst:AddTag("thrown")
    inst:AddTag("weapon")
    inst:AddTag("y_volleyball")
    inst:AddTag("projectile")
    local swap_data = {
        sym_build = "swapstar"
    }
    MakeInventoryFloatable(inst, "small", 0.18, { 0.8, 0.9, 0.8 }, true, -6, swap_data) -- 可漂浮于水上
    inst.entity:SetPristine()
end
local function master_common(inst)
    inst:AddComponent("finiteuses") -- 耐久度
    inst.components.finiteuses:SetMaxUses(100)
    inst.components.finiteuses:SetUses(100)
    inst.components.finiteuses:SetOnFinished(onperish)

    inst:AddComponent("weapon")             -- 武器组件
    inst.components.weapon:SetDamage(24)    -- 伤害
    inst.components.weapon:SetRange(12, 14) -- 设定范围
    inst.components.weapon:SetOnAttack(OnattackCallback)

    inst:AddComponent("inspectable")                             -- 可检查

    inst:AddComponent("projectile")                              -- 抛射体
    inst.components.projectile:SetLaunchOffset(Vector3(1, 2, 0)) -- 弹道偏移
    inst.components.projectile:SetSpeed(13)                      -- 弹道速度
    inst.components.projectile:SetCanCatch(true)
    inst.components.projectile:SetOnThrownFn(OnThrown)
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile:SetOnMissFn(OnMiss)
    inst.components.projectile:SetOnCaughtFn(OnCaught)

    inst:AddComponent("inventoryitem") -- 可收纳于物品栏
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
    inst:AddComponent("equippable")    -- 可装备组件

    inst.components.equippable:SetOnUnequip(OnUnequip)
    MakeHauntableLaunch(inst)
    inst:AddTag("volleyshop")
end
--普通起始球
local function fno()
    local inst = CreateEntity()
    clientcommon(inst)
    inst.AnimState:SetBank("oBall")
    inst.AnimState:SetBuild("oBall")
    inst.AnimState:PlayAnimation("idle")
    if not TheWorld.ismastersim then
        return inst
    end
    -- 关于主机
    master_common(inst)
    inst.components.inventoryitem.imagename = "oball"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/oball.xml"
    inst.components.equippable:SetOnEquip(onequipo)
    return inst
end
--世达
local function fns()
    local inst = CreateEntity()
    clientcommon(inst)
    inst.AnimState:SetBank("star")
    inst.AnimState:SetBuild("flystar")
    inst.AnimState:PlayAnimation("idle")
    if not TheWorld.ismastersim then
        return inst
    end
    -- 关于主机
    master_common(inst)
    inst.components.inventoryitem.imagename = "star"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/star.xml"
    inst.components.equippable:SetOnEquip(OnEquips)
    return inst
end
--魔腾
local function fnmoteng()
    local inst = CreateEntity()
    clientcommon(inst)

    inst.AnimState:SetBank("moteng")
    inst.AnimState:SetBuild("moteng")
    inst.AnimState:PlayAnimation("idle")
    --  inst.AnimState:SetRayTestOnBB(true)

    if not TheWorld.ismastersim then
        return inst
    end -- 关于主机
    master_common(inst)
    inst.components.inventoryitem.imagename = "moteng"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/moteng.xml"

    inst.components.equippable:SetOnEquip(OnEquipmoteng)

    return inst
end
--米卡萨
local function fnm()
    local inst = CreateEntity()
    clientcommon(inst)

    inst.AnimState:SetBank("mikasa")
    inst.AnimState:SetBuild("mikasa")
    inst.AnimState:PlayAnimation("idle")
    inst:AddTag("MIKASA")
    if not TheWorld.ismastersim then
        return inst
    end -- 关于主机
    master_common(inst)
    inst.components.inventoryitem.imagename = "mikasa"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/mikasa.xml"

    inst.components.equippable:SetOnEquip(OnEquipm)
    inst.components.equippable:SetOnUnequip(OnUnequipM)
    inst.caps = {}
    inst:AddComponent("mikasacarrier")

    inst.UpdateCap = function(inst)
        local owner = inst.components.inventoryitem:GetGrandOwner()
        if not owner then
            for k, v in pairs(inst.caps) do
                if v:IsValid() then
                    v:Remove()
                end
            end
            inst.caps = {}
            return
        end

        for k, v in pairs(inst.caps) do
            if not v:IsValid() then
                inst.caps[k] = nil
            elseif v.components.i20cap.status == "idle" or v.components.i20cap.status == "follow" then
                v:Remove()
                inst.caps[k] = nil
            end
        end
    end
    return inst
end

-------------------------------特效------------------------------
---
local function Projectile_CreateTailFx()
    local WEIGHTED_TAIL_FXS =
    {
        ["idle1"] = 1,
        ["idle2"] = .5,
    }

    local inst = CreateEntity()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    -- inst.AnimState:SetBank("lavaarena_blowdart_attacks")
    -- inst.AnimState:SetBuild("lavaarena_blowdart_attacks")
    inst.AnimState:SetBank("i20projtail")
    inst.AnimState:SetBuild("i20projtail")
    inst.AnimState:PlayAnimation(weighted_random_choice(WEIGHTED_TAIL_FXS))
    -- inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)

    inst.AnimState:SetLightOverride(0.3)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    local alpha = 0.75
    local r, g, b = 200 / 255, 200 / 255, 0 / 255
    -- inst.AnimState:SetMultColour(r, g, b, alpha)
    inst.AnimState:OverrideMultColour(r, g, b, alpha)

    inst:ListenForEvent("animover", inst.Remove)

    return inst
end
local function CalVelocity(pos, old_pos, dt)
    local dx = pos.x - old_pos.x
    local dz = pos.z - old_pos.z
    local speed = math.sqrt(dx * dx + dz * dz) / dt
    return speed
end
local function CalAngle(pos, old_pos)
    local x1 = old_pos.x
    local z1 = old_pos.z
    local x2 = pos.x
    local z2 = pos.z
    local angle = math.atan2(z1 - z2, x2 - x1) / DEGREES
    return angle
end
local function Projectile_UpdateTail(inst)
    local x, _, z = inst.Transform:GetWorldPosition()
    local time = GetTime()
    if not inst:HasTag('NoTail') then
        --客机无法通过Physics获取速度
        local speed = CalVelocity({ x = x, z = z }, inst.last_pos, time - inst.last_time)
        speed = math.min(speed, 65)
        local scale = (speed > 5) and ((speed / 30 - 1) * 0.6 + 1.2) or 0
        local tail_1 = inst:CreateTailFx()
        --速度越大，尾迹越长
        tail_1.Transform:SetScale(scale, scale, scale)
        tail_1.Transform:SetPosition(inst.Transform:GetWorldPosition())
        -- 不使用inst.Transform:GetRotation()，以提升尾迹连贯性
        local angle = CalAngle({ x = x, z = z }, inst.last_pos)
        tail_1.Transform:SetRotation(angle)
    end
    inst.last_pos = { x = x, z = z }
    inst.last_time = time
end
-----
local TERRAPRISMA_SHINING = true --泛光效果
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddLight()
    inst.entity:SetCanSleep(false)

    MakeInventoryPhysics(inst)

    inst.Light:SetFalloff(0.5)
    inst.Light:SetIntensity(0.8)
    inst.Light:SetRadius(1.2)
    inst.Light:SetColour(200 / 255, 200 / 255, 0 / 255)
    inst.Light:Enable(true)
    inst.Light:EnableClientModulation(true)

    inst.Physics:ClearCollidesWith(COLLISION.LIMITS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)

    if TERRAPRISMA_SHINING then
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    end

    inst.AnimState:SetBank("mikasa")
    inst.AnimState:SetBuild("mikasa")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")
    -- inst:AddTag("i20zy")

    --尾迹,非专用服务器
    if not TheNet:IsDedicated() then
        local x, _, z     = inst.Transform:GetWorldPosition()
        inst.last_pos     = { x = x, z = z }
        inst.last_time    = GetTime()
        inst.CreateTailFx = function(inst) return Projectile_CreateTailFx() end
        inst.UpdateTail   = Projectile_UpdateTail
        inst:DoPeriodicTask(0, inst.UpdateTail)
    end

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end
    inst.persists = false

    inst:AddComponent("i20cap")
    inst:AddComponent("combat")

    inst:ListenForEvent("onshoot", function(inst, data)
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    end)

    MakeHauntableLaunch(inst)

    return inst
end


return
    Prefab("star", fns, assets1), Prefab("mikasa", fnm, assets2), Prefab("moteng", fnmoteng, assets3),
    Prefab("lightmikasa", fn, assets2), Prefab("oball", fno, assets4)
