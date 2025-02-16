local vollproficiency = Class(function(self, inst)
    self.inst = inst
    self._vollpro = net_float(inst.GUID, "_vollpro")
end)
function vollproficiency:Setvollpro(vollpro)
    if self.inst.components.vollproficiency then
        vollpro = vollpro or 0
        self._vollpro:set(vollpro)

    end
end
function vollproficiency:Getvollpro()
    if self.inst.components.vollproficiency ~= nil then
        return self.inst.components.vollproficiency.vollpro
    else
        return self._vollpro:value()
    end
end
return vollproficiency
