local interaction_list = {
    'wall_hay',
    'wall_wood',
    'wall_stone',
    'wall_ruins',
    'wall_moonrock',

    "rock1",
    "rock_moon",
    "rock_flintless",
    "rock_flintless_med",
    "rock_flintless_low",
    "pond",
    "pond_mos",
    "pond_cave",
    "lava_pond",

    "pigman",
    "bunnyman",
    "perd",
    "spider",
    "frog",
    "hound",
    "firehound",
    "icehound",
    "walrus",
    "merm",
    "knight",
    "bishop",
    "krampus",
    "mossling",
    "chester",
    "tallbird",
    "babybeefalo",

    "molehill",
    "mound",
    "skeleton",
    "skeleton_player",

    "twigs"
}

for k, v in pairs(interaction_list) do
    AddPrefabPostInit(v, function(inst)
        if GLOBAL.TheWorld.ismastersim then
            inst:AddComponent("interactions")
        end
    end)
end

AddPlayerPostInit(function(inst)
    if GLOBAL.TheWorld.ismastersim and inst:HasTag("tsukishima") then
        inst:AddComponent("interactions")
        inst:DoPeriodicTask(0.25, function()
            if inst.Transform and inst.Transform.GetRotation then
                inst.old_rotation = inst.Transform:GetRotation()
            end
        end)
    end
end)

-- Actions ------------------------------

AddAction("WALLJUMP", "跨过去", function(act)
    if act.doer ~= nil and act.target ~= nil and act.doer:HasTag('player') and act.target.components.interactions and act.target:HasTag("wall") and (act.target.components.health == nil or not act.target.components.health:IsDead()) then
        act.target.components.interactions:WallJump(act.doer)
        return true
    else
        return false
    end
end)

AddAction("JUMPOVER", "跳过去", function(act)
    if act.doer ~= nil and act.target ~= nil and act.doer:HasTag('player') and act.target.components.interactions and (act.target:HasTag("boulder") or act.target:HasTag("watersource") or act.target:HasTag("lava") or act.doer == act.target or act.target:HasTag("cattoy")) then
        act.target.components.interactions:Jump(act.doer)
        return true
    else
        act.doer.sg:GoToState("idle")
        return false
    end
end)


AddAction("PUSH", "推开", function(act)
    if act.doer ~= nil and act.target ~= nil and act.target ~= act.doer and act.doer:HasTag('player') and act.doer.components.interactions and act.target:HasTag("player") and act.target ~= act.doer then
        act.doer.components.interactions:Push(act.target)
        return true
    else
        return false
    end
end)

AddAction("SHOVE", "滚开", function(act)
    if act.doer ~= nil and act.target ~= nil and act.target ~= act.doer and act.doer:HasTag('player') and act.doer.components.interactions and (act.target:HasTag("character") or act.target:HasTag("monster") or act.target:HasTag("animal") or act.target:HasTag("beefalo")) and act.target ~= act.doer then
        act.doer.components.interactions:Push(act.target)
        return true
    else
        return false
    end
end)



-- Component actions ---------------------

AddComponentAction("SCENE", "interactions", function(inst, doer, actions, right)
    if right then
        if inst:HasTag("wall") and (inst.components.health == nil or not inst.components.health:IsDead()) then
            table.insert(actions, GLOBAL.ACTIONS.WALLJUMP)
        elseif inst:HasTag("boulder") or inst:HasTag("watersource") or inst:HasTag("lava") or inst == doer or inst:HasTag("cattoy") then
            table.insert(actions, GLOBAL.ACTIONS.JUMPOVER)
        elseif inst:HasTag("player") and inst ~= doer then
            table.insert(actions, GLOBAL.ACTIONS.PUSH)
        elseif (inst:HasTag("character") or inst:HasTag("monster") or inst:HasTag("animal") or inst:HasTag("beefalo")) and inst ~= doer then
            table.insert(actions, GLOBAL.ACTIONS.SHOVE)
        end
    end
end)

-- Stategraph ----------------------------

local state_walljump = GLOBAL.State { name = "walljump",
    tags = { "doing", "busy" },

    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("jump_pre")
        inst.AnimState:PlayAnimation("jumpout")
        inst.Physics:SetMotorVel(0, 0, 0)

        inst.sg.statemem.action = inst.bufferedaction
        inst.sg:SetTimeout(2)
        if not GLOBAL.TheWorld.ismastersim then
            inst:PerformPreviewBufferedAction()
        end
    end,

    timeline =
    {
        GLOBAL.TimeEvent(4 * GLOBAL.FRAMES, function(inst)
            inst.sg:RemoveStateTag("busy")
        end),
        GLOBAL.TimeEvent(9 * GLOBAL.FRAMES, function(inst)
            if GLOBAL.TheWorld.ismastersim then
                inst:PerformBufferedAction()
            end
            inst.Physics:SetMotorVel(1.5, 0, 0)
        end),
        GLOBAL.TimeEvent(15 * GLOBAL.FRAMES, function(inst)
            inst.Physics:SetMotorVel(1, 0, 0)
        end),
        GLOBAL.TimeEvent(15.2 * GLOBAL.FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
        end),
        GLOBAL.TimeEvent(17 * GLOBAL.FRAMES, function(inst)
            inst.Physics:SetMotorVel(0.5, 0, 0)
        end),
        GLOBAL.TimeEvent(18 * GLOBAL.FRAMES, function(inst)
            inst.Physics:Stop()
        end),
    },

    onupdate = function(inst)
        if not GLOBAL.TheWorld.ismastersim then
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle", true)
            end
        end
    end,

    ontimeout = function(inst)
        if not GLOBAL.TheWorld.ismastersim then
            inst:ClearBufferedAction() -- client
        end
        inst.sg:GoToState("idle")
    end,

    onexit = function(inst)
        if inst.bufferedaction == inst.sg.statemem.action then
            inst:ClearBufferedAction()
        end
        inst.sg.statemem.action = nil
    end,
}
AddStategraphState("wilson", state_walljump)
AddStategraphState("wilson_client", state_walljump)

local state_freejump_pre = GLOBAL.State { name = "freejump_pre",
    tags = { "doing", "busy", "canrotate", "nomorph" },

    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("jump_pre")
        inst.sg:SetTimeout(GLOBAL.FRAMES * 18)

        if not GLOBAL.TheWorld.ismastersim then
            inst:PerformPreviewBufferedAction()
        end
    end,

    timeline =
    {
        GLOBAL.TimeEvent(1 * GLOBAL.FRAMES, function(inst)
            if GLOBAL.TheWorld.ismastersim then
                inst:PerformBufferedAction()
            end
        end),
    },

    events =
    {
        GLOBAL.EventHandler("animover", function(inst)
            inst.sg:GoToState("freejump")
        end),
    },

    onupdate = function(inst)
        if not GLOBAL.TheWorld.ismastersim then
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle", true)
            end
        end
    end,

    ontimeout = function(inst)
        if not GLOBAL.TheWorld.ismastersim then -- client
            inst:ClearBufferedAction()
        end
        inst.sg:GoToState("idle")
    end,

    onexit = function(inst)
        if inst.bufferedaction == inst.sg.statemem.action then
            inst:ClearBufferedAction()
        end
        inst.sg.statemem.action = nil
    end,
}
AddStategraphState("wilson", state_freejump_pre)
AddStategraphState("wilson_client", state_freejump_pre)
--跳跃高额移速加成1秒
local function speedjumptask(inst, speedmult, t)
    if inst.components.locomotor then
        inst.components.locomotor.runspeed = inst.components.locomotor.runspeed + speedmult
        inst.components.locomotor.walkspeed = inst.components.locomotor.walkspeed + speedmult
        -- SpawnPrefab("shield").entity:SetParent(inst.entity)
        SpawnPrefab("fx_book_moon").Transform:SetPosition(inst.Transform:GetWorldPosition())
        local op = SpawnPrefab("fx_matrix_multcolor_spred")
        op.entity:SetParent(inst.entity)
        inst:DoTaskInTime(t, function()
            inst.components.locomotor.runspeed = inst.components.locomotor.runspeed - speedmult
            inst.components.locomotor.walkspeed = inst.components.locomotor.walkspeed - speedmult
        end)
    end
end
--0.4S触球+无敌
AddStategraphState("wilson", GLOBAL.State { name = "freejump",
    tags = { "doing", "busy" },

    onenter = function(inst)
        inst.components.locomotor:Stop()
        --GLOBAL.ChangeToGhostPhysics(inst)
        inst.Physics:ClearCollisionMask()
        inst.Physics:CollidesWith(GLOBAL.COLLISION.GROUND)
        inst.Physics:CollidesWith(GLOBAL.COLLISION.CHARACTERS)
        inst.Physics:CollidesWith(GLOBAL.COLLISION.GIANTS)

        inst.AnimState:PlayAnimation("jumpout")
        inst.Physics:SetMotorVel(9.3, 0, 0)

        inst.sg.statemem.action = inst.bufferedaction
        inst.sg:SetTimeout(30 * GLOBAL.FRAMES)
        local delta_jump = 4
        inst:PushEvent("opjump", { delta=delta_jump })
        inst.throwvoleytask = inst:DoPeriodicTask(0, function()
            --xxs无敌
            inst.components.health:SetInvincible(true)
            local musttags = { "y_volleyball" }

            local ent = FindEntity(inst, 1, nil, musttags)
            local targ = FindEntity(inst, 24, nil, { "volley_target" })
            if ent ~= nil and targ ~= nil then
                local speed = inst.components.locomotor:GetRunSpeed()
                ent.components.projectile:SetSpeed(speed+10)
                ent.components.projectile:Throw(inst, targ)
                local x, y, z = inst.Transform:GetWorldPosition()
                SpawnPrefab("balloon_pop_head").Transform:SetPosition(x, y, z)
                if inst.throwvoleytask ~= nil then
                    inst.throwvoleytask:Cancel()
                    inst.throwvoleytask = nil
                end
            end
        end, 0.15)
        inst:DoTaskInTime(0.55, function()
            if
                inst.throwvoleytask ~= nil then
                inst.throwvoleytask:Cancel()
                inst.throwvoleytask = nil
            end
            inst.components.health:SetInvincible(false)
            inst:PushEvent("opjump", { delta = delta_jump })
        end)
    end,
    timeline =
    {
        GLOBAL.TimeEvent(4.5 * GLOBAL.FRAMES, function(inst)
            inst.Physics:SetMotorVel(8.4, 0, 0)
        end),
        GLOBAL.TimeEvent(9 * GLOBAL.FRAMES, function(inst)
            inst.Physics:SetMotorVel(7.7, 0, 0)
        end),
        GLOBAL.TimeEvent(13.5 * GLOBAL.FRAMES, function(inst)
            inst.Physics:SetMotorVel(7.1, 0, 0)
        end),
        GLOBAL.TimeEvent(15.2 * GLOBAL.FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
        end),
        GLOBAL.TimeEvent(16 * GLOBAL.FRAMES, function(inst)
            inst.Physics:SetMotorVel(2, 0, 0)
        end),
        GLOBAL.TimeEvent(18 * GLOBAL.FRAMES, function(inst)
            inst.Physics:Stop()
        end),
    },

    events =
    {
        GLOBAL.EventHandler("animqueueover", function(inst)
            local x, y, z = inst.Transform:GetWorldPosition()
            if inst.AnimState:AnimDone() then
                GLOBAL.ChangeToCharacterPhysics(inst)
                inst.Transform:SetPosition(x, 0, z)
                inst.sg:GoToState("idle")
                --
                speedjumptask(inst, 6, 1)
            end
        end),
    },

    ontimeout = function(inst)
        if not GLOBAL.TheWorld.ismastersim then -- client
            inst:ClearBufferedAction()
        end
        GLOBAL.ChangeToCharacterPhysics(inst)
        local x, y, z = inst.Transform:GetWorldPosition()
        inst.Transform:SetPosition(x, 0, z)
        inst.sg:GoToState("idle")
        --落地加速
        --speedjumptask(inst, 2, 1)
    end,

    onexit = function(inst)
        GLOBAL.ChangeToCharacterPhysics(inst)
        local x, y, z = inst.Transform:GetWorldPosition()
        inst.Transform:SetPosition(x, 0, z)
        if inst.bufferedaction == inst.sg.statemem.action then
            inst:ClearBufferedAction()
        end

        inst.sg.statemem.action = nil
    end,
})

local function DoTalkSound(inst)
    if inst.talksoundoverride ~= nil then
        inst.SoundEmitter:PlaySound(inst.talksoundoverride, "talk")
        return true
    elseif not inst:HasTag("mime") then
        inst.SoundEmitter:PlaySound(
            (inst.talker_path_override or "dontstarve/characters/") .. (inst.soundsname or inst.prefab) .. "/talk_LP",
            "talk")
        return true
    end
end

local function IsNearDanger(inst)
    local hounded = GLOBAL.TheWorld.components.hounded
    if hounded ~= nil and (hounded:GetWarning() or hounded:GetAttacking()) then
        return true
    end
    local burnable = inst.components.burnable
    if burnable ~= nil and (burnable:IsBurning() or burnable:IsSmoldering()) then
        return true
    end
    if inst:HasTag("spiderwhisperer") then
        return GLOBAL.FindEntity(inst, 10,
            function(target)
                return (target.components.combat ~= nil and target.components.combat.target == inst)
                    or (not (target:HasTag("player") or target:HasTag("spider"))
                        and (target:HasTag("monster") or target:HasTag("pig")))
            end,
            nil, nil, { "monster", "pig", "_combat" }) ~= nil
    end
    return GLOBAL.FindEntity(inst, 14,
        function(target)
            return (target.components.combat ~= nil and target.components.combat.target == inst)
                or (target:HasTag("monster") and not target:HasTag("player"))
        end,
        nil, nil, { "monster", "_combat" }) ~= nil
end






local state_push = GLOBAL.State { name = "push",
    tags = { "doing", "busy" },

    onenter = function(inst)
        inst.components.locomotor:Stop()

        local handitem = nil
        if inst.components.inventory then
            handitem = inst.components.inventory.equipslots[GLOBAL.EQUIPSLOTS.HANDS]
        elseif inst.replica.inventory then
            handitem = inst.replica.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
        end
        if handitem then
            inst.AnimState:Hide("ARM_carry")
            inst.AnimState:Show("ARM_normal")
        end

        inst.AnimState:PlayAnimation("punch")
        inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)

        inst.sg.statemem.action = inst.bufferedaction
        inst.sg:SetTimeout(2)

        if not GLOBAL.TheWorld.ismastersim then
            inst:PerformPreviewBufferedAction()
        end
    end,

    timeline =
    {
        GLOBAL.TimeEvent(8 * GLOBAL.FRAMES, function(inst)
            if GLOBAL.TheWorld.ismastersim then
                inst:PerformBufferedAction()
            end
        end),
        GLOBAL.TimeEvent(15 * GLOBAL.FRAMES, function(inst)
            inst.sg:RemoveStateTag("busy")
        end),
    },

    onupdate = function(inst)
        if not GLOBAL.TheWorld.ismastersim then
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle", true)
            end
        end
    end,
    --[[
	events =
	{
		GLOBAL.EventHandler("animqueueover", function(inst)
			if inst.AnimState:AnimDone() then
				inst.sg:GoToState("idle")
			end
		end),
	},
]]
    ontimeout = function(inst)
        local handitem = nil
        if inst.components.inventory then
            handitem = inst.components.inventory.equipslots[GLOBAL.EQUIPSLOTS.HANDS]
        elseif inst.replica.inventory then
            handitem = inst.replica.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
        end
        if handitem then
            inst.AnimState:Show("ARM_carry")
            inst.AnimState:Hide("ARM_normal")
        end

        if not GLOBAL.TheWorld.ismastersim then
            inst:ClearBufferedAction() -- client
        end
        inst.sg:GoToState("idle")
    end,

    onexit = function(inst)
        local handitem = nil
        if inst.components.inventory then
            handitem = inst.components.inventory.equipslots[GLOBAL.EQUIPSLOTS.HANDS]
        elseif inst.replica.inventory then
            handitem = inst.replica.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
        end
        if handitem then
            inst.AnimState:Show("ARM_carry")
            inst.AnimState:Hide("ARM_normal")
        end

        if inst.bufferedaction == inst.sg.statemem.action then
            inst:ClearBufferedAction()
        end
        inst.sg.statemem.action = nil
    end,
}
AddStategraphState("wilson", state_push)
AddStategraphState("wilson_client", state_push)

local actions = {
    { action = GLOBAL.ACTIONS.WALLJUMP, state = "walljump" },
    { action = GLOBAL.ACTIONS.JUMPOVER, state = "freejump_pre" },

    { action = GLOBAL.ACTIONS.PUSH,     state = "push" },
    { action = GLOBAL.ACTIONS.SHOVE,    state = "push" },
    --{action = GLOBAL.ACTIONS.SEARCH, state = "dolongaction"}
}

local characters = { "wilson", "wilson_client" }

for _, char in ipairs(characters) do
    for _, action in ipairs(actions) do
        AddStategraphActionHandler(char, GLOBAL.ActionHandler(action.action, action.state))
    end
end

--*************************按下按键触发的动作**********************--
--按下J向前跳
local function volljump(player)
    if not player or not player.components.ppower:GetActionLine() then return end
    player.sg:GoToState("freejump_pre")
end


AddModRPCHandler("volleyball", "y_jump", volljump)

local function SendGrowGiantRPC()
    SendModRPCToServer(GetModRPC("volleyball", "y_jump"))
end

GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_J, SendGrowGiantRPC)


--按下O向前冲刺再往上跳  体力消耗两次
local function vollrunjump(player)
    if not player or not player.components.ppower:GetActionLine() then return end

    player.Physics:SetMotorVel(25, 0, 0)
    player.AnimState:PlayAnimation("run_loop", true)
    --残影
    player.SBtask = player:DoPeriodicTask(0.05, function()
        local afterimage = SpawnPrefab("alpha_afterimage")
        if afterimage ~= nil then
            afterimage:CopyAppearance(player)
            afterimage:Init(player)
        end
    end)
    player.components.ppower:DoDelta(-8)
    player:DoTaskInTime(0.3, function()
        player.Physics:Stop()
        if player.SBtask then
            player.SBtask:Cancel()
            player.SBtask = nil
        end
        player.AnimState:PlayAnimation("deploytoss_lag")
        if player.runjumptask ~= nil then
            player.runjumptask:Cancel()
            player.runjumptask = nil
        end
        player:PushEvent("Jump_high_start")
        player.runjumptask = player:DoPeriodicTask(0, function()
            local x, y, z = player.Transform:GetWorldPosition()
            if y <= 3 then
                player.Transform:SetPosition(x, y + 0.5, z)
            else
                local item = player.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                if item and item:HasTag("y_volleyball") then
                    item.components.projectile:SetSpeed(24)
                end
                player.components.ppower:DoDelta(-8)
                if player.runjumptask then
                    player.runjumptask:Cancel()
                    player.runjumptask = nil
                end
                player.runjumptask2 = player:DoPeriodicTask(0, function()
                    local x, y, z = player.Transform:GetWorldPosition()
                    if y > 0.3 then
                        player.Transform:SetPosition(x, y - 0.3, z)
                    else
                        player:PushEvent("Jump_over")
                        if player.runjumptask2 then
                            player.runjumptask2:Cancel()
                            player.runjumptask2 = nil
                        end
                    end
                end, 0.3)
            end
        end)
    end)
end


AddModRPCHandler("volleyball", "y_runjump", vollrunjump)

local function SendGrowGiantRPC()
    SendModRPCToServer(GetModRPC("volleyball", "y_runjump"))
end

GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_O, SendGrowGiantRPC)

-----------------新动作新写法---------------------------------
---
-----1 给打气筒加入打气
STRINGS.MYMOD_ACTION = {
    DAQI = "打气",
}

local function RepairFn(items, target)
    if target.components and target.components.finiteuses then
        target.components.finiteuses:SetPercent(target.components.finiteuses:GetPercent() + .5)
        if items.components.finiteuses then
            items.components.finiteuses:Use(30)
        end
    end
    return true
end

local actions = {
    {
        id = "DAQI ",                    --动作ID
        str = STRINGS.MYMOD_ACTION.DAQI,  --动作显示文字
        fn = function(act)
            if act.doer ~= nil and act.invobject ~= nil and act.target ~= nil and
                act.invobject:HasTag("yue_pump") and act.target:HasTag("y_volleyball") then
                return RepairFn(act.invobject, act.target) --动作执行函数:修复护甲耐久
            end
        end,
        state = "give", --绑定sg
        actiondata = {
            priority = 99,
            mount_valid = true,
        },
    },
}
--绑定组件
local component_actions = {
    {
        type = "USEITEM", --动作类型
        component = "inventoryitem",
        tests = {         --尝试显示
            {
                action = "DAQI ",
                testfn = function(inst, doer, target, actions, right)
                    return doer:HasTag("player") and inst:HasTag("yue_pump") and target:HasTag("y_volleyball") 
                end,
            },
        },
    },
}

for _, act in pairs(actions) do
    local addaction = AddAction(act.id, act.str, act.fn)
    if act.actiondata then
        for k, v in pairs(act.actiondata) do
            addaction[k] = v
        end
    end
    AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(addaction, act.state))
    AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(addaction, act.state))
end

for _, v in pairs(component_actions) do
    local testfn = function(...)
        local actions = GLOBAL.select(-2, ...)
        for _, data in pairs(v.tests) do
            if data and data.testfn and data.testfn(...) then
                data.action = string.upper(data.action)
                table.insert(actions, GLOBAL.ACTIONS[data.action])
            end
        end
    end
    AddComponentAction(v.type, v.component, testfn)
end
