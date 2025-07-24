-- shrimply delightful

local existingClasses = {}

class = {}

---@param classId string
---@param classArgs table
---@param classConstructor fun(table,...)|nil
---@return table
function class:New(classId, classArgs, classConstructor)
	classConstructor = classConstructor or (function() return {} end)

	if type(classId)~='string' or type(classArgs)~='table' then
		error('[Class] Missing arguments')
		return {}
	end

	local classContent
	if classArgs.__classID then
		classContent = classArgs
	else
		classContent = table.clone(classArgs)
		classContent.__classID = classId
	end

	local classInstance = {}
	classInstance.__parentID = classId

	---@return table
	function classInstance:Create(...)
		local instance = table.clone(classContent)

		if type(arg)=='table' then
			if type(arg[1])=='table' then
				for k,v in pairs(arg[1] --[[@as table]]) do instance[k]=v end
			else
				classConstructor(instance, unpack(arg))
			end
		end

		return instance
	end
	function classInstance:Inherit(childId, childContent, childConstructor)
		if type(childId)~='string' or type(childContent)~='table' then
			error('[Class/Inherit] Missing arguments')
			return
		end

		local inheritContent = table.clone(classContent)
		for k,v in pairs(childContent) do inheritContent[k]=v end
		inheritContent.__classId = childId

		return class:New(childId, inheritContent, childConstructor)
	end

	classInstance.__call = function(self,...) self:Create(unpack(arg)) end
	classInstance.__newindex = function(_,k,v) classContent[k]=v end

	setmetatable(classInstance, classInstance)
	existingClasses[ classId ] = classInstance
	return classInstance
end

class.__newindex = function() end
class.__index = function(_,k) return existingClasses[k] end
class.__call = function(self,...) self:New(unpack(arg)) end
setmetatable(class, class)

--[[
Usage:

local classCreator = class:New('parent', {}, function(self, value)
	self.value = value
end)
local classInstance1 = classCreator:Create(1) -- { value = 1 }
local classInstance2 = classCreator:Create(2) -- { value = 2 }
--]]
