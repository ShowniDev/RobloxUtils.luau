# Interface
Interface system for type-safe Lua table validation
# 📐 I — Interface Validator for Lua / Luau

**I** is a small utility for validating Lua table structures, inspired by type systems. It allows developers to define expected table shapes and validate values with strict or soft checking.

## Features
- `I.strict(interface, table)` — Validates a table strictly. Throws an error on mismatch.  
- `I.soft(interface, table)` / `I.test(...)` — Soft validation. Returns true or an error message.  
- `I.opt(type, default)` — Marks a field as optional with a default value (also optional).  
- `I.nest(interface)` — Allows nested interface validation.  
- `I.get(index)` — Retrieves a previously validated table from internal memory.  
- `I.fromType(typeExampleTable)` — 🔁 Automatically generates an interface from a typed-like table example.


## Tips
- ♻️ Automatically garbage collects validated tables via weak references in `I.Instances`.  
- 💡 Use `fromType` when you already have a typed structure and want to quickly create a matching interface without rewriting the whole schema manually.

## Alias
-`I.soft`
 `I.test`
-`I.maybe`
 `I.opt`
-`I.fromType`
 `I.from`
