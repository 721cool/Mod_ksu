--[[
临时特效
- 使用方法：配置data表，modmain.lua用modimport引入该文件
- 对应科雷的fx.lua文件定义的特效，这类特效使用方便，功能简单，一般用于播放完就消失的没有实际效果的特效
- 主机没有AnimState，AnimState是在客机额外创建的对象，只有客机存在，对AnimState的操作可以通过配置或者fn进行额外的设置
- 有什么配置具体见prefabs/fx.lua的startfx函数，t变量就是配置里的数据
- 码师观点：用心的mod可能会使用大量的特效到处点缀，善用那些不起眼的小特效装饰自己的mod，这个文件配置特效也特别方便，换皮特效换色特效什么的再这里配置一下就行了

]]
local data = {
    {
        name = "fx_matrix_multcolor_spred",
        bank = "fx_matrix_multcolor_spred",
        build = "fx_matrix_multcolor_spred",
        anim = "idle",
        fn = function(inst) --对客机的动画实体追加的初始化
            inst.AnimState:SetFinalOffset(2)
            inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
--inst:RemoveEventCallback("animover", inst.Remove) --如果你想延迟一下再删除可以这样写，再自己决定什么时候删除
        end
        -- 更多配置见prefabs/fx.lua的startfx函数
    },
{
        name = "fx_boom_orange_real",
        bank = "fx_boom_orange_real",
        build = "fx_boom_orange_real",
        anim = "idle",
        fn = function(inst)
            inst.AnimState:SetFinalOffset(2)

           
        end
       
    },
{
        name = "fx_embers_fade_red",
        bank = "fx_embers_fade_red",
        build = "fx_embers_fade_red",
        anim = "idle",
        fn = function(inst)
            inst.AnimState:SetFinalOffset(2)

           
        end
       
    },
{
        name = "fx_vortex_purple",
        bank = "fx_vortex_purple",
        build = "fx_vortex_purple",
        anim = "idle",
        fn = function(inst)
            inst.AnimState:SetFinalOffset(2)

           
        end
       
    },

{
        name = "fx_righteye_blink",
        bank = "fx_righteye_blink",
        build = "fx_righteye_blink",
        anim = "idle",
        fn = function(inst)
            inst.AnimState:SetFinalOffset(2)

           
        end
       
    },
    {
        name = "star_fx",
        bank = "star_fx",
        build = "star_fx",
        anim = "idle1",
        fn = function(inst)
            inst.AnimState:SetFinalOffset(2)

           
        end
       
    },

}

local fx = require("fx")
for _, v in ipairs(data) do
    v.bank = v.bank or v.name
    v.build = v.build or v.name
    v.anim = v.anim or "idle"

    table.insert(Assets, Asset("ANIM", "anim/" .. v.build .. ".zip")) --没办法，动画需要自己导入

    table.insert(fx, v)
end
