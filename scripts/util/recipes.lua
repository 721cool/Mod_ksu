
local item_strings = {
    STAR = {
        NAME = "世达",
        DESCRIBE = "这颗星星好圆",
        RECIPE_DESC = "户外才是见证实力的地方"
    },
    MIKASA = {
        NAME = "米卡萨",
        DESCRIBE = "圆圆的黄金",
        RECIPE_DESC = "快乐源泉"
    },
    MOTENG = {
        NAME = "魔腾",
        DESCRIBE = "红配绿，青又白",
        RECIPE_DESC = "zxy的最爱"
    },
    
   PUMP = {
        NAME = "打气筒",
        DESCRIBE = "奇怪的厂家，奇怪的尺寸",
        RECIPE_DESC = "妈妈再也不用担心打气打得慢了！"
    },
    OBALL = {
        NAME = "入门球",
        DESCRIBE = "很普通的一颗球",
        RECIPE_DESC = "这到底是什么牌子？"
    },
    GOATSKIN = {
        NAME = "羊皮",
        DESCRIBE = "古老的技术，传统的艺术",
       RECIPE_DESC = ""
},
}
for item, strings in pairs(item_strings) do
    STRINGS.NAMES[item] = strings.NAME
    STRINGS.CHARACTERS.GENERIC.DESCRIBE[item] = strings.DESCRIBE
    STRINGS.RECIPE_DESC[item] = strings.RECIPE_DESC
end
--prefab资源导入
local prefab_photo = {
     Asset("ATLAS", "images/inventoryimages/filter.xml"),
    Asset("IMAGE", "images/inventoryimages/filter.tex"),  
}

for _, v in pairs(prefab_photo) do
    table.insert(Assets, v)
end
-----------关于羊皮的额外掉落
AddPrefabPostInit("lightninggoat", function(inst)
    if inst.components.lootdropper ~= nil then
        inst.components.lootdropper:AddChanceLoot("goatskin", 0.5)
    end
end)
