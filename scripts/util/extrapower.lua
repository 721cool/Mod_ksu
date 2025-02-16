--经验条（暂时废弃）
AddReplicableComponent("vollproficiency")
AddReplicableComponent("ppower")
AddPlayerPostInit(function(inst)
    if TheWorld.ismastersim then
        if not inst.components.vollproficiency then
            inst:AddComponent("vollproficiency")
        end
    end
end)
local protext = GLOBAL.require("widgets/showproficiency")
local function addprowidget(self, owner)
    self.protext = self:AddChild(protext(self.owner))
    self.protext:SetHAnchor(2)
    self.protext:SetVAnchor(1)

    self.protext:SetPosition(-50, -280, 0)

    local inst = GLOBAL.CreateEntity()
    if not inst.replica.vollproficiency then return end
    inst:DoPeriodicTask(1, function()
        local proficyency = owner.replica.vollproficiency:Getvollpro()
        local text = proficyency .. "/1000"
        self.protext:Onupdata(text)
    end)
end
AddClassPostConstruct("widgets/controls", addprowidget)
------------------------------经验条结束-----------------------------------------------------

----体力值---------------------------------------------------------
local assets = { Asset("ANIM", "anim/ppower.zip") }

for _, v in pairs(assets) do
    table.insert(Assets, v)
end
AddPlayerPostInit(function(inst)
    if TheWorld.ismastersim then
        inst:AddComponent("ppower")
        inst.components.ppower:SetMax(100)
        inst.components.ppower:daytask()
    end
end)

--界面部分
local ppowerBadge = require("widgets/ppower")
local function Add_ppower(self)
    self.ppower = self:AddChild(ppowerBadge(self.owner))

    self.owner:DoTaskInTime(0.5, function()
        local x1, y1, z1 = self.stomach:GetPosition():Get()
        local x2, y2, z2 = self.brain:GetPosition():Get()
        local x3, y3, z3 = self.heart:GetPosition():Get()
        if y2 == y1 or y2 == y3 then --开了三维mod
            self.ppower:SetPosition(self.stomach:GetPosition() + Vector3(x1 - x2, 0, 0))
        else
            self.ppower:SetPosition(self.stomach:GetPosition() + Vector3(x1 - x3, 0, 0))
        end
    end)


    --监听事件 刷新数据
    self.inst:ListenForEvent("ppowerdelta", function(inst, data)
        self.ppower:SetPercent(data, self.owner.replica.ppower:Max())
    end, self.owner)

    local old_SetGhostMode = self.SetGhostMode
    function self:SetGhostMode(ghostmode, ...)
        old_SetGhostMode(self, ghostmode, ...)
        if ghostmode then
            if self.ppower ~= nil then
                self.ppower:Hide()
            end
        else
            if self.ppower ~= nil then
                self.ppower:Show()
            end
        end
    end
end
AddClassPostConstruct("widgets/statusdisplays", Add_ppower)
---------------------------------体力值结束-------------------------
---------------------计分板部分--------------------------------------
local assets = { Asset("IMAGE", "images/inventoryimages/board.tex"),
    Asset("ATLAS", "images/inventoryimages/board.xml"), }

for _, v in pairs(assets) do
    table.insert(Assets, v)
end
local pointBoard = require("widgets/pointBoard")
local Text = require("widgets/text")
--比赛胜利将获得0.5的最大生命值,最多100点
local function Judicegame(point, inst)
    if point >= 25 then
        TheNet:Announce("比赛结束了！比分是" .. inst._pointnetvarred:value() .. " - " .. inst._pointnetvarblue:value())
        inst._pointnetvarblue:set(0)
        inst._pointnetvarred:set(0)
    end
end
local function Add_pointBoard(self)
    self.pointBoard = self:AddChild(pointBoard(self.owner))
    self.pointBoard.text1 = self.pointBoard:AddChild(Text(NUMBERFONT, 130, "0"))
    self.pointBoard.text2 = self.pointBoard:AddChild(Text(NUMBERFONT, 130, "0"))
    self.pointBoard.text1:SetHAlign(ANCHOR_LEFT)
    self.pointBoard.text2:SetHAlign(ANCHOR_LEFT)
    self.pointBoard:SetTexture("images/inventoryimages/board.xml", "board.tex")
    local w, h = 470, 179
    self.pointBoard:SetScale(0.25)
    local ws, hs = self.pointBoard:GetScaledSize()
    self.owner:DoTaskInTime(0.5, function()
        local x1, y1, z1 = self.stomach:GetPosition():Get()
        local x2, y2, z2 = self.brain:GetPosition():Get()
        local x3, y3, z3 = self.heart:GetPosition():Get()
        if y2 == y1 or y2 == y3 then --开了三维mod
            self.pointBoard:SetPosition(self.heart:GetPosition() - Vector3(20, 120, 0))
        else
            self.pointBoard:SetPosition(self.heart:GetPosition() - Vector3(20, 120, 0))
        end
    end)
    local x, y, z = self.pointBoard:GetPosition():Get()

    -- self.pointBoard.text1:SetPosition(x + 130, y, 0)
    -- self.pointBoard.text2:SetPosition(x - 130, y, 0)
    local k = 0.25
    local w1 = 365 * k
    local w2 = 130 * k
    WX = ws + 0.5 * w2
    self.pointBoard.text1:SetPosition(WX, hs * 0.3, 0)
    self.pointBoard.text2:SetPosition(-WX, hs * 0.3, 0)

--具体加分在ppower
    self.owner:ListenForEvent("pcblue", function()
        local point = self.owner._pointnetvarblue:value()
        self.pointBoard.text1:SetString(point)
        Judicegame(point, self.owner)
    end, self.owner)
    --人物被自己排球打到时红色加分
    self.owner:ListenForEvent("pcred", function()
        print("加一次分吧！")
        local point = self.owner._pointnetvarred:value()
        self.pointBoard.text2:SetString(point)
        Judicegame(point, self.owner)
    end, self.owner)
    -- self.inst:DoPeriodicTask(1, function()
    --     local text = self.inst._pointnetvarblue:value()
    --     self.pointBoard.text1:Onupdata(text)
    -- end)

    local old_SetGhostMode = self.SetGhostMode
    function self:SetGhostMode(ghostmode, ...)
        old_SetGhostMode(self, ghostmode, ...)
        if ghostmode then
            if self.pointBoard ~= nil then
                self.pointBoard:Hide()
            end
        else
            if self.pointBoard ~= nil then
                self.pointBoard:Show()
            end
        end
    end
end
AddClassPostConstruct("widgets/statusdisplays", Add_pointBoard)


------------------------------------计分板结束


--------------------------对部分生物的增伤-------------------
---对主动仇恨生物以及暗影的增伤
local ttags = { "hostile", "shadow" }
AddComponentPostInit("combat", function(self)
    if not TheWorld.ismastersim then return end
    local oldGetAttacked = self.GetAttacked
    self.GetAttacked = function(self, attacker, damage, weapon, stimuli, spdamage, ...)
        local dps = 1
        if weapon and weapon:HasTag("volleyball") and self.inst:HasOneOfTags(ttags) then
            dps = 1.25
        end

        if damage then
            damage = damage * dps
        end
        local spd = {}
        if spdamage ~= nil and next(spdamage) then
            for k, v in pairs(spdamage) do
                spd[k] = v * dps
            end
        else
            spd = nil
        end
        return oldGetAttacked(self, attacker, damage, weapon, stimuli, spd, ...)
    end
end)
-----------------------------对部分生物的增伤结束----------
---当人物被满血生物主动仇恨时获得buff（速度，回san)
---
AddComponentPostInit("combat", function(self)
    function self:SetTarget(target)
        if target ~= self.target and
            (target == nil or (self:IsValidTarget(target) and self:ShouldAggro(target))) and
            not (target and target.sg and target.sg:HasStateTag("hiding") and target:HasTag("player"))
        then
            self:DropTarget(target ~= nil)
            self:EngageTarget(target)
        end
        if not target then return end
        if self.inst.components.health and target:HasTag("tsukishima") then
            if self.inst.components.health:GetPercent() == 1 then
                target:PushEvent("AgainstViciousness", {})
                target.components.talker:Say("看样子有东西管不住自己的绳子")
            end
        end
    end
end)
--能力六：月灵(大小虚影)不会将月岛莹视作目标
local moonmonsters = { "gestalt", "gestalt_guard" }
for k, v in pairs(moonmonsters) do
    AddPrefabPostInit(v, function(inst)
        if not inst.components.combat then return end
        local Oldretarget = inst.components.combat.targetfn
        local function Retarget(inst, target)
            if target and target:HasTag("tsukishima") then
               target.components.talker:Say("他们看着我的眼神怎么有些暧昧？")  
                return nil
            end
            Oldretarget(inst)
        end
        inst.components.combat.targetfn = Retarget
    end)
end

---------------------------------------------------------------------------------------
