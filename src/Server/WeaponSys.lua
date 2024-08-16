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
type ClientWeaponState = {
    CFrame : CFrame,
    IsAiming : boolean
}
type Maid = Maid.Maid

type PlayerState = {
    IsAiming : boolean
}
type WeaponData = WeaponData.WeaponData
--constants
--remotes
local ON_WEAPON_SHOT = "OnWeaponShot"
local ON_WEAPON_EQUIP = "OnWeaponEquip"
local ON_AIMING = "OnAiming"
local ON_PLAYER_AIM_DIRECTION_UPDATE = "OnPlayerAimDirectionUpdate"

local GET_CLIENT_WEAPON_STATE_INFO = "GetClientWeaponStateInfo"
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



--class
local sys = {}

function createPlayerState(
    isAiming : boolean) : PlayerState
    return {
        IsAiming = isAiming
    }
end
function getPlayerState(plr : Player) : PlayerState
    return {
        IsAiming = plr:GetAttribute("IsAiming") :: boolean,
    }
end
function setPlayerState(
    plr : Player, 
    plrState: PlayerState) 
    
    plr:SetAttribute("IsAiming", plrState.IsAiming)
end

function onWeaponEquip(plr : Player, gun : Tool)
    local char = plr.Character; assert(char)

    local handle = gun:FindFirstChild("GunMesh") :: BasePart? ;assert(handle)
     
    local _toolMaid = Maid.new()

    NetworkUtil.fireAllClients(ON_WEAPON_EQUIP, plr)
    local leftLowerArm,leftUpperArm, leftHand, 
    rightLowerArm, rightUpperArm, rightHand = char:FindFirstChild("LeftLowerArm") :: BasePart, 
        char:FindFirstChild("LeftUpperArm") :: BasePart, 
        char:FindFirstChild("LeftHand") :: BasePart, 
        char:FindFirstChild("RightLowerArm") :: BasePart, 
        char:FindFirstChild("RightUpperArm") :: BasePart,
        char:FindFirstChild("RightHand") :: BasePart
    assert(leftLowerArm and leftUpperArm and leftHand and  rightLowerArm and rightUpperArm and rightHand)
    local leftShoulder, leftElbow, rightShoulder, rightElbow = leftUpperArm:FindFirstChild("LeftShoulder") :: Motor6D,
        leftLowerArm:FindFirstChild("LeftElbow") :: Motor6D,
        rightUpperArm:FindFirstChild("RightShoulder") :: Motor6D,
        rightLowerArm:FindFirstChild("RightElbow") :: Motor6D
    assert(leftShoulder, leftElbow, rightShoulder, rightElbow)

    local function cleanup()
        _toolMaid:Destroy()   
    end
    
    local t = 1
    _toolMaid:GiveTask(RunService.Stepped:Connect(function(_, dt : number)
        if t > 1 then 
            t = 0
            local info  = NetworkUtil.invokeClient(GET_CLIENT_WEAPON_STATE_INFO, plr)
            NetworkUtil.fireAllClients(ON_PLAYER_AIM_DIRECTION_UPDATE, plr, info.CFrame) 
        end
        t += dt 
    end))
    
    
    _toolMaid:GiveTask(gun.AncestryChanged:Connect(function()
        if not gun:IsAncestorOf(char) then
            cleanup()
        end
    end))
end

function onCharacterAdded(char : Model)
    local _maid = Maid.new()
    local plr = Players:GetPlayerFromCharacter(char)

    local humanoid = char:WaitForChild("Humanoid") :: Humanoid

    local function onChildAdded(child : Instance)
        assert(char.PrimaryPart)
        local weaponData 
        pcall(function()
            weaponData = WeaponData.getWeaponDataByName(child.Name) 
        end)
      
        if weaponData then  
            assert(child:IsA("Tool"))
            
            onWeaponEquip(plr, child)
        end
    end

    local function onChildRemoved(child : Instance)
        local weaponData 
        pcall(function()
            weaponData = WeaponData.getWeaponDataByName(child.Name) 
        end)
        if weaponData then
            assert(child:IsA("Tool"))
            local leftLowerArm,leftUpperArm, leftHand, 
            rightLowerArm, rightUpperArm, rightHand = char:FindFirstChild("LeftLowerArm") :: BasePart, 
                char:FindFirstChild("LeftUpperArm") :: BasePart, 
                char:FindFirstChild("LeftHand") :: BasePart, 
                char:FindFirstChild("RightLowerArm") :: BasePart, 
                char:FindFirstChild("RightUpperArm") :: BasePart,
                char:FindFirstChild("RightHand") :: BasePart
            assert(leftLowerArm and leftUpperArm and leftHand and  rightLowerArm and rightUpperArm and rightHand)
        
            NetworkUtil.fireAllClients(ON_PLAYER_AIM_DIRECTION_UPDATE, plr, char:GetBoundingBox())
            -- for _,v in pairs(rightHand:GetChildren()) do
            --     if v:IsA("Weld") and v.Part0 and v.Part0:IsDescendantOf(child) then
            --         v:Destroy()
            --     end
            -- end
            -- child:PivotTo(CFrame.new())
        end
    end

    _maid:GiveTask(char.ChildAdded:Connect(onChildAdded))
    _maid:GiveTask(char.ChildRemoved:Connect(onChildRemoved))

    do
        local prevHealth = humanoid.Health
        local isDead = false
        _maid:GiveTask(humanoid.HealthChanged:Connect(function(health : number)
            local delta =  health - prevHealth
            if health == 0 then 
                if not isDead then 
                    isDead = true
                    playSound(1978589648, char:WaitForChild("HumanoidRootPart"))
                end
            else
                if delta < -25 then
                    playSound(1007368252, char:WaitForChild("HumanoidRootPart"), 3)
                elseif delta >= -25 and delta < 0 then
                    playSound(8011792922, char:WaitForChild("HumanoidRootPart"), 2)
                end
            end
            prevHealth = health
        end))
    end

    _maid:GiveTask(char.AncestryChanged:Connect(function()
        if char.Parent == nil then
            _maid:Destroy()
        end
    end))
end
function onPlayerAdded(plr : Player)
    local _maid = Maid.new()
    
    setPlayerState(plr, createPlayerState(
        false
    ))

    onCharacterAdded(plr.Character or plr.CharacterAdded:Wait())
    _maid:GiveTask(plr.CharacterAdded:Connect(onCharacterAdded))

    _maid:GiveTask(plr.AncestryChanged:Connect(function()
        if plr.Parent == nil then
            _maid:Destroy()
        end
    end))
end

function clampBulletStartCFrame(characterCf : CFrame, startBulletCf : CFrame)
    local function adjustv3Fn(v3 : Vector3, fn : (axis : Enum.Axis) -> number)
        return Vector3.new(fn(Enum.Axis.X), fn(Enum.Axis.Y), fn(Enum.Axis.Z))
    end
    local charRelCf = characterCf:ToObjectSpace(startBulletCf)
    local clampedRelV3
    local _, e = pcall(function() 
        clampedRelV3 = adjustv3Fn(charRelCf.Position, function(axis : Enum.Axis)
            return math.clamp(charRelCf[axis.Name], -10, 10)
        end) 
    end)
    if not clampedRelV3 and e then 
        warn(e)
    end
    assert(clampedRelV3)
    local clampedRelCf = characterCf:ToWorldSpace(CFrame.new(clampedRelV3)*(charRelCf - charRelCf.Position))
    return clampedRelCf
end

function getEffectsFolder()
    local effectsFolder =  workspace:WaitForChild("Assets"):FindFirstChild("EffectsFolder") or Instance.new("Folder")
    effectsFolder.Name = "EffectsFolder"
    effectsFolder.Parent = workspace:WaitForChild("Assets")
    return effectsFolder
end

function getWeaponState()
    
end
function otherPlayerHit(plr : Player)
	
end


function onInstanceHit(hit : BasePart, cf : CFrame) 
    local function createFx()
        local p = Instance.new("Part")
        p.Anchored = true
        p.CanCollide = false
		p.Transparency = 1
        p.CFrame = cf
        p.Parent = getEffectsFolder()

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

function otherHumanoidHit(char : Model, hitPart : BasePart, hitCf : CFrame)
    local function createFx()
        local p = Instance.new("Part")
        p.Anchored = true
        p.CanCollide = false
		p.Transparency = 1
        p.CFrame = hitCf
        p.Parent = getEffectsFolder()

        local smoke = Instance.new("Smoke")
        smoke.Color = Color3.fromRGB(255,50,50)
        smoke.Size = 0.8
        smoke.Opacity = 4
        smoke.Parent = p
        local t = TweenService:Create(smoke, TweenInfo.new(1), {
            Opacity = 0
        })
        t:Play()    
        t:Destroy()
        task.delay(0.4, function()
            smoke.Enabled = false 
            task.delay(1, function()
                smoke:Destroy()
                p:Destroy()
            end)
        end)
    end

    local plr = Players:GetPlayerFromCharacter(char)
    local humanoid = char:FindFirstChild("Humanoid") :: Humanoid?
    local damage = if hitPart.Name == "Head" then 60 else 15

    assert(humanoid)
    humanoid.Health -= damage
    
    createFx()
end
    
function spawnBullet(startCf : CFrame)
    local _maid = Maid.new()
    local range = 1000
    local pcf  = startCf

    local i = 0

     local p = _maid:GiveTask(Instance.new("Part"))
     p.Name = "Bullet"
     p.CanCollide = false
     p.Anchored = true
     p.Size = Vector3.new(0.2,0.2,1)
     p.CFrame = startCf-- handle.CFrame + handle.CFrame.LookVector*handle.Size.Y
     p.Material = Enum.Material.Neon
     p.Parent = workspace		

     local raycastParams = RaycastParams.new()
     raycastParams.FilterDescendantsInstances = {p, getEffectsFolder()}
     --bullet init
     _maid:GiveTask(RunService.Stepped:Connect(function(t, dt : number)
        local velocity = p.CFrame.LookVector*2856.8*dt

         local ray = if pcf then workspace:Raycast(pcf.Position, velocity, raycastParams) else nil
         
         p.CFrame = pcf + velocity
        --  p.AssemblyLinearVelocity = velocity/dt

         if ray then 
            local hit = ray.Instance
			local char = if hit.Parent and hit.Parent:FindFirstChild("Humanoid") then hit.Parent 
                elseif hit.Parent and hit.Parent.Parent and hit.Parent.Parent:FindFirstChild("Humanoid") then hit.Parent.Parent
            else nil
			
            if char then
				otherHumanoidHit(char :: Model, hit, CFrame.new(ray.Position, ray.Position + ray.Normal))
            else
                onInstanceHit(hit, CFrame.new(ray.Position, ray.Position + ray.Normal))
			end
			_maid:Destroy()
         end
         i += dt*10
         --p.CFrame += p.CFrame.LookVector*3
		 --local parts = p:GetTouchingParts()
		 --local p2 = p:Clone()
		 --p2.CanCollide = false
		 --p2.Anchored = true
		 --p2.Parent = workspace
		--print(p.AssemblyLinearVelocity.Magnitude, parts)
  --       --if #parts > 0 then
         --    for _,v in pairs(parts) do
         --        local plrHit = game.Players:GetPlayerFromCharacter(v.Parent)
         --        local _char = v.Parent
         --        if plrHit then
         --            otherPlayerHit(plrHit)
         --            return
         --        end
         --        onInstanceHit(v, p.CFrame)
         --    end
         --    _maid:Destroy() 
         --end
         if i >= 100 then
             _maid:Destroy()
             return
         end

         pcf += velocity
     end))

	_maid:GiveTask(p.Touched:Connect(function(hit : BasePart)
		if hit.CanCollide and hit.Transparency < 1 then 
			local char = if hit.Parent and hit.Parent:FindFirstChild("Humanoid") then hit.Parent else nil
			if char then
				otherHumanoidHit(char :: Model, hit, pcf)
            else
                onInstanceHit(hit, pcf)
			end
			_maid:Destroy()
		end
	end))

    return p
end
function getWeaponFromPlayer(plr : Player) : Tool?
    local char = plr.Character
    assert(char)
    for _,v in pairs(char:GetChildren()) do 
        local weaponData = WeaponData.getWeaponDataByName(v.Name)
        if weaponData then 
            return v :: Tool
        end
    end
    return nil
end

function onGunShot(
    plr : Player, 
    shotPosCf: CFrame -- temporary!
    )
    local char = plr.Character
    assert(char and char.PrimaryPart)
    local head = char:FindFirstChild("Head")
    assert(head)
    
    local startCf = clampBulletStartCFrame(char.PrimaryPart.CFrame, shotPosCf)
    local gun = getWeaponFromPlayer(plr)
    assert(gun)
    local weaponData = WeaponData.getWeaponData(gun)
    assert(weaponData)

    local shotTimeStampKey = "ShotTimestamp" 
    local lastTimeShot = gun:GetAttribute(shotTimeStampKey) :: number? or 0 
    local timeNow = DateTime.now().UnixTimestampMillis/1000
    
    if weaponData.RateOfFire <= (timeNow - lastTimeShot) then 
        gun:SetAttribute(shotTimeStampKey, timeNow)

        local handle = gun:WaitForChild("GunMesh") :: BasePart
    
        task.spawn(function() spawnBullet(startCf) end)

        NetworkUtil.fireAllClients(ON_PLAYER_AIM_DIRECTION_UPDATE, plr, shotPosCf)
        playSound(1905367471, handle, 2)
        return true
    end
   
    return false
end
function sys.init(maid : Maid)
    for _,v in pairs(CollectionService:GetTagged("Gun")) do
        local weaponData = WeaponData.getWeaponDataByName(v.Name)
        assert(weaponData)
        WeaponData.setWeaponData(
            v, 
            v.Name, 
            weaponData.Id,
            weaponData.RateOfFire,
            weaponData.BulletSpeed
        )
    end
    
    maid:GiveTask(Players.PlayerAdded:Connect(onPlayerAdded))
    --networks
    maid:GiveTask(NetworkUtil.onServerEvent(ON_AIMING, function(plr : Player, aiming : boolean)  
        local playerState = getPlayerState(plr)
        
        setPlayerState(plr, createPlayerState(
            aiming
        ))
    end))

    NetworkUtil.onServerInvoke(ON_WEAPON_SHOT, onGunShot)

    NetworkUtil.getRemoteEvent(ON_WEAPON_EQUIP)
    NetworkUtil.getRemoteEvent(ON_PLAYER_AIM_DIRECTION_UPDATE)
    NetworkUtil.getRemoteFunction(GET_CLIENT_WEAPON_STATE_INFO)
    
end

return sys