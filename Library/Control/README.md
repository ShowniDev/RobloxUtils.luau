# Control Module

**Version:** 1.0.0  
**Author:** YourName  
**Dependencies:**  
- [`Destroyable`](https://github.com/ShowniDev/RobloxUtils.luau/blob/main/Utils/Destroyable/init.luau)
- [`Signal`](https://github.com/Sleitnick/RbxUtil/blob/main/modules/signal/init.luau)

## Overview
The `Control` module is a flexible input manager for Roblox that lets you:
- Bind keys or key combinations to named actions
- Support looped (hold), toggle, and normal press actions
- Rebind keys at runtime
- Track pressed state
- Automatically clean up connections with `Destroyable`

---

## Example
```lua
local Control = require(path.to.Control)

local controls = Control.new(player) -- `Control.new(player: Player, autoStartDebug: boolean?)`

controls:Bind({
    name = "Sprint",
    key = Enum.KeyCode.LeftShift,

    onPress = function()
        print("Sprinting...")
    end,

    onRelease = function()
        print("Stopped sprinting")
    end,

    loop = true, -- or toggle
})

controls:Start()
