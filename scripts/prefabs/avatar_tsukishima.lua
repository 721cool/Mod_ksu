local MakePlayerCharacter = require 'prefabs/player_common'

local avatar_name = 'tsukishima'
local assets = {
	Asset('SCRIPT', 'scripts/prefabs/player_common.lua'),
	Asset('ANIM', 'anim/'..avatar_name..'.zip'),
    Asset('ANIM', 'anim/ghost_' .. avatar_name .. '_build.zip'),
	Asset("SOUNDPACKAGE", "sound/kai.fev"), Asset("SOUND", "sound/kai.fsb")
}

local prefabs = {}

local start_inv = {}
-- for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
-- 	start_inv[string.lower(k)] = v[string.upper(avatar_name)]
-- end
start_inv['default'] = {}
for k,v in pairs(TUNING.TSUKISHIMA_CUSTOM_START_INV) do
	for i = 1, v.num do 
		table.insert(start_inv['default'], k)
	end
end

prefabs = FlattenTree({ prefabs, start_inv }, true)
---------------------------------------------------------------------------
---------------------------------------------------------------------------
local function onbecamehuman(inst, data, isloading)
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, avatar_name..'_speed_mod', 1)
end

local function onbecameghost(inst, data)
	inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, avatar_name..'_speed_mod')
end
---------------------------------------------------------------------------
---------------------------------------------------------------------------
local function onload(inst,data)
	inst:ListenForEvent('ms_respawnedfromghost', onbecamehuman)
	inst:ListenForEvent('ms_becameghost', onbecameghost)

	if inst:HasTag('playerghost') then
		onbecameghost(inst)
	else
		onbecamehuman(inst)
	end
end
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- 主/客机
local common_postinit = function(inst)
	inst:AddTag(avatar_name)
	inst:AddTag('volleyplayer')
    inst.MiniMapEntity:SetIcon(avatar_name .. '.tex')
    inst._pointnetvarred = net_smallbyte(inst.GUID, "pointred", "pcred")
	inst._pointnetvarblue = net_smallbyte(inst.GUID, "pointblue", "pcblue")
end
-- 主机

local master_postinit = function(inst)	
	inst.starting_inventory = start_inv[TheNet:GetServerGameMode()] or start_inv.default
	inst.talksoundoverride = 'kai/kai/voice1'
	
	inst.components.health:SetMaxHealth(TUNING[string.upper(avatar_name)..'_HEALTH'])
	inst.components.hunger:SetMax(TUNING[string.upper(avatar_name)..'_HUNGER'])
	inst.components.sanity:SetMax(TUNING[string.upper(avatar_name)..'_SANITY'])
	inst:AddTag("tsukishima")
	inst.components.foodaffinity:AddPrefabAffinity("baconeggs", TUNING.AFFINITY_15_CALORIES_HUGE)
	inst:AddComponent("TKextarAbility")
	inst.components.TKextarAbility:SetMoreFriends(inst)
    inst.components.TKextarAbility:Setobsord(inst)
    inst.components.TKextarAbility:MoonChange(inst)
	inst.components.TKextarAbility:SetRunJump(inst)

    inst:AddComponent("vollproficiency")
	--更低的攻击倍率，更低的饱食消耗速度,稍慢的移速
	inst.components.combat.damagemultiplier = TUNING.TSU_DAMAGEMUL
    inst.components.hunger.hungerrate = 0.75 * TUNING.WILSON_HUNGER_RATE
	inst.components.locomotor.runspeed = 5.5
	
	inst.OnLoad = onload
	inst.OnNewSpawn = onload
end
-- 人物皮肤
local function MakeTSUKISHIMASkin(name, data, notemp, free)
	local d = {}
	d.rarity = '典藏'
	d.rarityorder = 2
	d.raritycorlor = { 0 / 255, 255 / 255, 249 / 255, 1 }
	d.release_group = -1001
	d.skin_tags = { 'BASE', avatar_name, 'CHARACTER' }
	d.skins = {
		normal_skin = name,
		ghost_skin = 'ghost_'..avatar_name..'_build'
	}
	if not free then
		d.checkfn = TSUKISHIMA_API.TSUKISHIMASkinCheckFn
		d.checkclientfn = TSUKISHIMA_API.TSUKISHIMASkinCheckFn
	end
	d.share_bigportrait_name = avatar_name
	d.FrameSymbol = 'Reward'
	for k, v in pairs(data) do
		d[k] = v
	end
	TSUKISHIMA_API.MakeCharacterSkin(avatar_name, name, d)
	if not notemp then
		local d2 = shallowcopy(d)
		d2.rarity = '限时体验'
		d2.rarityorder = 80
		d2.raritycorlor = { 0.957, 0.769, 0.188, 1 }
		d2.FrameSymbol = 'heirloom'
		d2.name = data.name .. '(限时)'
		TSUKISHIMA_API.MakeCharacterSkin(avatar_name, name .. '_tmp', d2)
	end
end
function MakeTSUKISHIMAFreeSkin(name, data)
	MakeTSUKISHIMASkin(name, data, true, true)
end

MakeTSUKISHIMAFreeSkin(avatar_name..'_none', {
	name = '学生', -- 皮肤的名称
	des = '*...这是不是学校吧？', -- 皮肤界面的描述
	quotes = '\'经典套装\'', -- 选人界面的描述
	rarity = '典藏', -- 珍惜度 官方不存在的珍惜度则直接覆盖字符串
	rarityorder = 2, -- 珍惜度的排序 用于按优先级排序 基本没啥用
	raritycorlor = { 189 / 255, 73 / 255, 73 / 255, 1 }, -- {R,G,B,A}
	skins = { normal_skin = avatar_name, ghost_skin = 'ghost_'..avatar_name..'_build' },
	build_name_override = avatar_name,
    --share_bigportrait_name = avatar_name..'_none',
	share_bigportrait_name = avatar_name.."_none",
})


return MakePlayerCharacter(avatar_name, prefabs, assets, common_postinit, master_postinit, prefabs)