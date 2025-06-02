-- PLS READ README.md FOR DEPENDENCIES !
-- PLS READ README.md FOR DEPENDENCIES !
-- PLS READ README.md FOR DEPENDENCIES !

--[=[
	Control library V4 by @Showni  
	A flexible input management module for Roblox, supporting key binding, toggle and loop actions.

	@class Control
	@tag Input
	@tag Utility

	Features:
	- Bind actions to keys or input types.
	- Supports toggle and looped actions.
	- Tracks last input pressed.
	- Easy action editing and unbinding.

	@field _Actions { [string]: Action } Internal action storage
	@field _LastKey EnumItem | string | nil Last pressed key or input
	@field _activeLoops { [EnumItem | string]: RBXScriptConnection } Active loop connections
	
	@type Action
	@field key EnumItem | string | Instance Key or input to bind
	@field loop boolean If true, runs onPress in a loop while key is pressed
	@field toggle boolean If true, toggles state on each press
	@field onPress function Callback when key is pressed
	@field onRelease function Callback when key is released or toggled off
	@field state boolean Current toggle state
	@field active boolean Whether the action is active
]=]

local ServerScriptService = game:GetService("ServerScriptService")
local Uis = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Destroyable = require(ReplicatedStorage.Shared.Libraries.Destroyable)
local i = require(ReplicatedStorage.Shared.Libraries.i)

local NULL = function() end

local Control = setmetatable({}, Destroyable)
Control.__index = Control

type Action = {
	key: EnumItem | string,
	loop: boolean,
	toggle: boolean,
	onPress: () -> (),
	onRelease: () -> (),
	state: boolean,
	active: boolean,
}

export type Control = Destroyable.Destroyable & {
	_Actions: { [string]: Action },
	_LastKey: EnumItem | string | nil,
	_activeLoops: { [EnumItem | string]: RBXScriptConnection },

	_Convert: (self: Control, key: string) -> (EnumItem | string | nil),
	_Loop: (self: Control, callback: () -> ()) -> (RBXScriptConnection),

	Start: (self: Control) -> (),
	Bind: (self: Control, options: Action) -> (),
	Unbind: (self: Control, actionName: string) -> (),
	Edit: (self: Control, action: string, newKey: string) -> (),
	GetLastKey: (self: Control) -> (EnumItem | string | nil),
	GetActions: (self: Control) -> ({ [string]: Action }),
}

local OptionsInterface = {
	name = "string",
	key = {"EnumItem", "string", "Instance"},
	loop = i.opt("boolean", false),
	toggle = i.opt("boolean", false),
	onPress = i.opt("function", NULL),
	onRelease = i.opt("function", NULL),
}

--[[
	Creates a new Control instance.

	@return Control A new Control instance.
]=]
function Control.new(): Control
	local self = setmetatable(Destroyable.new(), Control) :: Control
	self._Actions = {}
	self._LastKey = nil
	self._activeLoops = {}
	return self
end

--[[
	Converts a string or input object to an EnumItem or string key.

	@param key string | EnumItem | Instance Input to convert.
	@return EnumItem | string | nil Converted key or nil if invalid.
]]
function Control._Convert(self: Control, key: string): EnumItem | string | nil
	if typeof(key) == "string" then
		return Enum.KeyCode[key] or Enum.UserInputType[key] or key
	end

	if typeof(key) == "EnumItem" then
		return key
	end

	if typeof(key) == "Instance" and key:IsA("InputObject") then
		return key.KeyCode ~= Enum.KeyCode.Unknown and key.KeyCode or key.UserInputType
	end
end

--[[
	Helper function to start a loop callback bound to RenderStepped.

	@param callback function Callback to execute every frame.
	@return RBXScriptConnection Connection to RenderStepped.
]]
function Control._Loop(self: Control, callback: () -> ()): RBXScriptConnection
	return RunService.RenderStepped:Connect(callback)
end

--[[
	Starts listening to user input and triggers bound actions accordingly.

	@void
]]
function Control:Start()
	local began = Uis.InputBegan:Connect(function(input, gp)
		if gp then return end
		local key = self:_Convert(input)
		self._LastKey = key
		for _, action in self._Actions do
			if self:_Convert(action.key) ~= key then continue end
			if action.loop and action.toggle then return end

			if action.loop then
				self._activeLoops[key] = self:_Loop(action.onPress)
				continue
			end

			if action.toggle then
				action.state = not action.state
				(action.state and action.onPress or action.onRelease)()
				continue
			end

			if action.onPress then
				action.onPress()
			end
		end
	end)

	local ended = Uis.InputEnded:Connect(function(input, gp)
		if gp then return end
		local key = self:_Convert(input)
		for _, action in self._Actions do
			if self:_Convert(action.key) ~= key then continue end

			if action.loop then
				local loopConnection = self._activeLoops[key]

				if loopConnection then
					loopConnection:Disconnect()
					self._activeLoops[key] = nil
				end
				continue
			end

			if not action.toggle and action.onRelease then
				action.onRelease()
			end
		end
	end)

	self:GetTrove():Add(began)
	self:GetTrove():Add(ended)
end

--[[
	Binds a new action to a key or input.

	@param options Action Table describing the action to bind:
		- name string: Unique identifier for the action (required)
		- key EnumItem | string | Instance: The input key or type to bind (required)
		- loop boolean: If true, onPress is called repeatedly while key is held (default false)
		- toggle boolean: If true, toggles the action state on key press (default false)
		- onPress function: Callback called when key is pressed (default no-op)
		- onRelease function: Callback called when key is released (default no-op)

	@void
]]
function Control:Bind(options: Action)
	local success, err = pcall(function()
		i.soft(OptionsInterface, options)
	end)

	if not success then warn(err) end

	self._Actions[options.name] = {
		key = options.key,
		loop = options.loop,
		toggle = options.toggle,
		onPress = options.onPress,
		onRelease = options.onRelease,

		state = false,
		active = true,
	}
end

--[[
	Unbinds an action by name.

	@param actionName string Name of the action to unbind.

	@void
]]
function Control:UnBind(actionName: string)
	self._Actions[actionName] = nil
end

--[[
	Edits the key binding of an existing action.

	@param action string Name of the action to edit.
	@param newKey string New key or input to bind.

	@void
	@throws If action name does not exist.
]]
function Control:Edit(action: string, newKey: string)
	assert(self._Actions[action], `Action "{action}" not found.`)
	self._Actions[action].key = newKey
end

--[[
	Returns the last pressed key or input.

	@return EnumItem | string | nil Last pressed key or nil if none.
]]
function Control:GetLastKey(): EnumItem | string | nil
	return self._LastKey
end

--[[
	Returns the table of all bound actions.

	@return { [string]: Action } The actions currently bound.
]]
function Control:GetActions(): { [string]: Action }
	return self._Actions
end

return Control
