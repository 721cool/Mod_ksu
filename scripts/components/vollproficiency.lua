local function setprof(self, vollpro) self.inst.replica.vollproficiency:Setvollpro(vollpro) end


local vollproficiency = Class(function(self, inst)
    self.inst = inst
    self.vollpro = 0

    local function onpreload(inst, data)
        if data then
            if data.vollpro then
                self.vollpro = data.vollpro
            end
        end
    end

    local function onsave(inst, data)
        data.vollpro = self.vollpro
    end
    inst.OnSave = onsave
    inst.OnPreLoad = onpreload
    local function vollpro(inst, data)
        local weapon = data.weapon
        if not weapon then return end
        if weapon:HasTag("volleyshop")
        then
            if self.vollpro < 1000 then
                if inst.prefab == "esctemplate" then
                    self.vollpro = self.vollpro + 1.5
                else
                    self.vollpro = self.vollpro + 1
                end
            end

            if self.vollpro == 1000 then
                inst.components.talker:Say("接下来或许可以尝试报名CUVA了")
            end
            if self.vollpro < 10 and math.random(1, 4) < 4 then
                inst.components.health:DoDelta(-1.5)
            elseif self.vollpro < 50 and math.random(1, 4) < 2 then
                inst.components.health:DoDelta(-1)
            elseif self.vollpro < 420 and math.random(1, 8) < 8 then
                inst.components.health:DoDelta(-.5)
            end
            if not inst.prefab == "esctemplate" then
                if data.target.components.health.currenthealth <= 0 then
                    inst.components.locomotor.walkspeed = inst.components.locomotor.walkspeed + 0.5
                    inst.components.locomotor.runspeed = inst.components.locomotor.runspeed + 0.5
                    inst:DoTaskInTime(2.5, function()
                        inst.components.locomotor.walkspeed = inst.components.locomotor.walkspeed - 0.5
                        inst.components.locomotor.runspeed = inst.components.locomotor.runspeed - 0.5
                    end)
                else
                    inst.components.locomotor.walkspeed = inst.components.locomotor.walkspeed - 0.1
                    inst.components.locomotor.runspeed = inst.components.locomotor.runspeed - 0.1
                    inst:DoTaskInTime(2.5, function()
                        inst.components.locomotor.walkspeed = inst.components.locomotor.walkspeed + 0.1
                        inst.components.locomotor.runspeed = inst.components.locomotor.runspeed + 0.1
                    end)
                end
            end
        end
    end
    local function vollpro2(inst)
        if self.vollpro < 1000 then
            if inst.prefab == "esctemplate" then
                self.vollpro = self.vollpro + 1
            else
                self.vollpro = self.vollpro + 0.5
            end
        end
    end
    self.inst:ListenForEvent("onattackother", vollpro)
    self.inst:ListenForEvent("catch", vollpro2)
end, nil, { vollpro = setprof })
function vollproficiency:Setvollproficiency(amount)
    self.vollpro = amount
end

function vollproficiency:Getvollproficiency()
    return self.vollpro
end

return vollproficiency
