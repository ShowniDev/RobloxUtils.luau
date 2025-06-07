--[[
I library by @Showni
	ENJOY !
]]

export type InterfaceType<T> = { [string]: T }

local I = {} -- ==> I for Interface
I.Instances = setmetatable({}, {__mode = "v"})

--[=[
	@interface InterfaceType<T>
	@within I
	Represents an interface type used to define the expected structure of a table.
]=]

--[=[
	@function _check
	@within I
	@private
	@param value any -- The value to check.
	@param expected {string} -- The list of expected types.
	@return boolean -- Whether the value matches one of the expected types.
]=]
local function _check(value: any, expected: {string}): boolean
	for _, types in expected do
		if types == "nil" and value == nil then
			return true
		elseif typeof(value) == types then
			return true
		end
	end
	return false
end

--[=[
	@function _handleError
	@within I
	@private
	@param key string -- The key of the interface entry.
	@param errMessage string -- The associated error message.
	@return string -- A formatted error string.
]=]
local function _handleError(key: string, errMessage: string): string
	return `failed "{tostring(key)}": {errMessage}`
end

--[=[
	@function opt
	@within I
	Marks a key in the interface as optional with a default value.

	@param expectedType string | {string} -- The expected type(s) of the optional key.
	@param defaultValue any -- The default value to use if the key is missing.
	@return table -- A descriptor for the optional key.
]=]
function I.opt(expectedType: string | { string }, defaultValue: any): {}
	if type(expectedType) == "string" then
		expectedType = { expectedType }
	end

	return {
		_isOptional = true,
		expectedType = expectedType,
		default = defaultValue,
	}
end

--[=[
	@function nest
	@within I
	Creates a nested interface definition.

	@param interface InterfaceType<any> -- The nested interface.
	@return table -- A descriptor for the nested interface.
]=]
function I.nest(interface: InterfaceType<any>)
	assert(type(interface) == "table", "I.nest: expected a table as argument.")
	return {
		_isNested = true,
		interface = interface
	}
end

--[=[
	@function strict
	@within I
	Validates a table against a defined interface. Errors on any mismatch.

	@param interface InterfaceType<any> -- The expected interface definition.
	@param newTable InterfaceType<any> -- The actual table to validate.
	@return InterfaceType<any> -- The validated and possibly completed table.
	@throws If any required key is missing or if any type mismatches are found.
]=]
function I.strict(interface: InterfaceType<any>, newTable: InterfaceType<any>): {}
	for key, value in interface do
		local tableValue = newTable[key]
		local actualType = typeof(tableValue)
		local isValid = false
		local isOptional = type(value) == "table" and value._isOptional	

		assert(isOptional or newTable[key] ~= nil, `Missing required key "{key}" in newTable`)

		if type(value) == "table" then
			if value._isOptional then
				assert(type(value.expectedType) == "table", `expectedType should be a table in optional field "{key}"`)

				if tableValue == nil and value.default ~= nil then
					newTable[key] = value.default
					tableValue = newTable[key]
					actualType = typeof(tableValue)
					isValid = true
				elseif tableValue == nil and value.default == nil then
					isValid = true
				else
					isValid = _check(tableValue, value.expectedType)
				end

			elseif value._isNested then
				assert(type(tableValue) == "table", `key "{key}" expected nested table, got {actualType}`)
				I.strict(value.interface, tableValue)
				isValid = true

			else
				for _, expectedType in value do
					if actualType == expectedType then
						isValid = true
						break
					end
				end
			end

			assert(isValid, `key "{key}" failed, got "{actualType}")`)

		else
			assert(type(value) == "string", `expected type string for key "{key}", got "{type(value)}"`)
			assert(actualType == value, `key "{key}" expected "{value}", got "{actualType}"`)
		end
	end

	for key in newTable do
		assert(interface[key] ~= nil, `unknown key "{key}" found in newTable`)
	end

	table.insert(I.Instances, newTable)
	return newTable
end

--[=[
	@function _softVerification
	@within I
	@private
	Validates a table against an interface but returns a boolean instead of throwing.

	@param interface InterfaceType<any>
	@param newTable InterfaceType<any>
	@return boolean, string? -- Whether the table is valid and an optional error message.
]=]
local function _softVerification(interface: InterfaceType<any>, newTable: InterfaceType<any>)
	for key, value in interface do
		local tableValue = newTable[key]
		local actualType = typeof(tableValue)
		local isValid = false
		local isOptional = type(value) == "table" and value._isOptional	

		if not isOptional and newTable[key] == nil then
			return false, _handleError(key, "missing required key")
		end

		if type(value) == "table" then
			if value._isOptional then
				if tableValue == nil and value.default ~= nil then
					continue -- skip
				elseif tableValue == nil and value.default == nil then
					-- skip
				elseif not _check(tableValue, value.expectedType) then
					return false, _handleError(key, `expected types {table.concat(value.expectedType, ", ")}, got {actualType}`)
				end

			elseif value._isNested then
				if type(tableValue) ~= "table" then
					return false, _handleError(key, `expected nested table, got {actualType}`)
				end

				local isIncorrect, err = _softVerification(value.interface, tableValue)
				if isIncorrect == false then
					return false, err
				end

			else
				for _, expectedType in value do
					if actualType == expectedType then
						isValid = true
						break
					end
				end

				if not isValid then
					return false, _handleError(key, `expected one of multiple types, got {actualType}`)
				end
			end
		else
			if actualType ~= value then
				return false, _handleError(key, `expected "{value}", got "{actualType}"`)
			end
		end
	end

	for key in newTable do
		if interface[key] == nil then
			return false, _handleError(key, `unknown key "{key}" found`)
		end
	end

	table.insert(I.Instances, newTable)
	return true
end

--[=[
	@function soft
	@within I
	Safely validates a table against an interface. Will throw an error with a readable message if invalid.

	@param interface InterfaceType<any>
	@param newTable InterfaceType<any>
	@return true -- If the validation succeeds.
	@throws If validation fails, the error contains the exact cause.
]=]
function I.soft(interface: InterfaceType<any>, newTable: InterfaceType<any>): boolean
	local isValid, err = _softVerification(interface, newTable)
	if not isValid then
		error(err, 2)
	end
	return true
end

--[=[
	@function fromType
	@within I
	Generates a strict interface definition based on an existing typed table.

	This is useful when you've already defined an `export type` and want to generate
	a corresponding runtime-checkable interface without repeating yourself.

	@param typeTable T -- A Lua table that serves as a sample of the structure of a type.
	@return InterfaceType<T> -- An interface compatible with I.strict and I.soft.
]=]
   function I.fromType(typeTable: any): I.InterfaceType<any>
	local result = {}

	for key, value in typeTable do
		if type(value) == "string" then
			result[key] = value
		elseif type(value) == "table" then

			if value._isOptional then
				result[key] = I.opt(value.expectedType, value.default)
			elseif value._isNested then
				result[key] = I.nest(I.fromType(value.interface))
			else
				result[key] = value
			end
		end
	end

	return result
end

-- @Alias
I.test = I.soft
I.maybe = I.opt
I.from = I.fromType

--[=[
	@function get
	@within I
	Retrieves a validated instance by index.

	@param index number -- The index of the stored validated table.
	@return table? -- The validated table or nil if not found.
]=]
function I.get(index: number): {}
	return I.Instances[index]
end

return I
