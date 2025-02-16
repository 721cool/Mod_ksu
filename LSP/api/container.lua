---@meta

---@class single_containerUI # 容器UI表
---@field widget container.widget
---@field type string # 容器类型,同类型容器只能打开一个
---| 'pack' # 背包
---| 'chest' # 箱子
---@field acceptsstacks nil|boolean # 是否接受堆叠物品,不填默认为true
---@field itemtestfn nil|fun(container, item, slot): boolean

---@class container.widget
---@field animbank string
---@field animbuild string 
---@field slotpos Vector3[] 
---@field slotbg atlasANDimage[]|table
---@field pos Vector3
---@field dragtype_drag string|nil # 设置拖拽,和widget名字保持一致
---@field unique string|nil # 唯一标识,用于花活
---@field buttoninfo container.widget.buttoninfo|nil

---@class container.widget.buttoninfo
---@field text string # 按钮文字
---@field position Vector3


---@class (exact) atlasANDimage
---@field atlas string
---@field image string


---@alias data_containerUI table<string, single_containerUI> # 自定义堆叠表