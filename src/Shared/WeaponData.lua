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
    RateOfFire : number
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
    RateOfFire = 0.5
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
    assert(id)
    assert(rateOfFire)
    assert(bulletSpeed)

    return {
        Name = gunInstance.Name,
        Id = id,
        RateOfFire = rateOfFire,
        BulletSpeed = bulletSpeed
    }
end

function util.setWeaponData(
    gunInstance : Instance,

    name : string,
    id : number,
    rateOfFire : number,
    bulletSpeed : number)
    
    assert(RunService:IsServer(), "Can only be done in server side!")

    gunInstance.Name = name;
    gunInstance:SetAttribute("Id", id);
    gunInstance:SetAttribute("RateOfFire", rateOfFire)
    gunInstance:SetAttribute("BulletSpeed", bulletSpeed)
end

return util 