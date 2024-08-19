--!strict
--services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--packages
local _Packages = ReplicatedStorage:WaitForChild("Packages")

local Maid = require(_Packages:WaitForChild("Maid"))
local ColdFusion = require(_Packages:WaitForChild("ColdFusion8"))
--modules
local WeaponUtil = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WeaponUtil"))
local interface = require(script.Parent)
--types
type Maid = Maid.Maid

type Fuse = ColdFusion.Fuse
type State<T> = ColdFusion.State<T>
type ValueState<T> = ColdFusion.ValueState<T>
type CanBeState<T> = ColdFusion.CanBeState<T>
--constants
--remotes
--variables
--references
--local functions
--class

return function(target : CoreGui)
   local maid = Maid.new()
   local _fuse = ColdFusion.fuse(maid)
   local _Value = _fuse.Value
   
   local weaponData = WeaponUtil.getWeaponDataByName("Gun"); assert(weaponData)
   local out = interface(
      maid,

      false,
      weaponData,

      _Value(WeaponUtil.createWeaponState(1)),
    _Value(WeaponUtil.createPlayerState(false, false, 100))
   )
   out.Parent = target
   return function()
      maid:Destroy()
   end
end