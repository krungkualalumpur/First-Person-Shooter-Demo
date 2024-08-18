--!strict
--services
local RunService = game:GetService("RunService")
--packages
--modules
--types
export type WeaponData = {
    Name : string,
    Id : number,
    BulletSpeed : number,
    RateOfFire : number,
    AmmoRound : number
}
export type WeaponState = {
    AmmoCapacity : number,
    AmmoRound : number
}
--constants
--remotes
--variables
--references
--local functions
--class
local data : {[string] : WeaponData} = {}
data.Gun = {
    Name = "Gun",
    BulletSpeed = 100,
    Id = 1,
    RateOfFire = 0.5,
    AmmoRound = 10
} 

local util = {}
function util.getWeaponDataByName(weaponName : string): WeaponData?
    local raw = data[weaponName]
    if raw then 
        return  table.freeze(table.clone(raw))
    else
        return nil
    end
end

function util.getWeaponData(gunInstance : Instance) : WeaponData
    local id = gunInstance:GetAttribute("Id") :: number?
    local rateOfFire = gunInstance:GetAttribute("RateOfFire") :: number?
    local bulletSpeed = gunInstance:GetAttribute("BulletSpeed") :: number?
    local ammoRound = gunInstance:GetAttribute("AmmoRound") :: number?
    assert(id)
    assert(rateOfFire)
    assert(bulletSpeed)

    return {
        Name = gunInstance.Name,
        Id = id,
        RateOfFire = rateOfFire,
        BulletSpeed = bulletSpeed,
        AmmoRound = 10
    }
end

function util.setWeaponData(
    gunInstance : Instance,

    weaponData : WeaponData)
    
    assert(RunService:IsServer(), "Can only be done in server side!")

    gunInstance.Name = weaponData.Name;
    gunInstance:SetAttribute("Id", weaponData.Id);
    gunInstance:SetAttribute("RateOfFire", weaponData.RateOfFire)
    gunInstance:SetAttribute("BulletSpeed", weaponData.BulletSpeed)
    gunInstance:SetAttribute("AmmoRound", weaponData.AmmoRound)
end

function util.createWeaponState(
    ammoCapacity : number,
    ammoRound : number) : WeaponState
    return {
        AmmoCapacity = ammoCapacity,
        AmmoRound = ammoRound
    }
end

function util.getWeaponState(gunInstance : Instance) : WeaponState
    local ammoCapacity = gunInstance:GetAttribute("AmmoCapacity") :: number
    assert(ammoCapacity)
    local ammoRound = gunInstance:GetAttribute("AmmoRound") :: number
    assert(ammoRound)
    return {
        AmmoCapacity = ammoCapacity,
        AmmoRound = ammoRound
    }
end

function util.setWeaponState(gunInstance : Instance, weaponState : WeaponState) 
  gunInstance:SetAttribute("AmmoCapacity", weaponState.AmmoCapacity)
  gunInstance:SetAttribute("AmmoRound", weaponState.AmmoRound)    
end

return util 