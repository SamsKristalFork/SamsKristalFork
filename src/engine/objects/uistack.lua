local UIStack, super = Class(Object)

function UIStack:init(master)
    self.master = master
    self.stack = {}
end

function UIStack:push(obj, activate_func, deactivate_func)
    for _,iobj in ipairs(self.stack) do
        iobj.object[iobj.deactivate]()
    end

    local entry = {object = obj, activate = activate_func, deactivate = deactivate_func}
    table.insert(self.stack, entry)

    entry.object[entry.activate]()
end

function UIStack:pop()
    local obj = table.remove(self.stack)
    obj.object[obj.deactivate]()
    
    local current = self:getCurrent()
    current.object[obj.activate]()
end

function UIStack:getCurrent()
    return self.stack[#self.stack]
end

function UIStack:clear()
    for _,iobj in ipairs(self.stack) do
        iobj.object[iobj.deactivate]()
    end
    self.stack = {}
end

function UIStack:onKeyPressed(key)
    if #self.stack > 0 then
        self:getCurrent():onKeyPressed(key)
    end

    if #self.stack > 1 then
        if Input.isCancel(key) then
            self:pop()
        end
    end
end

return UIStack