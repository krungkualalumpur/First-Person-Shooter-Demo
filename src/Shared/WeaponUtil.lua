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
    AmmoRound : number,
    HealthDamage : number
}
export type WeaponState = {
    AmmoRound : number
}
export type PlayerState = {
    IsReloading : boolean,
    IsAiming : boolean,
    AmmoCapacity : number
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
    BulletSpeed = 2856.8,
    Id = 1,
    RateOfFire = 0.5,
    AmmoRound = 10,
    HealthDamage = 15
} 
data.Uzi = {
    Name = "Uzi",
    BulletSpeed = 2856.8,
    Id = 2,
    RateOfFire = 0.1,
    AmmoRound = 20,
    HealthDamage = 8
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
    local healthDamage = gunInstance:GetAttribute("HealthDamage") :: number?
    assert(id)
    assert(rateOfFire)
    assert(bulletSpeed)
    assert(ammoRound)
    assert(healthDamage)

    return {
        Name = gunInstance.Name,
        Id = id,
        RateOfFire = rateOfFire,
        BulletSpeed = bulletSpeed,
        AmmoRound = ammoRound,
        HealthDamage = healthDamage
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
    gunInstance:SetAttribute("HealthDamage", weaponData.HealthDamage)
end

function util.createWeaponState(
    ammoRound : number) : WeaponState
    return {
        AmmoRound = ammoRound
    }
end

function util.getWeaponState(gunInstance : Instance) : WeaponState
    local ammoRound = gunInstance:GetAttribute("AmmoRound") :: number
    assert(ammoRound)
    return {
        AmmoRound = ammoRound
    }
end

function util.setWeaponState(gunInstance : Instance, weaponState : WeaponState) 
  gunInstance:SetAttribute("AmmoRound", weaponState.AmmoRound)    
end

function util.createPlayerState(
    isAiming : boolean,
    isReloading : boolean,
    ammoCapacity : number) : PlayerState
    return {
        IsAiming = isAiming,
        IsReloading = isReloading,
        AmmoCapacity = ammoCapacity
    }
end
function util.getPlayerState(plr : Player) : PlayerState
    local ammoCapacity = plr:GetAttribute("AmmoCapacity")
    assert(type(ammoCapacity) == "number")
    local isReloading = plr:GetAttribute("IsReloading")
    assert(type(isReloading) == "boolean")
    local isAiming = plr:GetAttribute("IsAiming")
    assert(type(isAiming) == "boolean")

    return {
        AmmoCapacity = ammoCapacity :: number,
        IsReloading = isReloading :: boolean,
        IsAiming = isAiming :: boolean,
    }
end
function util.setPlayerState(
    plr : Player, 
    plrState: PlayerState) 
    
    plr:SetAttribute("IsAiming", plrState.IsAiming)
    plr:SetAttribute("AmmoCapacity", plrState.AmmoCapacity)
    plr:SetAttribute("IsReloading", plrState.IsReloading)
end

return util 