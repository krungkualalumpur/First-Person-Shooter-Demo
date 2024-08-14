--!strict
--services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
--packages
local _Packages = ReplicatedStorage:WaitForChild("Packages")

local Maid = require(_Packages:WaitForChild("Maid"))
--modules
local WeaponSys = require(ServerScriptService:WaitForChild("Server"):WaitForChild("WeaponSys"))
--types
--constants
--remotes
--variables
--references
--local functions
--class
local maid = Maid.new()

WeaponSys.init(maid)