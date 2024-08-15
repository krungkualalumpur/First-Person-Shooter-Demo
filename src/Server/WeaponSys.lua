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

type WeaponData = WeaponData.WeaponData
--constants
--remotes
local ON_WEAPON_SHOT = "OnWeaponShot"
local ON_WEAPON_EQUIP = "OnWeaponEquip"

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
            local handle = child:FindFirstChild("GunMesh") :: BasePart? ;assert(handle)
     
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

            -- local a_l = leftLowerArm.Size.Y
            -- local b_l = leftUpperArm.Size.Y
            
            -- local a_r = rightLowerArm.Size.Y
            -- local b_r = rightUpperArm.Size.Y

            -- local weld = _toolMaid:GiveTask(Instance.new("Weld")) :: Weld --Instance.new("Weld")
            -- weld.Name = "WeaponWeld"
            -- weld.Part0 = handle
            -- weld.Part1 = rightHand
            -- weld.C0 = CFrame.new()
            -- weld.C1 = CFrame.new()
            -- weld.Parent = rightHand

            -- local function customInverseKinematicsCfAndAngles(a : number, b : number, startV3 : Vector3, targetV3 : Vector3): (CFrame, number, number, number)
            --     local c = math.clamp((startV3 - targetV3).Magnitude, 0, (a + b))
            --     --local handDestPos = if (startV3 - targetV3).Magnitude > a + b then startV3 + (targetV3 - startV3).Unit*c else targetV3
            --     local A = math.acos((-(a^2) + b^2 + c^2)/(2*b*c))
            --     local B = math.acos((a^2 - b^2 + c^2)/(2*a*c))
            --     local C = math.acos((a^2 + b^2 - c^2)/(2*a*b))

            --     local cf = 	CFrame.new(startV3, targetV3)  
            --     cf = ((CFrame.new(startV3)*(char.PrimaryPart.CFrame - char.PrimaryPart.CFrame.Position)):ToObjectSpace(cf))*CFrame.Angles(math.pi/2,0,0)
            --     cf -= cf.Position
            --     return cf, A, B, C
            -- end
            local function resetJoints()
                leftShoulder.C0, leftElbow.C0, rightShoulder.C0, rightElbow.C0 = CFrame.new(leftShoulder.C0.Position),  CFrame.new(leftElbow.C0.Position), CFrame.new(rightShoulder.C0.Position), CFrame.new(rightElbow.C0.Position)
            end
            local function cleanup()
                _toolMaid:Destroy()   
                resetJoints()
            end
            
            -- local t = 2
            -- _toolMaid:GiveTask(RunService.Stepped:Connect(function(_, dt : number)
            --     if t > 1 then 
            --         local info : ClientWeaponState = NetworkUtil.invokeClient(GET_CLIENT_WEAPON_STATE_INFO, plr)
                    
            --         t = 0

            --         local leftTorsoToArmPos = leftUpperArm.CFrame*(Vector3.new(0,leftUpperArm.Size.Y*0.5,0)) 
            --         local rightTorsoToArmPos = rightUpperArm.CFrame*(Vector3.new(0,rightUpperArm.Size.Y*0.5,0)) 
                   
            --         local deg = math.acos(((-(char.PrimaryPart.CFrame.LookVector*handle.Size.Z) + (rightTorsoToArmPos - char.PrimaryPart.Position) + Vector3.new(0, -1, 0)) ).Unit:Dot(-(char.PrimaryPart.CFrame.LookVector*handle.Size.Z).Unit))

            --         local directionSourceCf = if info.IsAiming then info.CFrame*CFrame.new(0, -handle.Size.Y*0.75, 0)
			-- 	            else (char.PrimaryPart.CFrame*CFrame.Angles(-deg, 0, 0))
            --         -- local directionSourceCf =  
                   
            --         weld.C1 = ((rightHand.CFrame:Inverse()*(directionSourceCf*CFrame.new(0,0, if info.IsAiming then -handle.Size.Z else -handle.Size.Z*0.5))))

            --         local c_l = math.clamp((leftTorsoToArmPos - handle.Position).Magnitude, 0, (a_l + b_l))
            --         local c_r = math.clamp((rightTorsoToArmPos - handle.Position).Magnitude, 0, (a_r + b_r))

            --         local handDestPos = handle.Position-- if (rightTorsoToArmPos - handle.Position).Magnitude > a_r + b_r then rightTorsoToArmPos + (handle.Position - rightTorsoToArmPos).Unit*c_r else handle.Position
                    
            --         local cfrot_l, A_l, B_l, C_l = customInverseKinematicsCfAndAngles(a_l, b_l, leftTorsoToArmPos, handDestPos)
            --         local cfrot_r, A_r, B_r, C_r = customInverseKinematicsCfAndAngles(a_r, b_r, rightTorsoToArmPos, handDestPos)
                    
            --         leftShoulder.C0 = CFrame.new(leftShoulder.C0.Position)*cfrot_l*CFrame.Angles(-A_l, 0, 0)
                    
            --         leftElbow.C0 = CFrame.new(leftElbow.C0.Position)*CFrame.Angles(-C_l + math.rad(180), 0, 0)
            --         rightShoulder.C0 = CFrame.new(rightShoulder.C0.Position)*cfrot_r*CFrame.Angles(-A_r, 0, 0)
                    
            --         rightElbow.C0 =  CFrame.new(rightElbow.C0.Position)*CFrame.Angles(-C_r + math.rad(180) ,0, 0)         
            --     end
            --     t += dt 
            -- end))
          
           
            _toolMaid:GiveTask(child.AncestryChanged:Connect(function()
                if not child:IsAncestorOf(char) then
                    print('krinappu')
                    cleanup()
                end
            end))
        end
    end

    local function onChildRemoved(child : Instance)
        -- local weaponData 
        -- pcall(function()
        --     weaponData = WeaponData.getWeaponDataByName(child.Name) 
        -- end)
        -- if weaponData then
        --     assert(child:IsA("Tool"))
        --     local leftLowerArm,leftUpperArm, leftHand, 
        --     rightLowerArm, rightUpperArm, rightHand = char:FindFirstChild("LeftLowerArm") :: BasePart, 
        --         char:FindFirstChild("LeftUpperArm") :: BasePart, 
        --         char:FindFirstChild("LeftHand") :: BasePart, 
        --         char:FindFirstChild("RightLowerArm") :: BasePart, 
        --         char:FindFirstChild("RightUpperArm") :: BasePart,
        --         char:FindFirstChild("RightHand") :: BasePart
        --     assert(leftLowerArm and leftUpperArm and leftHand and  rightLowerArm and rightUpperArm and rightHand)
        
        --     for _,v in pairs(rightHand:GetChildren()) do
        --         if v:IsA("Weld") and v.Part0 and v.Part0:IsDescendantOf(child) then
        --             v:Destroy()
        --         end
        --     end
        --     child:PivotTo(CFrame.new())
        -- end
    end

    _maid:GiveTask(char.ChildAdded:Connect(onChildAdded))
    _maid:GiveTask(char.ChildRemoved:Connect(onChildRemoved))

    _maid:GiveTask(char.AncestryChanged:Connect(function()
        if char.Parent == nil then
            _maid:Destroy()
        end
    end))
end
function onPlayerAdded(plr : Player)
    local _maid = Maid.new()
    
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

function otherHumanoidHit(char : Model, hitCf : CFrame)
    local function createFx()
        local p = Instance.new("Part")
        p.Anchored = true
        p.CanCollide = false
		p.Transparency = 1
        p.CFrame = hitCf
        p.Parent = getEffectsFolder()

        local smoke = Instance.new("Smoke")
        smoke.Color = Color3.fromRGB(255,50,50)
        smoke.Size = 1.5
        smoke.Opacity = 1
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
            print("Destroyah!")
        end)
        print(p)
    end

    local plr = Players:GetPlayerFromCharacter(char)
    local humanoid = char:FindFirstChild("Humanoid") :: Humanoid?
    assert(humanoid)
    humanoid.Health -= 10
    createFx()
end
    
function spawnBullet(startCf : CFrame)
    local _maid = Maid.new()
    local range = 1000
    local pcf  = startCf

    local i = 0

    --local ray = workspace:Raycast(startCf.Position, startCf.LookVector*range)
    --local travelTime : number, hitPos : Vector3, hitInstance : Instance? = range/2856.8, startCf.Position + startCf.LookVector*range, nil
    --if ray then 
    --    hitPos, hitInstance = ray.Position, ray.Instance
    --    travelTime = ray.Distance/2856.8
    --end

    --_maid:GiveTask(RunService.Stepped:Connect(function(t, dt : number)
    --    i += dt
    --    if i >= travelTime then
    --        _maid:Destroy()

    --        if hitInstance and hitInstance:IsA("BasePart") then 
    --            local plrHit = game.Players:GetPlayerFromCharacter(hitInstance.Parent)
    --            local _char = hitInstance.Parent
    --            if plrHit then
    --                otherPlayerHit(plrHit)
    --                return
    --            end
    --            onInstanceHit(hitInstance, CFrame.new(hitPos)*(hitInstance.CFrame - hitInstance.CFrame.Position))
    --        end
    --    end
    --end))

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
			local char = if hit.Parent and hit.Parent:FindFirstChild("Humanoid") then hit.Parent else nil
			if char then
				otherHumanoidHit(char :: Model, CFrame.new(ray.Position, ray.Position + ray.Normal))
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
				otherHumanoidHit(char :: Model, pcf)
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
    local startCf = clampBulletStartCFrame(char.PrimaryPart.CFrame, shotPosCf)
    local gun = getWeaponFromPlayer(plr)
    assert(gun)
    -- local weaponData = WeaponData.getWeaponData(gun)
    -- local t = 0
    local _maid = Maid.new()

    local handle = gun:WaitForChild("GunMesh") :: BasePart
    
  	local bullet =  spawnBullet(startCf)
	--  bullet:SetNetworkOwner(plr)
	
    playSound(1905367471, handle, 2)
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
    maid:GiveTask(NetworkUtil.onServerEvent(ON_WEAPON_SHOT, onGunShot))

    NetworkUtil.getRemoteEvent(ON_WEAPON_EQUIP)
    NetworkUtil.getRemoteFunction(GET_CLIENT_WEAPON_STATE_INFO)
    
end

return sys