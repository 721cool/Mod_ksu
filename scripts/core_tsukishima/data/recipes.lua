---@diagnostic disable: lowercase-global, undefined-global, trailing-space

---@type data_recipe[]
local function Injectatlas(ingredients, amount)
	local atlas = "images/inventoryimages/" .. ingredients .. ".xml"
	return Ingredient(ingredients, amount, atlas)
end
local data = {
	{
		recipe_name = 'star', --食谱ID
		ingredients = { --配方

			Injectatlas("goatskin", 1),
			Ingredient('silk', 6),
			Ingredient('moonrocknugget', 1),
			Ingredient('featherpencil', 1),
		},
		tech = TECH.SCIENCE_ONE, --所需科技 ,TECH.LOST 表示需要蓝图才能解锁
		isOriginalItem = false, --是官方物品(官方物品严禁写atlas和image路径,因为是自动获取的),不写则为自定义物品
		config = {
			-- --其他的一些配置,可不写
			-- --制作出来的物品,不写则默认制作出来的预制物为食谱ID
			-- product = 'choleknife',
			-- --xml路径,不写则默认路径为,'images/inventoryimages/'..product..'.xml' 或 'images/inventoryimages/'..recipe_name..'.xml'
			-- atlas = 'images/choleknife.xml',
			-- --图片名称,不写则默认名称为 product..'.tex' 或 recipe_name..'.tex'
			-- image = 'choleknife.tex',
			-- --制作出的物品数量,不写则为1
			-- numtogive = 40,
			-- --不需要解锁
			-- nounlock = false,
		},
		filters = { 'BALLSHOP' } --将物品添加到这些分类中
	}, {
	recipe_name = 'moteng', --食谱ID
	ingredients = {        --配方

		Injectatlas("goatskin", 1),
		Ingredient('silk', 6),
		Ingredient('tentaclespots', 1),
		Ingredient('greengem', 1),
	},
	tech = TECH.SCIENCE_ONE, --所需科技 ,TECH.LOST 表示需要蓝图才能解锁
	isOriginalItem = false, --是官方物品(官方物品严禁写atlas和image路径,因为是自动获取的),不写则为自定义物品
	config = {},
	filters = { 'BALLSHOP' } --将物品添加到这些分类中
}, {
	recipe_name = 'mikasa', --食谱ID
	ingredients = {       --配方
		Ingredient('goldnugget', 10),
		Injectatlas("goatskin", 1),
		Ingredient('silk', 6),
		Ingredient('feather_canary', 2),
		Ingredient('transistor', 2),
	},
	tech = TECH.SCIENCE_ONE, --所需科技 ,TECH.LOST 表示需要蓝图才能解锁
	isOriginalItem = false, --是官方物品(官方物品严禁写atlas和image路径,因为是自动获取的),不写则为自定义物品
	config = {},
	filters = { 'BALLSHOP' } --将物品添加到这些分类中
}, {
	recipe_name = 'pump', --食谱ID
	ingredients = {       --配方


		Ingredient('goldnugget', 6),
		Ingredient('mosquito', 1),
		Ingredient('orangegem', 1),
		Ingredient('yellowgem', 2),
		Ingredient('greengem', 1),

	},
	tech = TECH.SCIENCE_ONE, --所需科技 ,TECH.LOST 表示需要蓝图才能解锁
	isOriginalItem = false, --是官方物品(官方物品严禁写atlas和image路径,因为是自动获取的),不写则为自定义物品
	config = {},
	filters = { 'BALLSHOP' } --将物品添加到这些分类中
}, {
	recipe_name = 'oball', --食谱ID
	ingredients = {       --配方
		Ingredient('pigskin', 1),
		Ingredient('silk', 3),
		Ingredient('cutgrass', 3),
	},
	tech = TECH.SCIENCE_ONE, --所需科技 ,TECH.LOST 表示需要蓝图才能解锁
	isOriginalItem = false, --是官方物品(官方物品严禁写atlas和image路径,因为是自动获取的),不写则为自定义物品
	config = {},
	filters = { 'BALLSHOP' } --将物品添加到这些分类中
},
}


return data
