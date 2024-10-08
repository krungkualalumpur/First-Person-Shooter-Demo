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
local WeaponUtil = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WeaponUtil"))
--types
type ClientWeaponState = {
    CFrame : CFrame,
    IsAiming : boolean
}
type Maid = Maid.Maid

type PlayerState = WeaponUtil.PlayerState
type WeaponUtil = WeaponUtil.WeaponData
--constants
--remotes
local ON_WEAPON_SHOT = "OnWeaponShot"
local ON_WEAPON_SHOT_START = "OnWeaponShotStart"
local ON_WEAPON_SHOT_END = "OnWeaponShotEnd"

local ON_WEAPON_EQUIP = "OnWeaponEquip"
local ON_AIMING = "OnAiming"
local ON_PLAYER_AIM_DIRECTION_UPDATE = "OnPlayerAimDirectionUpdate"
local ON_WEAPON_SHOT_EFFECT = "OnWeaponShotEffect"

local ON_WEAPON_RELOAD = "OnWeaponReload"
local ON_WEAPON_RELOAD_CLIENT= "OnWeaponReloadClient"

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

local maid = Maid.new()

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
            weaponData = WeaponUtil.getWeaponDataByName(child.Name) 
        end)
      
        if weaponData then  
            assert(child:IsA("Tool"))
            
            onWeaponEquip(plr, child)
        end
    end

    local function onChildRemoved(child : Instance)
        local weaponData 
        pcall(function()
            weaponData = WeaponUtil.getWeaponDataByName(child.Name) 
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
    
    WeaponUtil.setPlayerState(plr, WeaponUtil.createPlayerState(
        false,
        false,
        15
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

function onInstanceHit(hit : BasePart, cf : CFrame) 
    local maxMarkCountPerHitInstance = 10
    
    local raycastParams = RaycastParams.new()
     raycastParams.FilterDescendantsInstances = {getEffectsFolder()}

    local function createDefaultMark(offset : Vector3?)
        local markLifeTime = 10
        local ray = workspace:Raycast(cf.Position - cf.LookVector, cf.LookVector*100, raycastParams)

        if ray --[[and ray.Instance == hit ]]then 
            local p = Instance.new("Part")
            p.CanCollide = false
            p.Anchored = true
            p.Transparency = 1
            p.Size = Vector3.new(0.4,0.4,0.05)
            p.CFrame = CFrame.new(ray.Position, ray.Position + ray.Normal) + if offset then offset else Vector3.new()
            local sg = Instance.new("SurfaceGui")
            sg.Brightness = 5
            sg.LightInfluence = 1
            sg.Parent = p
            local imageLabel = Instance.new("ImageLabel") 
            imageLabel.BackgroundTransparency = 1
            imageLabel.ImageColor3 = Color3.fromRGB(255,150,150)
            imageLabel.Size = UDim2.fromScale(1, 1)
            imageLabel.Image = "rbxassetid://17266483161" --"rbxassetid://3696144972"
            imageLabel.Parent = sg
            -- local decal = Instance.new("Decal")
            -- decal.Texture = "rbxassetid://3696144972"
            -- decal.Parent = sg
            p.Parent = getEffectsFolder()
            
            local tween = TweenService:Create(sg, TweenInfo.new(2), {
                Brightness = 0;
                LightInfluence = 0
            })
            local tween2 = TweenService:Create(imageLabel, TweenInfo.new(markLifeTime), {
                ImageTransparency = 1
            })
            tween:Play(); tween:Destroy()
            tween2:Play(); tween:Destroy()

            task.delay(markLifeTime, function()
                p:Destroy()
            end)
            print(p)
        end
    end
    
    local function create3DMark()
        local p = Instance.new("Part")
        p.Size = Vector3.new(1,0.2,0.2)
        p.Anchored = true
        p.Shape = Enum.PartType.Cylinder
        p.CanCollide = false
		p.Transparency = 1
        p.CFrame = cf*CFrame.Angles(0, math.pi/2, 0)
        
        p.Parent = getEffectsFolder()
        local s, newSubtract: UnionOperation? = pcall(function() 
            if  (hit:GetAttribute("IsShot") or 0) < maxMarkCountPerHitInstance then 
                return hit:SubtractAsync({p})
            end
            error(`Shot more than {maxMarkCountPerHitInstance}!`)
        end)
        
        if s and newSubtract then 
            newSubtract.CFrame = hit.CFrame
            newSubtract.Parent = hit.Parent
            for _,v in pairs(hit:GetChildren()) do
                v:Clone().Parent = newSubtract
            end
            newSubtract:SetAttribute("IsShot", (hit:GetAttribute("IsShot") :: number? or 0) + 1)
            hit:Destroy()
        else
            local hitCloned = Instance.new"Part"
            hitCloned.TopSurface, hitCloned.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
            hitCloned.CFrame, hitCloned.Size = hit.CFrame, hit.Size
            hitCloned.Material, hitCloned.Color, hitCloned.CanCollide, hitCloned.Anchored = hit.Material, hit.Color, hit.CanCollide, hit.Anchored
            for _,v in pairs(hit:GetChildren()) do
                v:Clone().Parent = hitCloned
            end
            hitCloned.Parent = hit.Parent
            hit:Destroy()
        end
        p:Destroy()

        local offset = p.CFrame.RightVector*p.Size.X*0.5
        createDefaultMark(offset)
    end

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

    if hit:IsDescendantOf(workspace:WaitForChild("Assets"):WaitForChild("Destructibles")) then
        create3DMark()
    else
        createDefaultMark()
    end
    createFx()
end

function otherHumanoidHit(char : Model, hitPart : BasePart, hitCf : CFrame, healthDamage : number)
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
    local damage = if hitPart.Name == "Head" then healthDamage*3 else healthDamage

    assert(humanoid)
    humanoid.Health -= damage
    
    createFx()
end
    
function spawnBullet(weaponData : WeaponUtil.WeaponData, startCf : CFrame)
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
     p.Parent = getEffectsFolder()		

     local raycastParams = RaycastParams.new()
     raycastParams.FilterDescendantsInstances = {p, getEffectsFolder()}

     local overlapParams = OverlapParams.new()
     overlapParams.FilterDescendantsInstances = {p, getEffectsFolder()}
     --bullet init
     local gravity = Vector3.new(0, -workspace.Gravity, 0)

     local currentVelocity = p.CFrame.LookVector*weaponData.BulletSpeed
     
     _maid:GiveTask(RunService.Stepped:Connect(function(t, dt : number)
        currentVelocity = currentVelocity + gravity*dt

        local velocity = currentVelocity*dt
         local ray = if pcf then workspace:Raycast(pcf.Position, velocity, raycastParams) else nil
         local partsTouched = workspace:GetPartsInPart(p, overlapParams)

         p.CFrame = pcf + velocity
        --  p.AssemblyLinearVelocity = velocity/dt

         if ray then 
            local hit = ray.Instance
			local char = if hit.Parent and hit.Parent:FindFirstChild("Humanoid") then hit.Parent 
                elseif hit.Parent and hit.Parent.Parent and hit.Parent.Parent:FindFirstChild("Humanoid") then hit.Parent.Parent
            else nil
			
            if char then
				otherHumanoidHit(char :: Model, hit, CFrame.new(ray.Position, ray.Position + ray.Normal), weaponData.HealthDamage)
            else
                local lcf = CFrame.new(ray.Position, ray.Position + pcf.LookVector)
                onInstanceHit(hit, lcf)
			end
            currentVelocity -= currentVelocity*0.8
			--_maid:Destroy()
            pcf = CFrame.new(ray.Position)*(pcf - pcf.Position) + currentVelocity*dt
        elseif #partsTouched > 0 then
            currentVelocity -= currentVelocity*0.8
            pcf = pcf + currentVelocity*dt
        else
            pcf += velocity 
         end
         i += dt*10

        --  local p2 = Instance.new("Part")
        -- --  print(pcf.Position)
        --  p2.Position = p.Position
        --  p2.CanCollide = false
        --  p2.Anchored = true 
        --  p2.Parent = getEffectsFolder()

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
         if currentVelocity.Magnitude < 5 then 
            _maid:Destroy()
            return
         end
         if i >= 100 then
             _maid:Destroy()
             return 
         end

     end))

	-- _maid:GiveTask(p.Touched:Connect(function(hit : BasePart) 
	-- 	if hit.CanCollide and hit.Transparency < 1 then 
	-- 		local char = if hit.Parent and hit.Parent:FindFirstChild("Humanoid") then hit.Parent else nil
	-- 		if char then
	-- 			otherHumanoidHit(char :: Model, hit, pcf, weaponData.HealthDamage)
    --         else
    --             onInstanceHit(hit, pcf)
	-- 		end
	-- 		_maid:Destroy()
	-- 	end
	-- end))

    return p
end
function getWeaponFromPlayer(plr : Player) : Tool?
    local char = plr.Character
    assert(char)
    for _,v in pairs(char:GetChildren()) do 
        local weaponData = WeaponUtil.getWeaponDataByName(v.Name)
        if weaponData then 
            return v :: Tool
        end
    end
    return nil
end

function onGunShot(
    plr : Player,
    startCf :CFrame)    
    local gun = getWeaponFromPlayer(plr)
    assert(gun)
    local weaponData = WeaponUtil.getWeaponDataByName(gun.Name); assert(weaponData)
    local handle = gun:WaitForChild("GunMesh") :: BasePart
    local char = plr.Character
    assert(char and char.PrimaryPart)

    local shotTimeStampKey = "ShotTimestamp" 
    local lastShotTime = gun:GetAttribute(shotTimeStampKey) :: number? or (0)

    local function flashFx(adornee : Instance)
        local lifeTime = 0.09

        -- local inst = Instance.new("Part")
        -- inst.Transparency = 1
        -- inst.CanCollide, inst.Anchored = true, true
        -- inst.CFrame, inst.Size = startCf, Vector3.new(0,0,0)
        -- inst.Parent = workspace

        local bg = Instance.new("BillboardGui")
        bg.LightInfluence = 0
        bg.Brightness = 4
        bg.ExtentsOffsetWorldSpace = Vector3.new(0,0.5,-1)
        bg.Size = UDim2.fromScale(2.5, 2.5)
        bg.Parent = adornee

        local imageLabel = Instance.new("ImageLabel")
        imageLabel.Rotation = math.random(-180, 180)
        imageLabel.Size = UDim2.fromScale(1, 1)
        imageLabel.BackgroundTransparency = 1
        imageLabel.Image = "rbxassetid://233113663"
        imageLabel.Parent = bg
        local tween = TweenService:Create(imageLabel, TweenInfo.new(lifeTime), {
            ImageTransparency = 1
        })
        tween:Play()
        tween:Destroy()

        local light = Instance.new("SpotLight")
        light.Parent = adornee

        task.delay(lifeTime, function()
            bg:Destroy()
            light:Destroy()
        end)
    end
    local function shoot()
        startCf = clampBulletStartCFrame(char.PrimaryPart.CFrame, startCf)
        --NetworkUtil.fireAllClients(ON_PLAYER_AIM_DIRECTION_UPDATE, plr, shotPosCf)
        task.spawn(function()
            spawnBullet(weaponData, startCf) 
        end)
        flashFx(gun:WaitForChild("GunMesh"))

        NetworkUtil.fireClient(ON_WEAPON_SHOT_EFFECT, plr, weaponData)
        playSound(1905367471, handle, 2)
    end

    local weaponState = WeaponUtil.getWeaponState(gun)

    if (DateTime.now().UnixTimestampMillis/1000) - lastShotTime > weaponData.RateOfFire*0.99 then 
        if weaponState.AmmoRound > 0 then
            if not WeaponUtil.getPlayerState(plr).IsReloading then  
                gun:SetAttribute(shotTimeStampKey, (DateTime.now().UnixTimestampMillis/1000))
                shoot()
                
                weaponState.AmmoRound -= 1
                WeaponUtil.setWeaponState(gun, weaponState)
            end
        else
             --empty clip
            playSound(240785604, gun:WaitForChild("Handle"))
        end
    end
end

function onGunShotStart(
    plr : Player, 
    shotPosCf: CFrame -- temporary!
    )
    local char = plr.Character
    assert(char and char.PrimaryPart)
    local head = char:FindFirstChild("Head")
    assert(head)
    
    local gun = getWeaponFromPlayer(plr)
    assert(gun)
    local weaponData = WeaponUtil.getWeaponDataByName(gun.Name)
    assert(weaponData)
    local handle = gun:WaitForChild("GunMesh") :: BasePart
    local shotTimeStampKey = "ShotTimestamp" 
    
    
    local lastShotTime = handle:GetAttribute(shotTimeStampKey) :: number or (tick() - weaponData.RateOfFire)
    local t = lastShotTime 

    maid.Shoot = RunService.Stepped:Connect(function() 
        local timeNow = tick() 
    
        if weaponData.RateOfFire <= (timeNow - t) then --make this loop somehow
            t = tick()
            handle:SetAttribute(shotTimeStampKey, t)

            onGunShot(plr, shotPosCf)
        end
    end)
   
    return nil
end

function onGunShotEnd(plr : Player)
    maid.Shoot = nil
    return nil
end

function onReload(plr : Player)
    local gun = getWeaponFromPlayer(plr); assert(gun)
    local weaponData = WeaponUtil.getWeaponDataByName(gun.Name); assert(weaponData)
    local weaponState = WeaponUtil.getWeaponState(gun)
    local playerState = WeaponUtil.getPlayerState(plr)

    local function reloading()
        local bulletsReloaded = math.clamp((weaponData.AmmoRound - weaponState.AmmoRound), 0, playerState.AmmoCapacity)
        playerState.AmmoCapacity -= bulletsReloaded
        playerState.IsReloading = true
        weaponState.AmmoRound += bulletsReloaded
        WeaponUtil.setPlayerState(plr, playerState)
        WeaponUtil.setWeaponState(gun, weaponState) 

        playSound(4648872031, gun:WaitForChild("Handle"))
        NetworkUtil.invokeClient(ON_WEAPON_RELOAD_CLIENT, plr)

        local newPlayerState = WeaponUtil.getPlayerState(plr); newPlayerState.IsReloading = false
        WeaponUtil.setPlayerState(plr, newPlayerState)
    end

    if not playerState.IsReloading then
        if playerState.AmmoCapacity > 0 and weaponState.AmmoRound < weaponData.AmmoRound then 
            reloading()
        else
        
        end
    end
end

function sys.init(maid : Maid)
    local defaultAmmoCapacity = 0

    for _,v in pairs(CollectionService:GetTagged("Gun")) do
        local weaponData = WeaponUtil.getWeaponDataByName(v.Name)
        assert(weaponData)
        WeaponUtil.setWeaponData(
            v, 
            weaponData
        )
        local newWeaponState = WeaponUtil.createWeaponState(defaultAmmoCapacity)
        WeaponUtil.setWeaponState(v, newWeaponState)
    end
    
    maid:GiveTask(Players.PlayerAdded:Connect(onPlayerAdded))
    --networks
    maid:GiveTask(NetworkUtil.onServerEvent(ON_AIMING, function(plr : Player, aiming : boolean)  
        local gun = getWeaponFromPlayer(plr); assert(gun)
        local playerState = WeaponUtil.getPlayerState(plr)
        
        WeaponUtil.setPlayerState(plr, WeaponUtil.createPlayerState(
            aiming,
            playerState.IsReloading,
            playerState.AmmoCapacity
        ))
    end))

    maid:GiveTask(NetworkUtil.onServerEvent(ON_WEAPON_SHOT, onGunShot))
    maid:GiveTask(NetworkUtil.onServerEvent(ON_WEAPON_RELOAD, onReload))

    NetworkUtil.onServerInvoke(ON_WEAPON_SHOT_START, onGunShotStart)
    NetworkUtil.onServerInvoke(ON_WEAPON_SHOT_END, onGunShotEnd)

    NetworkUtil.getRemoteEvent(ON_WEAPON_EQUIP)
    NetworkUtil.getRemoteEvent(ON_PLAYER_AIM_DIRECTION_UPDATE)
    NetworkUtil.getRemoteEvent(ON_WEAPON_SHOT_EFFECT)
    NetworkUtil.getRemoteFunction(GET_CLIENT_WEAPON_STATE_INFO)
    NetworkUtil.getRemoteFunction(ON_WEAPON_RELOAD_CLIENT)

    --temporary!
    local proxprompt : ProximityPrompt = workspace.SpawnLocation.ProximityPrompt
    proxprompt.ActionText = "Add 10 Ammo"
    proxprompt.TriggerEnded:Connect(function(plr : Player)
        local plrState = WeaponUtil.getPlayerState(plr); plrState.AmmoCapacity += 10
        WeaponUtil.setPlayerState(plr, plrState)
    end)
end

return sys