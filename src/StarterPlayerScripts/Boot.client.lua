--!strict
--services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--packages
local _Packages = ReplicatedStorage:WaitForChild("Packages")

local Maid = require(_Packages:WaitForChild("Maid"))
--modules
local AnimationManager = require(ReplicatedStorage:WaitForChild("Client"):WaitForChild("AnimationManager"))
local WeaponSys = require(ReplicatedStorage:WaitForChild("Client"):WaitForChild("WeaponSys"))
--types
--constants
--remotes
--variables
--references
--local functions
--class
local maid = Maid.new()

AnimationManager.init(maid)
WeaponSys.init(maid)

-- local char = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
-- while task.wait(1) do
--     for _,v in pairs(char.Humanoid.Animator:GetPlayingAnimationTracks()) do
--         --if v.Name:lower():find("toolnoneanim") or v.Name:lower():find("animation1") or v.Name:lower():find("idle") then 
--         v:Stop(0)
--         --end
--     end
-- end