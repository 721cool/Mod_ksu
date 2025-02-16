---@class LAN_TOOL_SUGARS
local tool = {
    EPSILON = 1e-7,
}

----------------------------------
-- GAME
----------------------------------

---实体是有效并存活的
---@param ent any
---@return boolean
---@nodiscard
function tool:checkAlive(ent)
    if ent and ent:IsValid() and ent.components.health and not ent.components.health:IsDead() then
        return true
    end
    return false
end

---卸下已装备的物品
---@param equipment any 欲卸下的装备
function tool:unequipItem(equipment)
    if equipment.components.equippable ~= nil and equipment.components.equippable:IsEquipped() then
        local owner = equipment.components.inventoryitem.owner
        if owner ~= nil and owner.components.inventory ~= nil then
            local item = owner.components.inventory:Unequip(equipment.components.equippable.equipslot)
            if item ~= nil then
                owner.components.inventory:GiveItem(item, nil, owner:GetPosition())
            end
        end
    end
end

---大概率能成功添加掉落物lootdrop的方法,这个方法是勾lootsetupfn的
---@param inst ent
---@param fn function 这里写添加lootdrop掉落物的逻辑
---@deprecated
function tool:addLootDropAlwaysSuccess(inst,fn)
    if not inst.components.lootdropper then
        inst:AddComponent('lootdropper')
    end
    local old_lootsetupfn = inst.components.lootdropper.lootsetupfn
    inst.components.lootdropper:SetLootSetupFn(function (...)
        local res = old_lootsetupfn ~= nil and {old_lootsetupfn(...)} or {}
        fn(...)
        return unpack(res)
    end)
end

---抛物品
---@param loot ent 预制物
---@param pt Vector3 坐标
function tool:flingItem(loot, pt)
    if loot ~= nil then
        loot.Transform:SetPosition(pt:Get())

        local min_speed = 0
        local max_speed = 2
        local y_speed = 8
        local y_speed_variance = 4

        if loot.Physics ~= nil then
            local angle = math.random() * TWOPI
            local speed = min_speed + math.random() * (max_speed - min_speed)

            local sinangle = math.sin(angle)
            local cosangle = math.cos(angle)
            loot.Physics:SetVel(speed * cosangle, GetRandomWithVariance(y_speed, y_speed_variance), speed * -sinangle)

            local radius = loot:GetPhysicsRadius(1)
            radius = radius * math.random()
            loot.Transform:SetPosition(pt.x + cosangle * radius,pt.y + 0.5,pt.z - sinangle * radius)
        end
    end
end

---消耗一个物品
---@param itm ent
function tool:consumeOneItem(itm)
    if itm and itm:IsValid() then
        if itm.components.stackable then
            itm.components.stackable:Get():Remove()
        else
            itm:Remove()
        end
    end
end

----------------------------------
-- OTHERS
----------------------------------


---闭包: 判断字符串是否不包含指定的所有字符串
---@param ... string 需要判断的字符串长参
---@return fun(string_needcheck:string):boolean
---@nodiscard
function tool:stringNotInclude(...)
    local arg = {...}
    return function (string_needcheck)
        for i,v in ipairs(arg) do
            if string.find(string_needcheck,v) then
                return false
            end
        end
        return true
    end
end

---查找并获取某个上值
---@param fn function
---@param target_name string
---@return any
---@nodiscard
function tool:upvalueFind(fn, target_name)
    local i = 1
    repeat
        local upvalue_name, upvalue_value = debug.getupvalue(fn, i)
        if upvalue_name == target_name then
            return upvalue_value
        end
        i = i + 1
    until not upvalue_name
    return nil
end

---简易装饰器
---@param parent any # 类
---@param field string # 需要勾的字段(方法名)
---@param before_fn nil|fun(self, ...) # 在原函数前执行
---@param after_fn nil|fun(self, ...) # 在原函数后执行
function tool:hookFn(parent,field,before_fn,after_fn)
    if after_fn == nil then
        local old_fn = parent[field]
        parent[field] = function (...)
            if before_fn ~= nil then
                before_fn(...)
            end
            return old_fn(...)
        end
        return
    end
    local old_fn = parent[field]
    parent[field] = function (...)
        if before_fn ~= nil then
            before_fn(...)
        end
        local res = old_fn ~= nil and {old_fn(...)} or {}
        after_fn(...)
        return unpack(res)
    end
end

---比较浮点数是否相等
---@param a number
---@param b number
---@return boolean
---@nodiscard
function tool:floatEqual(a,b)
    return math.abs(a - b) < self.EPSILON
end

---转义字符串中的特殊字符
local function escape_string(s)
    return string.gsub(s, '"', "\'")
end

---将表转换为字符串(递归打印,注意深度)
---@param t table # 需要转换的表
---@param depth nil|number # 递归深度(不填则无限大)
---@param indent nil|any # 缩进(nil就行)
---@return string # 转换后的字符串
---@nodiscard
function tool:table2string(t, depth, indent)
    -- 递归打印表
    local s = "{\n"
    indent = indent or "\t"
    depth = depth or math.huge  -- 默认深度为无穷大，表示一直递归

    local key_count = 0
    for k, v in pairs(t) do
        key_count = key_count + 1
        if depth <= 0 then
            s = s .. indent .. "[...] = \"...\",\n"
            break
        end

        local new_indent = indent .. "\t"
        local _fix_k = tonumber(k)
        local fix_k
        if _fix_k ~= nil and type(_fix_k) == "number" then
            fix_k = _fix_k
        else
            fix_k = "\"" .. escape_string(tostring(k)) .. "\""
        end

        s = s .. new_indent .. "[" .. fix_k .. "] = "  

        if type(v) == "table" then
            s = s .. self:table2string(v, depth - 1, new_indent)
        else
            s = s .. "\"" .. escape_string(tostring(v)) .. "\""
        end

        if key_count < #t then  
            s = s .. ",\n"
        else
            s = s .. "\n"
        end
    end
    s = s .. indent .. "}"
    return s
end

---将结果打印(宣告)在公屏上
---@param ... string # 需要打印的字符串
function tool:declare(...)
    local s = ''
    for i = 1, select('#', ...) do s = s .. tostring(select(i, ...)) .. ' ' end
    TheNet:Announce(s)
end

---保留几位小数
---@param round number # 保留几位
---@param ... number # 数字
---@return string ... # 结果
---@nodiscard
function tool:fnum(round,...)
    local res = {}
    for i = 1, select('#', ...) do res[i] = string.format('%.'..round..'f', select(i, ...)) end
    return unpack(res)
end


return tool