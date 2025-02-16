---@diagnostic disable: lowercase-global, undefined-global, trailing-space

---@class api_dish
local dst_lan = {}

---------------------------------------------------------------
-- 请参考下表来写/Please refer to the table below for writing --
---------------------------------------------------------------
-- local dishes = {} -- 键为料理名的料理定义表
-- dishes.dish_mymod_dish1 = {
--     test = function(cooker, names, tags) -- 料理的测试函数，条件进行数值比较前必须判空
--         -- @param cooker string 烹饪锅的prefab名
--         return ((names.potato and names.potato >= 2) and (tags.veggie and tags.veggie > 0) or
--                 ((names.potato or 0) + (names.potato_cooked or 0)) >= 2 and tags.veggie) and
--                 names.honey and not tags.meat
--     end,
--     weight = 10, -- 食谱权重
--     priority = 6, -- @Runar: 料理优先级，严格的测试函数配合设定合理的料理优先级才能铸就好的料理。无端99还条件简单的无疑是给自己和其他模组添麻烦
--     foodtype = FOODTYPE.VEGGIE, -- 食物类型
--     perishtime = 3, --腐烂时间/天
--     hunger = 1,
--     sanity = 1,
--     health = 1,
--     cooktime = 10, -- 烹饪时间/s
--     floater = {'med', nil, 0.55}, -- 设置料理漂浮水面的数据
--     potlevel = "low", -- 动画在烹饪锅的位置高低,建议一个mod中所有料理固定一个值
--     -- prefabs = {}, -- 该料理被注册为预制物之前需要先加载的预制物
--     -- tags = { "honeyed" }, -- 将被添加到预制物的tags
--     -- oneat_desc = "juice!", -- 烹饪指南中会显示的描述语
--     oneatenfn = function(inst, eater) -- 食用后执行的函数，在此实现buff
--         eater:AddDebuff("buff_electricattack", "buff_electricattack")
--     end,
--     card_def = {ingredient = {{ "potato", 2 }, { "honey", 2 }}}, -- 将生成对应的食谱卡
--     -- imagename = "honeyedpotato", -- 贴图,不写则用prefab名
--     -- atlasname = "images/inventoryimages/honeyedpotato.xml" -- 图集,不写则用inventoryimages
--     -- cookbook_tex = "honeyedpotato", -- 烹饪指南中显示的图片名,不写则用prefab名
--     -- cookbook_atlas = "images/cookbookimages/honeyedpotato.xml", -- 烹饪指南中显示的图片图集,不写则用inventoryimages

--     -- isMasterfood = true, -- 是否大厨料理
--     -- maxstacksize = 40, -- 最大堆叠数量
--     -- onperishreplacement = nil, -- 腐烂产物，默认为腐烂物
--     -- perishfn = nil, -- 腐烂时的回调函数

-- }
-- for k, v in pairs(dishes) do
--     v.name = k -- 设置料理名
--     v.basename = k -- 设置调味料理基础名
--     v.weight = v.weight or 1 -- 设置料理权重
--     v.priority = v.priority or 0 -- 设置料理优先级
--     v.perishtime = v.perishtime*480
--     v.cooktime = v.cooktime/40
--     v.potlevel = v.potlevel or 'low' -- 贴图相对位置 
--     v.overridebuild = v.overridebuild or k -- 设置料理锅上动画（贴图）所在的build压缩包（有时build名不一定为压缩包名）
--     v.floater = v.floater or { "small", .05, .7 } -- 设置料理漂浮数据
--     v.mod = true -- 确定为模组料理便于本模组内进行调味处理，换个名也可
--     v.cookbook_tex = v.cookbook_tex or k -- 烹饪指南tex名，不设置则为prefab名
--     v.cookbook_atlas = v.cookbook_atlas or ("images/inventoryimages/" .. k .. ".xml") -- 烹饪指南图集
--     -- v.cookbook_catogory = "mod" -- 料理在烹饪指南中所处的目录。后续定义中被确认为模组料理，写了大概率不生效
--     v.imagename = v.imagename or k -- 用于prefab中设置贴图名
--     v.atlasname = v.atlasname or ("images/inventoryimages/" .. k .. ".xml") -- 用于指定库存贴图图集
--     v.oneat_desc = v.oneat_desc or STRINGS.NAMES[string.upper(k)] or k -- 添加描述
-- end

---让prefab可以进烹煮锅
---@param names string[] prefab
---@param tags table<string, number> tags
---@param cancook any
---@param candry any
function dst_lan:AddIngredientValues(names,tags,cancook,candry)
    -- (names)<>[] 
    -- (tags)<>[] 
    -- (cancook)<>[] 
    -- (candry)<>[] 
    -- AddIngredientValues({'gears'}, {gears=1})
    AddIngredientValues(names,tags,cancook,candry)
end

---将所有料理添加到对应锅中
---@param tbl table data table
---@private
function dst_lan:addToPot(tbl)
    for _, v in pairs(tbl) do
        if not v.isMasterfood then
            -- 将非大厨料理添加到烹饪锅
            AddCookerRecipe("cookpot", v)
            AddCookerRecipe("archive_cookpot", v)
        end
        --将所有料理添加到便携锅
        AddCookerRecipe("portablecookpot", v)
        if v.card_def then
            -- 如果有食谱卡定义则生成对应的食谱卡，大厨料理食谱卡无法被解读
            AddRecipeCard("cookpot", v)
        end
    end
end

---添加调味
---@param tbl table data table
---@private
function dst_lan:spiced(tbl)
    GenerateSpicedFoods(tbl)
   -- 生成的调味料理定义在官方的表中，但是由于模组加载晚于游戏因此需要自行添加到调味站配方
    local spicedfoods = require("spicedfoods")
    for _, v in pairs(spicedfoods) do
        if v.mod == true and v.lan.nospiced then
            -- 设定模组料理为非官方料理
            v.official = false
            -- 将调味料理配方添加到便携式调味站
            AddCookerRecipe("portablespicer", v)
        end
    end
end

function dst_lan:main(tbl)
    self:addToPot(tbl)
    self:spiced(tbl)
end


return dst_lan