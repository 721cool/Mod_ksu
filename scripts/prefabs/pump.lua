local assets =
{
    Asset("ANIM", "anim/pump.zip"),
    Asset("ANIM", "anim/swap_pump.zip"),
    Asset("IMAGE", "images/inventoryimages/pump.tex"),
    Asset("ATLAS", "images/inventoryimages/pump.xml"),
}

local function onequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_object", skin_build, "swap_pump", inst.GUID, "pump")
    else
        owner.AnimState:OverrideSymbol("swap_object", "swap_pump", "pump")
    end
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    owner.AnimState:SetMultiSymbolExchange("swap_object", "hand")
end

local function onunequip(inst, owner)
    owner.AnimState:SetMultiSymbolExchange("hand", "swap_object")
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("pump")
    inst.AnimState:SetBuild("pump")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")
    inst:AddTag("pointy")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")
inst:AddTag("yue_pump")
    MakeInventoryFloatable(inst, "med", 0.05, { 1.1, 0.5, 1.1 }, true, -9)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(12)
    inst.components.weapon:SetRange(2.5)

    -------

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(1702)
    inst.components.finiteuses:SetUses(1702)

    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
     inst.components.inventoryitem.imagename = "pump"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/pump.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("pump", fn, assets)
