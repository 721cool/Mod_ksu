---@diagnostic disable: lowercase-global, undefined-global, trailing-space

local modid = 'tsukishima'

local data = _require('core_'..modid..'/data/badges')

API.BADGE:main(data)