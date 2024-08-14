--!strict
--services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
--packages
local _Packages = ReplicatedStorage:WaitForChild("Packages")

local Maid = require(_Packages:WaitForChild("Maid"))
local ColdFusion = require(_Packages:WaitForChild("ColdFusion8"))
local MathUtil = require(_Packages:WaitForChild("MathUtil"))
local NetworkUtil = require(_Packages:WaitForChild("NetworkUtil"))
local InputHandler = require(_Packages:WaitForChild("InputHandler"))
--modules
local WeaponData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WeaponData"))
--types
type Maid = Maid.Maid

type WeaponData = WeaponData.WeaponData
--constants
--remotes
local ON_WEAPON_SHOT = "OnWeaponShot"
--variables
--references
--local functions
local function playSound(id : number, target : Instance, volume : number?)
    local conn 

    local sound = Instance.new("Sound")
    sound.SoundId = `rbxassetid://{id}`
    sound.Volume = volume or 1
    sound.Parent = target

    sound:Play()

    conn = sound.Ended:Connect(function()
        if conn then conn:Disconnect() end
        sound:Destroy()
    end)
    return sound
end
function otherPlayerHit(plr : Player)
	
end


--class
local sys = {}
function onInstanceHit(hit : BasePart, cf : CFrame) 
    local function createFx()
        local p = Instance.new("Part")
        p.Anchored = true
        p.Transparency = 1
        p.CFrame = cf
        p.Parent = hit.Parent

        local smoke = Instance.new("Smoke")
        smoke.Color = hit.Color
        smoke.Size = 1.5
        smoke.Opacity = 4
        smoke.Parent = p
        local t = TweenService:Create(smoke, TweenInfo.new(5), {
            Opacity = 0
        })
        t:Play()
        t:Destroy()
        task.delay(0.4, function()
            smoke.Enabled = false 
            task.delay(5, function()
                smoke:Destroy()
                p:Destroy()
            end)
        end)
    end

    createFx()
end
    
function spawnBullet(startCf : CFrame)
    local _maid = Maid.new()
    local range = 1000
    
    local i = 0

    local ray = workspace:Raycast(startCf.Position, startCf.LookVector*range)
    local travelTime : number, hitPos : Vector3, hitInstance : Instance? = range/2856.8, startCf.Position + startCf.LookVector*range, nil
    if ray then 
        hitPos, hitInstance = ray.Position, ray.Instance
        travelTime = ray.Distance/2856.8
    end

    _maid:GiveTask(RunService.Stepped:Connect(function(t, dt : number)
        i += dt
        if i >= travelTime then
            _maid:Destroy()

            if hitInstance and hitInstance:IsA("BasePart") then 
                local plrHit = game.Players:GetPlayerFromCharacter(hitInstance.Parent)
                local _char = hitInstance.Parent
                if plrHit then
                    otherPlayerHit(plrHit)
                    return
                end
                onInstanceHit(hitInstance, CFrame.new(hitPos)*(hitInstance.CFrame - hitInstance.CFrame.Position))
            end
        end
    end))

    -- local p = _maid:GiveTask(Instance.new("Part"))
    -- p.Name = "Bullet"
    -- p.CanCollide = false
    -- p.Size = Vector3.new(0.2,0.2,1)
    -- p.CFrame = startCf-- handle.CFrame + handle.CFrame.LookVector*handle.Size.Y
    -- p.Material = Enum.Material.Neon
    -- p.Parent = workspace		

    -- --bullet init
    -- local i = 0
    -- _maid:GiveTask(RunService.Stepped:Connect(function(t, dt : number)
    --     i += dt*10
    --     p.AssemblyLinearVelocity = p.CFrame.LookVector*2856.8
    --     print(p.AssemblyLinearVelocity.Magnitude)
    --     --p.CFrame += p.CFrame.LookVector*3
    --     local parts = workspace:GetPartsInPart(p)
    --     if #parts > 0 then
    --         for _,v in pairs(parts) do
    --             local plrHit = game.Players:GetPlayerFromCharacter(v.Parent)
    --             local _char = v.Parent
    --             if plrHit then
    --                 otherPlayerHit(plrHit)
    --                 return
    --             end
    --             onInstanceHit(v, p.CFrame)
    --         end
    --         _maid:Destroy() 
    --     end
    --     if i >= 100 then
    --         _maid:Destroy()
    --     end
    -- end))

    -- return p
end
function getWeaponFromPlayer(plr : Player)
    local char = plr.Character
    assert(char)
    local gun = char:FindFirstChild("Gun") :: Tool?
    return if gun and gun:FindFirstChild("Handle") then gun else nil
end

function onGunShot(
    plr : Player, 
    shotPosCf: CFrame -- temporary!
    )

    local gun = getWeaponFromPlayer(plr)
    assert(gun)
    local weaponData = WeaponData.getWeaponData(gun)
    
    local t = 0
    local _maid = Maid.new()

    local handle = gun:WaitForChild("Handle") :: BasePart
    
    spawnBullet(shotPosCf)

    playSound(1905367471, handle, 2)
end
function sys.init(maid : Maid)
    for _,v in pairs(CollectionService:GetTagged("Gun")) do
        WeaponData.setWeaponData(
            v, 
            v.Name, 
            WeaponData.getWeaponDataByName(v.Name).Id,
            WeaponData.getWeaponDataByName(v.Name).RateOfFire,
            WeaponData.getWeaponDataByName(v.Name).BulletSpeed
        )
    end
    --networks
    maid:GiveTask(NetworkUtil.onServerEvent(ON_WEAPON_SHOT, onGunShot))
end

return sys