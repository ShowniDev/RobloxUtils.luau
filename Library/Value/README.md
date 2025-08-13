# Value Module

**Version:** 1.0.0  
**Author:** YourName  
**Dependencies:**  
- [`Destroyable`](https://github.com/ShowniDev/RobloxUtils.luau/blob/main/Utils/Destroyable/init.luau)
- [`Signal`](https://github.com/Sleitnick/RbxUtil/blob/main/modules/signal/init.luau)

## Overview
The `Value` module provides a generic observable value type for Roblox Lua projects.  
It allows you to:
- Store and manage a value of any type (except tables)
- Observe changes via events
- Transform values into new observables
- Filter updates based on conditions
- Save and load state
- Bind two `Value` objects together

It integrates with `Destroyable` to automatically clean up connections and resources.

---

## Example
```lua
local Value = require(path.to.Value)

-- Create a Value
local health = Value.new(100)

-- Observe changes
health:observe(function(newValue)
    print("Health is now:", newValue)
end)

-- Change value
health:set(90) -- Fires event

-- Increment
health:calculate(-10) -- Now 80

-- Save and load
health:save()
print("Saved health:", health:load())
