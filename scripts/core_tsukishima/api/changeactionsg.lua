-- @lan: _开头的方法是内部方法,一般来说不要在外部调用
---@diagnostic disable: lowercase-global, undefined-global, trailing-space

---@class api_changeactionsg
local dst_lan = {}

---@private
function dst_lan:_change_server(data_tbl)
    AddStategraphPostInit("wilson", function(sg)
        for _, v in ipairs(data_tbl) do
            local taraction = type(v.action) == "string" and rawget(GLOBAL.ACTIONS,string.upper(v.action)) or v.action
            local original_handler = sg.actionhandlers[taraction] and sg.actionhandlers[taraction].deststate
            local actionhandler = GLOBAL.ActionHandler(taraction, function(inst, action, ...)
                local doer = action.doer
                if v.testfn(doer) then
                    return v.sg
                end
                return original_handler and original_handler(inst, action, ...) or nil
            end)
            sg.actionhandlers[taraction] = actionhandler
        end
    end)
end

---@private
function dst_lan:_change_client(data_tbl)
    AddStategraphPostInit("wilson_client", function(sg)
        for _, v in ipairs(data_tbl) do
            local taraction = type(v.action) == "string" and rawget(GLOBAL.ACTIONS,string.upper(v.action)) or v.action
            local original_handler = sg.actionhandlers[taraction] and sg.actionhandlers[taraction].deststate
            local actionhandler = GLOBAL.ActionHandler(taraction, function(inst, action, ...)
                local doer = action.doer
                if v.testfn_client(doer) then
                    return v.sg
                end
                return original_handler and original_handler(inst, action, ...) or nil
            end)
            sg.actionhandlers[taraction] = actionhandler
        end
    end)
end

---修改action的sg
---@param data_tbl data_changeactionsg[]
function dst_lan:main(data_tbl)
    self:_change_server(data_tbl)
    self:_change_client(data_tbl)
end

return dst_lan