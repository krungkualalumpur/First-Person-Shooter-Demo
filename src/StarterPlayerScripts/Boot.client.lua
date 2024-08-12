--!strict
--services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--packages
local _Packages = ReplicatedStorage:WaitForChild("Packages")

local Maid = require(_Packages:WaitForChild("Maid"))
--modules
local WeaponSys = require(ReplicatedStorage:WaitForChild("Client"):WaitForChild("WeaponSys"))
--types
--constants
--remotes
--variables
--references
--local functions
--class
local maid = Maid.new()
print("Ima le")
WeaponSys.init(maid)