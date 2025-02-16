-- 皮肤API
rawset(GLOBAL, 'TSUKISHIMA_API', env)

local avatar_name = 'tsukishima'

local modid = 'tsukishima'

table.insert(PrefabFiles, 'avatar_'..avatar_name)

local assets_avatar = {
    Asset('ATLAS', 'images/saveslot_portraits/'..avatar_name..'.xml'),

	Asset('ATLAS', 'images/selectscreen_portraits/'..avatar_name..'.xml'),

	Asset('ATLAS', 'images/selectscreen_portraits/'..avatar_name..'_silho.xml'),

	Asset('ATLAS', 'bigportraits/'..avatar_name..'.xml'),

	Asset('ATLAS', 'images/map_icons/'..avatar_name..'.xml'),

	Asset('ATLAS', 'images/avatars/avatar_'..avatar_name..'.xml'),

	Asset('ATLAS', 'images/avatars/avatar_ghost_'..avatar_name..'.xml'),

	Asset('ATLAS', 'images/avatars/self_inspect_'..avatar_name..'.xml'),

	Asset('ATLAS', 'images/names_'..avatar_name..'.xml'),
	
    Asset('ATLAS', 'bigportraits/'..avatar_name..'_none.xml' ),
}

for _,v in pairs(assets_avatar) do
    table.insert(Assets, v)
end

--[[---注意事项
1. 目前官方自从熔炉之后人物的界面显示用的都是那个椭圆的图
2. 官方人物目前的图片跟名字是分开的 
3. 用打包工具生成好tex后
	bigportraits/xxx_none.xml 中 Element name 加上后缀 _oval
    images/names_xxx.xml 中 Element name 去掉前缀 names_
]]


modimport('scripts/api_skins/'..avatar_name..'_skins') -- 皮肤api
--基本变量
TUNING.TSU_DAMAGEMUL = 0.75
TUNING.TSU_MAXHEALTH = 100
TUNING.TSU_RUNSPEED = 5.5
-- 初始物品
TUNING.TSUKISHIMA_CUSTOM_START_INV = {
	['star'] = {
		num = 1, -- 数量
		moditem = true, -- 是否为mod物品
		 img = {atlas = 'images/inventoryimages/star.xml', image = 'star.tex'},
	},
	-- ['flint'] = {
	-- 	num = 3,
	-- 	moditem = false,
	-- },
}

TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT[string.upper(avatar_name)] = {}
for k,v in pairs(TUNING.TSUKISHIMA_CUSTOM_START_INV) do
	table.insert(TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT[string.upper(avatar_name)], k)
	if v.moditem then
		TUNING.STARTING_ITEM_IMAGE_OVERRIDE[k] = {
			atlas = v.img and v.img.atlas or "images/inventoryimages/"..k..".xml",
			image = v.img and v.img.image or k..".tex",
		}
	end
end


-- 角色注册
AddMinimapAtlas("images/map_icons/"..avatar_name..".xml")
AddModCharacter(avatar_name, "FEMALE") 

-- 三维
TUNING[string.upper(avatar_name)..'_HEALTH'] = 100
TUNING[string.upper(avatar_name)..'_HUNGER'] = 100
TUNING[string.upper(avatar_name)..'_SANITY'] = 200


local avatar_info = {
	['cn'] = {
		-- 选人界面的描述
		titles = "排球少年",
		names = "月岛莹",
		descriptions = "*双手熟练排球\n*不喜欢被招惹\n*“莹”的力量",
		quotes = "\'这里不是放学后该来的地方吧\'",
		survivability = "严峻",
		-- 描述
		myname = '月岛莹', -- 角色名
		others_desc_me = '有点冷淡的小哥', -- 其他人描述我
		me_desc_another_me = '%s,你是世界上的另一个我嘛?', -- 自己描述自己
	},
	['en'] = {
		-- select screen desc
		titles = "Sakura Swordswoman",
		names = "Niyu",
		descriptions = "*Light Yume\n*Raindrop",
		quotes = "\'Light Yume Raindrop\'",
		survivability = "Strong",
		-- desc
		myname = 'My name is', -- avatar name
		others_desc_me = 'You are a good character', -- other people describe me
		me_desc_another_me = '%s, are you another me?', -- describe another me
	},
}

STRINGS.CHARACTER_TITLES[avatar_name] = avatar_info[TUNING[string.upper('CONFIG_'..modid..'_LANG')]].titles
STRINGS.CHARACTER_NAMES[avatar_name] = avatar_info[TUNING[string.upper('CONFIG_'..modid..'_LANG')]].names
STRINGS.CHARACTER_DESCRIPTIONS[avatar_name] = avatar_info[TUNING[string.upper('CONFIG_'..modid..'_LANG')]].descriptions
STRINGS.CHARACTER_QUOTES[avatar_name] = avatar_info[TUNING[string.upper('CONFIG_'..modid..'_LANG')]].quotes
STRINGS.CHARACTER_SURVIVABILITY[avatar_name] = avatar_info[TUNING[string.upper('CONFIG_'..modid..'_LANG')]].survivability

if STRINGS.CHARACTERS.TSUKISHIMA == nil then
    STRINGS.CHARACTERS.TSUKISHIMA = {}
end

if STRINGS.CHARACTERS.TSUKISHIMA.DESCRIBE == nil then
    STRINGS.CHARACTERS.TSUKISHIMA.DESCRIBE = {}
end

STRINGS.NAMES.TSUKISHIMA = avatar_info[TUNING[string.upper('CONFIG_'..modid..'_LANG')]].myname
STRINGS.CHARACTERS.GENERIC.DESCRIBE.TSUKISHIMA = avatar_info[TUNING[string.upper('CONFIG_'..modid..'_LANG')]].others_desc_me
STRINGS.CHARACTERS.TSUKISHIMA.DESCRIBE.TSUKISHIMA = avatar_info[TUNING[string.upper('CONFIG_'..modid..'_LANG')]].me_desc_another_me