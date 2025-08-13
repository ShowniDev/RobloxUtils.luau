local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Uis = game:GetService("UserInputService")

local Destroyable = require(ReplicatedStorage.Shared.Libraries.Destroyable)
local Signal = require(ReplicatedStorage.Shared.Libraries.Signal)

local NULL = function() end

--[=[
	@class Control
	@since 1.0.0

	An input handling module that maps keys or combinations to named actions.
	Supports looped, toggled, and normal actions, as well as rebinding.

	```lua
	local Control = require(path.to.Control)

	local controls = Control.new(player)
	controls:Bind({
		name = "Jump",
		key = Enum.KeyCode.Space,
		loop = false,
		toggle = false,
		onPress = function()
			print("Jump pressed")
		end,
		onRelease = function()
			print("Jump released")
		end,
	})

	controls:Start()
	```
]=]

local Control = setmetatable({}, Destroyable)
Control.__index = Control

type Key = EnumItem | string
type Action = {
	name: string,
	key: Key,
	loop: boolean,
	toggle: boolean,
	onPress: () -> (),
	onRelease: () -> (),
}

export type Control = Destroyable.Destroyable & {
	_actions: { [string]: Action },
	_loopConnections: { [EnumItem | string]: RBXScriptConnection },
	_helds: {[string]: Key | {Key}},
	_signal: Signal.Signal,

	_findActionByKey: (self: Control, key: Key) -> Action?,

	Start: (self: Control) -> (),
	Stop: (self: Control) -> (),
	Bind: (self: Control, options: Action) -> (),
	Unbind: (self: Control, actionName: string) -> (),
	Edit: (self: Control, action: string, newKey: string) -> (),
	IsPressed: (self: Control, action: string) -> boolean,
	GetAction: (self: Control, name: string) -> { Action },
}

--[=[
	Converts various key representations into Enum items.
	Accepts Enum.KeyCode, Enum.UserInputType, InputObject, or string.
	@private
]=]
local function _convert(key: Key): Key | nil
	if typeof(key) == "string" then
		if Enum.KeyCode[key] then
			return Enum.KeyCode[key]
		elseif Enum.UserInputType[key] then
			return Enum.UserInputType[key]
		end
		return error(`{key} is invalid key`)

	elseif typeof(key) == "EnumItem" then
		return key
	elseif typeof(key) == "Instance" and key:IsA("InputObject") then
		return key.KeyCode ~= Enum.KeyCode.Unknown and key.KeyCode or key.UserInputType
	end
end

--[=[
	Checks if a key or key sequence is valid.
	@private
]=]
local function _isValidKey(key: Key | {Key}): boolean
	if typeof(key) == "table" then
		for _, subKey in key do
			if not _convert(subKey) then
				return false
			end
		end
		return true
	else
		return _convert(key) ~= nil
	end
end

--[=[
	Creates a new Control object.

	@param player Player -- The player this control set belongs to.
	@param autoStartDebug boolean? -- Whether to automatically start listening.
	@return Control
]=]
function Control.new(player: Player, autoStartDebug: boolean?): Control
	local self = setmetatable(Destroyable.new(), Control) :: Control<T>

	self:GetTrove():AttachToInstance(player)

	self._actions = {}
	self._loopConnections = {}
	self._helds = {}
	self._signal = Signal.new()

	self:GetTrove():Add(RunService.Heartbeat:Connect(function(dt)
		if self._signal and self._signal.Fire then
			self._signal:Fire(dt)
		end
	end))

	if autoStartDebu
