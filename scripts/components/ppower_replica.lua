local ppower = Class(function(self, inst)
    self.inst = inst

    --官方的关于人物net的部分其实都放到了 player_classified.lua 里面 不过mod偷懒的话可以直接写 只是不太正规而已

    self.current_ppower = net_ushortint(inst.GUID, "ppower.current", "ppowerdirty") --第三个是事件名字 注意这个和界面监听的是同一个名字
    self.max_ppower = net_ushortint(inst.GUID, "ppower.max", "ppowerdirty")
    
    self.inst:DoTaskInTime(0, function()
        self.inst:ListenForEvent("ppowerdirty", function()
            self.inst:PushEvent("ppowerdelta", self:GetPercent())
        end)
        self.inst:PushEvent("ppowerdelta", self:GetPercent())
    end)

    self.current_ppower:set(100)
    self.max_ppower:set(100)
end)

function ppower:SetCurrent(current)
    if self.current_ppower ~= nil then
        self.current_ppower:set(current)
    end
end

function ppower:SetMax(max)
    if self.max_ppower ~= nil then
        self.max_ppower:set(max)
    end
end

function ppower:Max()
    if self.inst.components.ppower ~= nil then
        return self.inst.components.ppower.max
    elseif self.max_ppower ~= nil then
        return self.max_ppower:value()
    else
        return 100
    end
end

function ppower:GetPercent()
    if self.inst.components.ppower ~= nil then
        return self.inst.components.ppower:GetPercent()
    elseif self.current_ppower ~= nil and self.max_ppower ~= nil then
        return self.current_ppower:value() / self.max_ppower:value()
    else
        return 1
    end
end

--别的方法不想写了有需要的自己补充吧

return ppower