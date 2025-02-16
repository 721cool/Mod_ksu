local function onmax(self, max)
    self.inst.replica.ppower:SetMax(max)
end

local function oncurrent(self, current)
    self.inst.replica.ppower:SetCurrent(current)
end


local ppower = Class(function(self, inst)
        self.inst = inst
        self.max = 100          --最大值
        self.current = self.max --当前值
        self.point = 0          --得分
        self.redpoints = 0
        self.mount = 2
        self.least = 8
        self.maxhealth = 100
    end,
    nil,
    {
        max = onmax,
        current = oncurrent,
    })

function ppower:OnSave() --保存
    return {
        current = self.current,
        point = self.point,
        max = self.maxhealth
    }
end

function ppower:OnLoad(data) --加载
    if data.current ~= nil then
        self.current = data.current
        self.maxhealth = data.max

        self:DoDelta(0)
    end
    if data.point ~= nil then self.point = data.point end
end

function ppower:setmount(mount)
    self.mount = mount
end

function ppower:SetMax(amount) --设置最大值
    self.max = amount
    self.current = amount
end

function ppower:DoDelta(delta) --改变的函数
    local old = self.current
    self.current = math.clamp(self.current + delta, 0, self.max)

    --其实改变的时候事件和需要传的参数都是随自己看需求写的
    self.inst:PushEvent("ppowerdelta", { oldpercent = old / self.max, newpercent = self.current / self.max })
    if self.current <= 30 then
        self.inst.components.hunger.hungerrate = 2 * TUNING.WILSON_HUNGER_RATE
        self.inst.components.ppower:setmount(2)
    end
end

function ppower:MoonAdd(bool)
    if bool then
        self.mount = 10
    else
        self.mount = 2
    end
end

function ppower:GetPercent() --获取百分比
    return self.current / self.max
end

function ppower:SetPercent(p) --设置百分比
    local old    = self.current
    self.current = p * self.max
    self.inst:PushEvent("ppowerdelta", { oldpercent = old / self.max, newpercent = p })
end

function ppower:Getpoint(mount, blue)
    if blue then
        self.point = self.point + mount
        if self.point >=25 then
            self.inst.components.sanity:DoDelta(25)
            self.point = 0
            local max = self.inst.maxhealth
            if max < 200 then
                self.inst.components.health:SetMax(max + 0.5)
            end
        end

        self.inst._pointnetvarblue:set(self.point)
        
    else
        self.redpoints = self.redpoints + mount
        self.inst._pointnetvarred:set(self.redpoints)
    end
end

function ppower:Getmultipul()
    local result = self.current / 50
    return math.floor(result * 10 + 0.5) / 10
end

--获取饥饿消耗速率
--体能的回复
--每秒恢复4点
--攻击时消耗5点体力，5秒内恢复降低至2点
--体力下降到30%s后，饥饿消耗速率提升到2（常态是0.75）持续4分钟，体力快速恢复30点
function ppower:lowerline()
    self.inst.lowerlinetask = self.inst:DoPeriodicTask(1, function()
        if self.current ~= self.max then
            self.inst.components.ppower:DoDelta(3)
        end
    end)
    self.inst:DoPeriodicTask(10, function()
        if self.inst.lowerlinetask ~= nil then
            self.inst.lowerlinetask:Cancel()
            self.inst.lowerlinetask = nil
        end
    end)

    if self.inst.setmounttask == nil then
        self.inst.components.hunger.hungerrate = 2 * TUNING.WILSON_HUNGER_RATE
        self.inst.setmounttask = self.inst:DoTaskInTime(240, function()
            self.inst.components.hunger.hungerrate = 0.75 * TUNING.WILSON_HUNGER_RATE
            self.inst.setmounttask = nil
        end)
    end
end

function ppower:daytask()
    local inst = self.inst
    -- --fx测试
    -- inst.willa_iceshield_fx = SpawnPrefab("willa_iceshield_fx").entity:SetParent(inst.entity)

    --得分监听
    inst:ListenForEvent("y_getpoint", function(data)
        local points = math.floor(math.random(1, 3))

        inst.components.ppower:Getpoint(points, true)
    end, inst)
    --失分监听
    inst:ListenForEvent("attacked", function(inst, data)
        local weapon = data.weapon
        if weapon and weapon:HasTag("y_volleyball") then
            print("打球了！")
            local points = math.random(2, 4)

            inst.components.ppower:Getpoint(points, false)
        end
    end)
    --体力在饥饿健康时增加
    inst.oppoweraddtask = inst:DoPeriodicTask(1, function()
        if self.current ~= self.max and self.inst.components.hunger.current > 10 then
            inst.components.ppower:DoDelta(self.mount)
        end
    end)
    --体力在触发跳跃时减少
    inst.oppattacktask = inst:ListenForEvent("opjump", function(data)
        local delta = data.delta or 4
        if delta then
            self.inst.components.ppower:DoDelta(-delta)
        end
        --跳跃后恢复体力暂时衰减
        if self.inst.cureattacktask == nil then
            self.mount = 1
            self.inst.cureattacktask = self.inst:DoTaskInTime(5, function()
                self.mount = 2
                self.inst.cureattacktask = nil
            end)
        end
    end, self.inst)
end

function ppower:GetActionLine(op)
    local line = self.least
    if op then line = op end
    if self.current >= line then
        return true
    else
        return false
    end
end

return ppower
