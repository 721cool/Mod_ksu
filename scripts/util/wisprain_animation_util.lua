local tools = {}

-- 获取当前动画名
function tools:getcurrentanim(inst)
    if inst == nil then return end
	local a, b, c, d, e, f = inst.AnimState:GetHistoryData()
	return b
end

return tools 