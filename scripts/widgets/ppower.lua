local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"

local ppower_Badge = Class(Badge, function(self, owner, art)
    Badge._ctor(self, "ppower", owner)
end)

function ppower_Badge:SetPercent(val, max)
    Badge.SetPercent(self, val, max)
end

return ppower_Badge
