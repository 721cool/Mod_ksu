---@diagnostic disable: lowercase-global, undefined-global, trailing-space

local modid = 'tsukishima'

local data = _require('core_'..modid..'/data/recipes')
API.RECIPE:addRecipeFilter("BALLSHOP", "images/inventoryimages/filter.xml","filter.tex","排球小站")
API.RECIPE:main(data)