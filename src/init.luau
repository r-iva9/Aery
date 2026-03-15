--!strict
--!optimize 2
--!native

--[[
    AERY: GARBAGE COLLECTOR MODULE and PART OF ALLURE ECOSYSTEM
    By r-iva9
    1.0.0
    Open source (MIT)
    https://github.com/r-iva9/Aery

    ALLURE FULLSTACK ECOSYSTEM
    By r-iva9
	1.1.0
	Open source (MIT)
	https://github.com/r-iva9/Allure
]]

------------
-- TYPES

--[=[
	luau type blanks
]=]
type table = { [any]: any }
type fn = <A..., R...>(A...) -> R...

--[=[
	Contents of a garbage collector
]=]
export type Trashable =
	| Instance
	| thread
	| fn
	| RBXScriptConnection
	| { __deleter: fn }
	| { __destroy: fn }
	| { Destroy: fn }
	| { destroy: fn }
	| { _destroy: fn }
	| { _Destroy: fn }
	| { Trashable }
	| any --the rest is set to nil without additional actions

--[=[
	Aery garbage collector
]=]
export type Aery = setmetatable<
	{ Trashable },
	{
		__call: fn,
		__index: {
			Insert: typeof(table.insert),
			Remove: typeof(table.remove),

			--- Use `used` as a new dependency of this Aery
			Use: <T>(self: Aery, used: T) -> Aery,

			--- Equivalent to `Aery:Clean()` or `Aery()`
			Clean: (self: Aery, cleanupWrapper: { [string]: fn }?) -> Aery,

			--- Uses `newWrapper` as the `cleanupWrapper` to be used in cleaning when `cleanupWrapper` is not passed.<br>If `newWrapper` is not specified, the wrapper is returned
			Wrapper: <T>(self: Aery, newWrapper: T?) -> table | Aery | nil,

			--- Creates a new Aery ***inside*** of this Aery.<br>This child aery can reference dependencies of the parent, and will be cleaned when the parent is cleaned.
			Aery: & (<S>(S) -> S & Aery)
				& (<S, A>(S, A) -> S & Aery & A)
				& (<S, A, B>(S, A, B) -> S & Aery & A & B)
				& (<S, A, B, C>(S, A, B, C) -> S & Aery & A & B & C)
				& (<S, A, B, C, D>(S, A, B, C, D) -> S & Aery & A & B & C & D)
				& (<S, A, B, C, D, E>(S, A, B, C, D, E) -> S & Aery & A & B & C & D & E)
				& (<S, A, B, C, D, E, F>(S, A, B, C, D, E, F) -> S & Aery & A & B & C & D & E & F)
				& (<S, A, B, C, D, E, F, G>(S, A, B, C, D, E, F, G) -> S & Aery & A & B & C & D & E & F & G)
				& (<S, A, B, C, D, E, F, G, H>(
					S,
					A,
					B,
					C,
					D,
					E,
					F,
					G,
					H
				) -> S & Aery & A & B & C & D & E & F & G & H)
				& (<S, A, B, C, D, E, F, G, H, I>(
					S,
					A,
					B,
					C,
					D,
					E,
					F,
					G,
					H,
					I
				) -> S & Aery & A & B & C & D & E & F & G & H & I),
		},
	}
>

--[=[
	Constructor function of Aeries
]=]
export type AeryConstructor =
	& (<S>(S) -> Aery)
	& (<S, A>(S, A) -> Aery & A)
	& (<S, A, B>(S, A, B) -> Aery & A & B)
	& (<S, A, B, C>(S, A, B, C) -> Aery & A & B & C)
	& (<S, A, B, C, D>(S, A, B, C, D) -> Aery & A & B & C & D)
	& (<S, A, B, C, D, E>(S, A, B, C, D, E) -> Aery & A & B & C & D & E)
	& (<S, A, B, C, D, E, F>(S, A, B, C, D, E, F) -> Aery & A & B & C & D & E & F)
	& (<S, A, B, C, D, E, F, G>(S, A, B, C, D, E, F, G) -> Aery & A & B & C & D & E & F & G)
	& (<S, A, B, C, D, E, F, G, H>(S, A, B, C, D, E, F, G, H) -> Aery & A & B & C & D & E & F & G & H)
	& (<S, A, B, C, D, E, F, G, H, I>(S, A, B, C, D, E, F, G, H, I) -> Aery & A & B & C & D & E & F & G & H & I)

------------
-- UTILITY

--- Returns a typesafe reference to `t`
local function ref<T>(t: T): any
	return t :: any
end

--[[
	Utility table merger.
	<br>Takes 2 tables, modifies and returns the first one

	Does not perform cloning or deepcloning
]]
local function lowmerge<T, V>(t0: T, t1: V): T & V
	for k, v in t1 :: table do
		(t0 :: any)[k] = v
	end
	return t0
end

--[[
	`if --> elseif --> elseif` nesting for equality conditions but with custom type for the argument and returns

	```luau
	local a = equalityCases(typeof(value), {
		number = function(k, v: number)
			print("value is a number:", v)
			return true
		end,
		['string'] = function(k, v: string)
			print("value is a string:", v)
			return false
		end,
	}, key, value)
	```
]]
local function equalityCases<T, V>(argument: T, cases: { [V]: fn }, ...)
	for condition, case in cases do
		if argument == condition then
			return case(...)
		end
	end
end

------------
-- AERY

local Aery = {
	Name = "Aery",
	Version = "1.0.0",
	Author = "r-iva9",

	--- ALLURE
	Tags = {
		Priority = 0,
	},
	Dependencies = {},
}

--[[
	Entirely clears the `t` table or Aery. Identical to `Aery:Clean()` or `Aery()`
	<br>Supports a `cleanupWrapper` to override the cleanup functions or avoid cleanup

	```luau
	local myTable = {}

	-- Clean everything, but keep instances:
	Aery:Clean(myTable, {
		Instance = function(k, v, t)
			t[k] = v
		end
	})
	```
]]
Aery.Clean = function<S>(self: S, t: table, cleanupWrapper: { [string]: fn }?)
	local memo: table? = if cleanupWrapper then {} else nil
	local cases = {
		Instance = function(i, s: Instance)
			s:Destroy()
		end,
		["function"] = function(i, s: fn)
			s(s)
		end,
		thread = function(i, s: thread)
			coroutine.close(s)
		end,
		RBXScriptConnection = function(i, s: RBXScriptConnection)
			s:Disconnect()
		end,
		["table"] = function(i: number, s: table)
			equalityCases(true, {
				[getmetatable(s) ~= nil and ref(getmetatable(s)).__index.Clean ~= nil] = function(s: any)
					s:Clean()
				end,
				[s.Destroy ~= nil] = s.Destroy,
				[s.destroy ~= nil] = s.destroy,
				[s._Destroy ~= nil] = s._Destroy,
				[s._destroy ~= nil] = s._destroy,
				[s.__deleter ~= nil] = s.__deleter,
				[s.__destroy ~= nil] = s.__destroy,
				[true] = function(s: table)
					Aery:Clean(s)
				end,
			}, s)
		end,
	}

	for i, k in pairs(t) do
		equalityCases(typeof(k), if cleanupWrapper then lowmerge(cases, cleanupWrapper) else cases, i, k, memo)
	end
	table.clear(t)

	if not memo then
		return t
	end
	for i, k in memo do
		t[i] = k
	end

	return t
end

--[[
	Creates a new Aery garbage collector.
	<br>Supports a `cleanupWrapper` to override the cleanup functions or avoid cleanup

	```luau
	local myAery = Aery:Aery {value = 10}

	-- An Aery inside of myAery
	local smallAery = myAery:Aery()

	-- Clean everything, including smallAery, but keep instances:
	myAery  {
		Instance = function(k, v, t)
			t[k] = v
		end
	}
	```
]]
Aery.Aery = function<S, T...>(self: S, ...: T...)
	local content = {} :: { Trashable }
	local dep: { any } = { ... }
	local wrapper = nil

	return setmetatable(content, {
		__call = function(self, wrap: any?)
			Aery:Clean(self, wrap or wrapper)
		end,
		__index = setmetatable({
			Insert = table.insert,
			Remove = table.remove,
			Use = function<S, T>(self: S, used: T)
				table.insert(dep, used)
				return self
			end,
			Wrapper = function<T>(self: Aery, newWrapper: T?): table | Aery | nil
				if not newWrapper then
					return wrapper
				end
				wrapper = newWrapper
				return self
			end,
			Aery = function<S, T...>(self: S, ...: T...)
				local A = Aery:Aery(self, ... :: any)
				table.insert(content :: table, A)
				return A
			end,
			Clean = function<S>(self: S, cleanupWrapper: { [string]: fn }?)
				return Aery:Clean(self, cleanupWrapper or wrapper)
			end,
		}, {
			__index = function(t, k)
				for _, c in dep do
					if c[k] then
						return c[k]
					end
				end
			end,
		}),
	})
end :: AeryConstructor

return Aery
