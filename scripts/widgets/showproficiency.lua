local Widget=require"widgets/widget"
local Text=require"widgets/text"
local vollproficiency=Class(Widget,function(self,owner)
    self.owner=owner
Widget._ctor(self,"vollproficiency")
self.newText=self:AddChild(Text(NUMBERFONT,30,""))
end)

function vollproficiency:Onupdata(text)
self.newText:SetString(text)
end
return vollproficiency

