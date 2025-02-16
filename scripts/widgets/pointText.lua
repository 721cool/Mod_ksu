local Widget = require "widgets/widget"
local Text = require "widgets/text"
local pointText = Class(Widget, function(self, owner)
    self.owner = owner
    Widget._ctor(self, "pointText")
    self.newText = self:AddChild(Text(NUMBERFONT, 30, ""))
end)

function pointText:Onupdata(text)
    self.newText:SetString(text)
end

return pointText
