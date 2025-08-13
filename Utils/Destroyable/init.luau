-- read README for dependencies
-- read README for dependencies
-- read README for dependencies

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Shared.Libraries.Trove)

local Destroyable = {}
Destroyable.__index = Destroyable

export type Destroyable = {
	_trove: Trove.Trove,
	GetTrove: (self: Destroyable) -> Trove.Trove,
	Destroy: (self: Destroyable) -> (),
}

function Destroyable.new(): Destroyable
	local self = {
		_trove = Trove.new()
	}

	return setmetatable(self, Destroyable):: Destroyable
end

function Destroyable.GetTrove(self: Destroyable): Trove.Trove
	return self._trove
end

function Destroyable.Destroy(self: Destroyable)
	self._trove:Clean()
end

return Destroyable
