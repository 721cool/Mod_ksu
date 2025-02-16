---@diagnostic disable: lowercase-global, undefined-global, trailing-space

GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

---@type string
local modid = 'tsukishima' -- 定义唯一modid

---@type LAN_TOOL_COORDS
C_TSUKISHIMA = require('core_'..modid..'/utils/coords')
---@type LAN_TOOL_SUGARS
S_TSUKISHIMA = require('core_'..modid..'/utils/sugar')

rawset(GLOBAL,'C_TSUKISHIMA',C_TSUKISHIMA)
rawset(GLOBAL,'S_TSUKISHIMA',S_TSUKISHIMA)


PrefabFiles = {
	
	"balls", "alpha_afterimage","pump","goatskin"
}

Assets = {

}
-- 导入常量表
modimport('scripts/core_'..modid..'/data/tuning.lua')

-- 导入工具
modimport('scripts/core_'..modid..'/utils/_register.lua')

-- 导入功能API
modimport('scripts/core_'..modid..'/api/_register.lua')

-- 导入mod配置
TUNING[string.upper('CONFIG_'..modid..'_LANG')] = GetModConfigData(modid..'_lang')

-- 导入语言文件
modimport('scripts/core_'..modid..'/languages/'..TUNING[string.upper('CONFIG_'..modid..'_LANG')]..'.lua')

-- 导入人物
modimport('scripts/data_avatar/data_avatar_tsukishima.lua')
--导入了我自己写的文件
modimport("scripts/util/recipes")
modimport("scripts/util/extrapower")
modimport("scripts/util/extraactions")
modimport("scripts/util/tsuki_fx")

-- 导入调用器
-- modimport('scripts/core_'..modid..'/callers/caller_attackperiod.lua')
-- modimport('scripts/core_'..modid..'/callers/caller_badge.lua')
-- modimport('scripts/core_'..modid..'/callers/caller_ca.lua')
-- modimport('scripts/core_'..modid..'/callers/caller_changeactionsg.lua')
-- modimport('scripts/core_'..modid..'/callers/caller_container.lua')
-- modimport('scripts/core_'..modid..'/callers/caller_dish.lua')
-- modimport('scripts/core_'..modid..'/callers/caller_keyhandler.lua')
-- modimport('scripts/core_'..modid..'/callers/caller_onlyusedby.lua')
 modimport('scripts/core_'..modid..'/callers/caller_recipes.lua')
-- modimport('scripts/core_'..modid..'/callers/caller_stack.lua')


-- 导入UI

-- 注册客机组件

-- 导入钩子