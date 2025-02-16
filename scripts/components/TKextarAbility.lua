local wisprain_animation_util = require "util/wisprain_animation_util"
local TKextarAbility = Class(function(self, inst)
    self.inst = inst
    self.ability = nil
    self.ability_name = nil
end)
---------------------------影子部分
local function KillPet(pet)
    if pet.components.health:IsInvincible() then
        --reschedule
        pet._killtask = pet:DoTaskInTime(.5, KillPet)
    else
        pet.components.health:Kill()
    end
end
local function NotBlocked(pt)
    return not TheWorld.Map:IsGroundTargetBlocked(pt)
end
local function OnSpawnPet(inst, pet)
    if pet:HasTag("shadowminion") then
        if not (inst.components.health:IsDead() or inst:HasTag("playerghost")) then
            --if not inst.components.builder.freebuildmode then
            --  inst.components.sanity:AddSanityPenalty(pet, TUNING.SHADOWWAXWELL_SANITY_PENALTY[string.upper(pet.prefab)])
            --end
            inst:ListenForEvent("onremove", inst._onpetlost, pet)
            pet.components.skinner:CopySkinsFromPlayer(inst)
        elseif pet._killtask == nil then
            pet._killtask = pet:DoTaskInTime(math.random(), KillPet)
        end
    elseif inst._OnSpawnPet ~= nil then
        inst:_OnSpawnPet(pet)
    end
end

local function OnDespawnPet(inst, pet)
    if pet:HasTag("shadowminion") then
        if not inst.is_snapshot_user_session and pet.sg ~= nil then
            pet.sg:GoToState("quickdespawn")
        else
            pet:Remove()
        end
    elseif inst._OnDespawnPet ~= nil then
        inst:_OnDespawnPet(pet)
    end
end
local function FindSpawnPoints(doer, pos, num, radius)
    local ret = {}
    local theta, delta, attempts
    if num > 1 then
        delta = TWOPI / num
        attempts = 3
        theta = doer:GetAngleToPoint(pos) * DEGREES
        if num == 2 then
            theta = theta + PI * (math.random() < .5 and .5 or -.5)
        else
            theta = theta + PI
            if math.random() < .5 then
                delta = -delta
            end
        end
    else
        theta = 0
        delta = 0
        attempts = 1
        radius = 0
    end
    for i = 1, num do
        local offset = FindWalkableOffset(pos, theta, radius, attempts, false, false, NotBlocked, true, true)
        if offset ~= nil then
            table.insert(ret, Vector3(pos.x + offset.x, 0, pos.z + offset.z))
        end
        theta = theta + delta
    end
    return ret
end

local NUM_MINIONS_PER_SPAWN = 1
local function TrySpawnMinions(prefab, doer, pos)
    if doer.components.petleash ~= nil then
        local spawnpts = FindSpawnPoints(doer, pos, NUM_MINIONS_PER_SPAWN, 1)
        if #spawnpts > 0 then
            for i, v in ipairs(spawnpts) do
                local pet = doer.components.petleash:SpawnPetAt(v.x, 0, v.z, prefab)
                if pet ~= nil then
                    if pet.SaveSpawnPoint ~= nil then
                        pet:SaveSpawnPoint()
                    end
                    if #spawnpts > 1 and i <= 3 then
                        --restart "spawn" state with specified time multiplier
                        pet.sg.statemem.spawn = true
                        pet.sg:GoToState("spawn",
                            (i == 1 and 1) or
                            (i == 2 and .8) or
                            .87 + math.random() * .06
                        )
                    end
                end
            end
            return true
        end
    end
    return false
end
local function ReskinPet(pet, player, nofx)
    pet._dressuptask = nil
    if player:IsValid() then
        if not nofx then
            local x, y, z = pet.Transform:GetWorldPosition()
            local fx = SpawnPrefab("slurper_respawn")
            fx.Transform:SetPosition(x, y, z)
        end
        pet.components.skinner:CopySkinsFromPlayer(player)
    end
end

local function OnSkinsChanged(inst, data)
    for k, v in pairs(inst.components.petleash:GetPets()) do
        if v:HasTag("shadowminion") then
            if v._dressuptask ~= nil then
                v._dressuptask:Cancel()
                v._dressuptask = nil
            end
            if data and data.nofx then
                ReskinPet(v, inst, data.nofx)
            else
                v._dressuptask = v:DoTaskInTime(math.random() * 0.5 + 0.25, ReskinPet, inst)
            end
        end
    end
end
-------------------------月亮-----------------
local function OnIsFullmoon(inst, isfullmoon)
    if isfullmoon then
        inst.components.combat.damagemultiplier = 2 * TUNING.TSU_DAMAGEMUL
        --inst.components.health:SetMaxHealth(2 * TUNING.TSU_MAXHEALTH)
        inst.components.locomotor.runspeed = 10
        inst.components.ppower:MoonAdd(true)
        SpawnPrefab("alterguardian_phase3trapprojectile").Transform:SetPosition(inst.Transform:GetWorldPosition())
        inst:DoTaskInTime(0.5, function()
            SpawnPrefab("alterguardian_phase3trappst").entity:SetParent(inst.entity)
            SpawnPrefab("moonpulse_fx").entity:SetParent(inst.entity)
        end)
        inst.fullmoonfxtask = inst:DoPeriodicTask(1, function()
            if inst.components.health:IsDead() or not TheWorld.state.isfullmoon then
                if inst.fullmoonfxtask ~= nil then
                    inst.fullmoonfxtask:Cancel()
                    inst.fullmoonfxtask = nil
                end
                inst.components.combat.damagemultiplier = TUNING.TSU_DAMAGEMUL
                -- inst.components.health:SetMaxHealth(TUNING.TSU_MAXHEALTH)
                inst.components.locomotor.runspeed = 5.5
                inst.components.ppower:MoonAdd(false)
                return
            end
            inst.components.health:DoDelta(0.35)
            local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if not item or not item:HasTag("MIKASA") then
                inst.components.sanity:DoDelta(-0.2)
            end
        end, 1)
    else --月圆结束时退出状态
        inst.components.combat.damagemultiplier = TUNING.TSU_DAMAGEMUL
        inst.components.health:SetMaxHealth(TUNING.TSU_MAXHEALTH)
        inst.components.locomotor.runspeed = TUNING.TSU_RUNSPEED
        inst.components.ppower:MoonAdd(false)
        if inst.fullmoonfxtask ~= nil then
            inst.fullmoonfxtask:Cancel()
            inst.fullmoonfxtask = nil
        end
    end
end
----------------------------------------助跑跳
local function OnJump_high_start(inst)
    inst.circle = SpawnPrefab("reticuleaoesmallhostiletarget")
    inst.circle.entity:SetParent(inst.entity)
    inst.Jump_high_start = inst:DoPeriodicTask(0, function()
        local x, y, z = inst.Transform:GetWorldPosition()
        local mul = 10 + y
        if inst.circle then
            inst.circle.AnimState:SetScale(mul, mul, mul)
        end
        --随着高度而提升角色视野
        inst:AddCameraExtraDistance(inst, y * 3, "OnJump_high_start")
    end)
end
local function OnJump_over(inst)
    if inst.Jump_high_start ~= nil then
        inst.Jump_high_start:Cancel()
        inst.Jump_high_start = nil
    end
    if inst.circle ~= nil then
        inst.circle:Remove()
        inst.circle = nil
    end
    inst:RemoveCameraExtraDistance(inst, "OnJump_high_start")
end
----------------------------------------助跑跳
----能力1：MB防御
--宽广的防御，这片天空被我覆盖
---@15%免伤，空手翻倍
---

function TKextarAbility:Setobsord(inst)
    local defend = 0.2
    inst.components.health:SetAbsorptionAmount(2 * defend)
    inst.TKabsordtask1 = inst:ListenForEvent("unequip", function(inst, data)
        local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if not item then
            inst.components.health:SetAbsorptionAmount(2 * defend)
        else
            inst.components.health:SetAbsorptionAmount(defend)
        end
    end)
    inst.TKabsordtask2 = inst:ListenForEvent("equip", function(inst, data)
        local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if not item then
            inst.components.health:SetAbsorptionAmount(2 * defend)
        else
            inst.components.health:SetAbsorptionAmount(defend)
        end
    end)
end

-------------------------------------------------------------
----能力2：MB召唤影子朋友
----@这已经不是一般的怪物了，必须要重拳出击
function TKextarAbility:SetMoreFriends(inst)
    ----出动吧影子朋友们！对boss生物概率翻倍
    if inst.components.petleash ~= nil then
        inst._OnSpawnPet = inst.components.petleash.onspawnfn
        inst._OnDespawnPet = inst.components.petleash.ondespawnfn
        inst.components.petleash:SetMaxPets(inst.components.petleash:GetMaxPets() + 6)
    else
        inst:AddComponent("petleash")
        inst.components.petleash:SetMaxPets(6)
    end
    inst.components.petleash:SetOnSpawnFn(OnSpawnPet)
    inst.components.petleash:SetOnDespawnFn(OnDespawnPet)

    inst:ListenForEvent("onskinschanged", OnSkinsChanged) -- Fashion Shadows.
    inst.TKfriendstask = inst:ListenForEvent("onhitother", function(inst, data)
        local target = data.target
        local pos = inst:GetPosition()
        local per = 0.1
        if target:HasTag("epic") then per = 0.3 end
        if target and target.components.health and math.random() < per then
            inst.components.sanity:DoDelta(-15)
            TrySpawnMinions("shadowprotector", inst, pos)
        end
    end)
end

---能力3：当有生物主动仇恨时，开始认真
---@维持30s
---@慢性回san
---@增加20%移速
---@会对这些主动仇恨以及暗影生物产生25%的增伤（在extrapower中）
function TKextarAbility:SetSeriousTask(inst)
    inst:ListenForEvent("AgainstViciousness", function(inst, data)
        if inst.SeriousTask ~= nil then
            inst.SeriousTask:Cancel()
            inst.SeriousTask = nil
        end
        local eyesfx = SpawnPrefab("fx_righteye_blink")
        eyesfx.entity:SetParent(inst.entity)
        inst.components.locomotor:SetExternalSpeedMultiplier(inst, "sv_sp", 1.2)
        inst.AgainstViciousness = inst:DoPeriodicTask(3, function()
            inst.components.sanity:DoDelta(1)
        end)
        inst.SeriousTask = inst:DoTaskInTime(30, function()
            inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "sv_sp")
            inst.AgainstViciousness:Cancel()
            inst.AgainstViciousness = nil
        end)
    end)
end

function TKextarAbility:SetMoonSign(inst)
    if inst._light == nil then
        inst._light = SpawnPrefab("alterguardianhatlight")
        inst._light.entity:SetParent(inst.entity)
    end
end

------能力四：月光为月岛带来阴影

function TKextarAbility:MoonChange(inst)
    inst:WatchWorldState("isfullmoon", OnIsFullmoon)
end

-- 能力五：助跑跳时能随着跳跃高度提升视野和手中排球攻击范围
function TKextarAbility:SetRunJump(inst)
    inst:ListenForEvent("Jump_high_start", OnJump_high_start)
    inst:ListenForEvent("Jump_over", OnJump_over)
end

--能力六：月灵不会将月岛莹视作目标
---@在extrapower中完成


return TKextarAbility
