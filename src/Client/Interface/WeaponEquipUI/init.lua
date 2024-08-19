--!strict
--services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--packages
local _Packages = ReplicatedStorage:WaitForChild("Packages")

local Maid = require(_Packages:WaitForChild("Maid"))
local ColdFusion = require(_Packages:WaitForChild("ColdFusion8"))
local Sintesa = require(_Packages:WaitForChild("Sintesa"))
--modules
local WeaponUtil = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WeaponUtil"))
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
return function(
    maid : Maid,
    
    isDark : CanBeState<boolean>,

    weaponData : CanBeState<WeaponUtil.WeaponData>,

    weaponState : State<WeaponUtil.WeaponState>,
    playerState : State<WeaponUtil.PlayerState>)

    local _fuse = ColdFusion.fuse(maid)
    local _new = _fuse.new
    local _import = _fuse.import
    local _bind = _fuse.bind
    local _clone = _fuse.clone
    local _Computed = _fuse.Computed
    local _Value = _fuse.Value

    local isDarkState = _import(isDark, isDark)
    local weaponDataState = _import(weaponData, weaponData)

    local out = _new("Frame")({
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Children = {
            _new("UIPadding")({
                PaddingBottom = UDim.new(0, 20),
                PaddingTop = UDim.new(0, 20),
                PaddingLeft = UDim.new(0, 20),
                PaddingRight = UDim.new(0, 20),
            }),
            _new("UIListLayout")({
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                VerticalAlignment = Enum.VerticalAlignment.Bottom
            }),
            _bind(Sintesa.InterfaceUtil.TextLabel.ColdFusion.new(maid, 1, _Computed(function(wpnData : WeaponUtil.WeaponData)
                return wpnData.Name
            end, weaponDataState), _Computed(function(isDark : boolean)
                local dynamicScheme = Sintesa.ColorUtil.getDynamicScheme(isDark)
                local on_surface = Sintesa.StyleUtil.MaterialColor.Color3FromARGB(dynamicScheme:get_background())
                return on_surface
            end, isDarkState), Sintesa.TypeUtil.createTypographyData(Sintesa.StyleUtil.Typography.get(Sintesa.SintesaEnum.TypographyStyle.HeadlineLarge)) , 
            10))({
                TextXAlignment = Enum.TextXAlignment.Right
            }),
            _bind(Sintesa.InterfaceUtil.TextLabel.ColdFusion.new(maid, 1, _Computed(function(plrState : WeaponUtil.PlayerState, wpn : WeaponUtil.WeaponState)
                return `{tostring(wpn.AmmoRound)}/{tostring(plrState.AmmoCapacity)}`
            end, playerState, weaponState), _Computed(function(isDark : boolean)
                local dynamicScheme = Sintesa.ColorUtil.getDynamicScheme(isDark)
                local on_surface = Sintesa.StyleUtil.MaterialColor.Color3FromARGB(dynamicScheme:get_background())
                return on_surface
            end, isDarkState), Sintesa.TypeUtil.createTypographyData(Sintesa.StyleUtil.Typography.get(Sintesa.SintesaEnum.TypographyStyle.HeadlineSmall)) 
            , 10))({
                TextXAlignment = Enum.TextXAlignment.Right
            })
        }
    })
    return out
end
