
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
local assets = {
    Asset("ANIM", "anim/tsukishima.zip"),
}
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
local prefabs = {}
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
local SimpleSwapName = {
    "backpack",
    "swap_body",
    "swap_hat",
    "headbase_hat",
    -- "backpack",
    -- "backpack",
    -- "backpack",
}
local function CopyAppearance(inst, target)
    if target ~= nil and target:IsValid() then
        if inst.components.skinner ~= nil and target.components.skinner ~= nil then
            inst.components.skinner:CopySkinsFromPlayer(target)
        end
        local swap_object_build, swap_object_sym = target.AnimState:GetSymbolOverride("swap_object")
        if swap_object_build ~= nil and swap_object_sym ~= nil then
            inst.AnimState:OverrideSymbol("swap_object", swap_object_build, swap_object_sym)
            inst.AnimState:Show("ARM_carry")
            inst.AnimState:Hide("ARM_normal")
        end
        for _, name in ipairs(SimpleSwapName) do
            local swap_build, swap_sym = target.AnimState:GetSymbolOverride(name)
            if swap_build ~= nil and swap_sym ~= nil then
                inst.AnimState:OverrideSymbol(name, swap_build, swap_sym)
            end
        end
    end
end

local function Init(inst, target)
    if target ~= nil and target:IsValid() and target.components.skinner ~= nil then
        local x, y, z = target.Transform:GetWorldPosition()
        local angle = target.Transform:GetRotation()
        inst.Transform:SetPosition(x, y, z)
        inst.Transform:SetRotation(angle)

        local bank
        local anim
        local DebugString = target.entity:GetDebugString() or " "
        anim = string.match(DebugString, "%sanim:%s([%w%d_]+)")
        if anim == nil then
            bank, anim = target.AnimState:GetHistoryData()
        end
        local frame = target.AnimState:GetCurrentAnimationFrame()
        inst.AnimState:PlayAnimation(anim)
        inst.AnimState:SetFrame(frame)
        inst.AnimState:Pause()
    end
end
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("tsukishima")
    inst.AnimState:SetSortOrder(0)
    -- inst.AnimState:SetErosionParams(0, 0, 0)
    inst.AnimState:SetMultColour(0, 0, 0, 1)

    inst.AnimState:Hide("ARM_carry")
    inst.AnimState:Hide("HAT")
    inst.AnimState:Hide("HAIR_HAT")

    inst:AddTag("NOBLOCK")
    inst:AddTag("NOCLICK")
    inst:AddTag("alpha_timestop_immune")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("skinner")
    inst.components.skinner:SetupNonPlayerData()

    inst:DoPeriodicTask(0, function()
        inst.percent = (inst.percent or 1) - 0.05
        if inst.percent >= 0 then
            inst.AnimState:SetMultColour(0, 0, 0, inst.percent)
        else
            inst:Remove()
        end
    end)

    inst.CopyAppearance = CopyAppearance
    inst.Init = Init

    inst.persists = false

    return inst
end
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
return Prefab("alpha_afterimage", fn, assets, prefabs)
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------