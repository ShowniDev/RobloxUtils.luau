-- read README for dependencies
-- read README for dependencies
-- read README for dependencies

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Destroyable = require(ReplicatedStorage.Shared.Libraries.Destroyable)
local Signal = require(ReplicatedStorage.Shared.Libraries.Signal)

--[=[
	@class Value
	@since 1.0.0
	@private

	Generic observable value object with utility methods for transformation,
	filtering, binding, and persistence.  
	Designed for use in Roblox with automatic cleanup via `Destroyable`.

	```lua
	local Value = require(path.to.Value)

	local health = Value.new(100)
	health:observe(function(newHealth)
		print("Health changed to", newHealth)
	end)

	health:set(90)
	```
]=]

export type Value<T> = Destroyable.Destroyable & {
	_value: T,
	_save: T?,
	_changed: Signal.Signal<T>,

	set: (self: Value<T>, newValue: T, forceSave: boolean?) -> (),
	get: (self: Value<T>) -> T,
	calculate: (self: Value<T>, AddOrSubstract: number) -> (),
	round: (self: Value<T>) -> (),
	filter: (self: Value<T>, predicate: (value: T) -> boolean) -> Value<T>,
	map: <U>(self: Value<T>, transformer: (value: T) -> U) -> Value<U>,
	save: (self: Value<T>) -> (),
	load: (self: Value<T>) -> T?,
	bind: (self: Value<T>, observableValue: Value<T>) -> RBXScriptConnection,
	unBind: (self: Value<T>) -> (),
	once: (self: Value<T>, fn: (value: T) -> ()) -> RBXScriptConnection,
	observe: (self: Value<T>, fn: (value: T) -> ()) -> RBXScriptConnection,
}

local Value = setmetatable({}, Destroyable)
Value.__index = Value

--[=[
	Creates a new Value instance.

	@param value T? -- The initial value. Tables are not allowed.
	@return Value<T>
]=]
function Value.new<T>(value: T?): Value<T>
	local self = setmetatable(Destroyable.new(), Value) :: Value<T>
	assert(typeof(value) ~= "table", `wrong type of {value}: {type(value)}`)

	self._value = value
	self._changed = Signal.new()

	self:GetTrove():Extend(self._changed)
	return self
end

--[=[
	Sets the value and fires the `Changed` signal if the value changes.
	If `forceSave` is true, the value is also saved to `_save`.

	@param newValue T -- The new value to set.
	@param forceSave boolean? -- Whether to save this value.
]=]
function Value.set<T>(self: Value<T>, newValue: T, forceSave: boolean?)
	if typeof(newValue) ~= typeof(self._value) then return end
	if newValue == self._value then return end
	
	self._value = newValue
	self._changed:Fire(newValue)

	if forceSave then
		self._save = newValue
	end
end

--[=[
	Returns the current value.

	@return T
]=]
function Value.get<T>(self: Value<T>): T
	return self._value
end

--[=[
	Adds or subtracts a number from the value, firing the `Changed` signal.

	@param AddOrSubstract number -- The number to add (or subtract if negative).
]=]
function Value.calculate<T>(self: Value<T>, AddOrSubstract: number)
	if typeof(self._value) ~= "number" then return end

	local newValue = self._value + AddOrSubstract
	self._value = newValue
	self._changed:Fire(newValue)
end

--[=[
	Rounds the numeric value down to the nearest integer and fires the `Changed` signal.
]=]
function Value.round<T>(self: Value<T>)
	if typeof(self._value) ~= "number" then return end
	local newValue = math.floor(self._value)
	self._changed:Fire(newValue)
end

--[=[
	Returns a new Value that only updates when the predicate returns true.

	@param predicate (value: T) -> boolean
	@return Value<T>
]=]
function Value.filter<T>(self: Value<T>, predicate: (value: T) -> boolean): Value<T>
	local observable = Value.new(self._value)
	self:observe(function(value)
		if predicate(value) then
			observable:set(value)
		end
	end)

	self:GetTrove():Add(observable)
	return observable
end

--[=[
	Transforms the value into a new type via the transformer function.

	@param transformer (value: T) -> U
	@return Value<U>
]=]
function Value.map<T, U>(self: Value<T>, transformer: (value: T) -> U): Value<U>
	local observable = Value.new(transformer(self._value))

	local connection = self:observe(function(value)
		observable:set(transformer(value))
	end)

	self:GetTrove():Add(connection)
	return observable
end

--[=[
	Saves the current value into `_save`.
]=]
function Value.save<T>(self: Value<T>)
	self._save = self._value
end

--[=[
	Loads the saved value from `_save`.

	@return T?
]=]
function Value.load<T>(self: Value<T>): T?
	if self._save then
		return self._save
	end
end

--[=[
	Binds this Value to another observable Value.  
	When the other Value changes, this one updates.

	@param observableValue Value<T>
	@return RBXScriptConnection
]=]
function Value.bind<T>(self: Value<T>, observableValue: Value<T>): RBXScriptConnection
	if self._connection then
		self._conn:Disconnect()
	end

	self._connection = observableValue:observe(function(value)
		self:set(value)
	end)

	self:GetTrove():Add(self._connection)
	return self._connection
end

--[=[
	Unbinds this Value from a previously bound Value.
]=]
function Value.unbind<T>(self:Value<T>)
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
end

--[=[
	Listens for the next change event, then disconnects automatically.

	@param fn (value: T) -> ()
	@return RBXScriptConnection
]=]
function Value.once<T>(self: Value<T>, fn: (value: T) -> ()): RBXScriptConnection
	local connection
	connection = self._changed:Connect(function(value)
		connection:Disconnect()
		fn(value)
	end)

	self:GetTrove():Add(connection)
	return connection
end

--[=[
	Listens for all change events.

	@param fn (value: T) -> ()
	@return RBXScriptConnection
]=]
function Value.observe<T>(self: Value<T>, fn: (value: T) -> ()): RBXScriptConnection
	local connection = self._changed:Connect(fn)
	self:GetTrove():Add(connection)
	return connection
end

return Value
