--!strict
--services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
--packages
local _Packages = ReplicatedStorage:WaitForChild("Packages")

local Maid = require(_Packages:WaitForChild("Maid"))
local ColdFusion = require(_Packages:WaitForChild("ColdFusion8"))
local MathUtil = require(_Packages:WaitForChild("MathUtil"))
local InputHandler = require(_Packages:WaitForChild("InputHandler"))
local NetworkUtil = require(_Packages:WaitForChild("NetworkUtil"))
--modules
local WeaponData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WeaponData"))
--types
type Maid = Maid.Maid

type Fuse = ColdFusion.Fuse
type State<T> = ColdFusion.State<T>
type ValueState<T> = ColdFusion.ValueState<T>
type CanBeState<T> = ColdFusion.CanBeState<T>

type PlayerState = {
    IsAiming : boolean
}
--constants
local WALK_SPEED = 15
local JUMP_POWER = 50
--remotes
local ON_WEAPON_SHOT = "OnWeaponShot"
local ON_WEAPON_EQUIP = "OnWeaponEquip"

local ON_AIMING = "OnAiming"
local ON_PLAYER_AIM_DIRECTION_UPDATE = "OnPlayerAimDirectionUpdate"

local GET_CLIENT_WEAPON_STATE_INFO = "GetClientWeaponStateInfo"
--variables
local camFOV = 70
--references
local Player = Players.LocalPlayer
local UITarget = Player:WaitForChild("PlayerGui"):WaitForChild("ScreenGui")
--local functions
local function freezePlayer()
    local character = Player.Character or Player.CharacterAdded:Wait()
    character.Humanoid.WalkSpeed = 0
    character.Humanoid.JumpPower = 0
end
local function thawPlayer()
    local character = Player.Character or Player.CharacterAdded:Wait()
    character.Humanoid.WalkSpeed = WALK_SPEED
    character.Humanoid.JumpPower = JUMP_POWER
end
--class
local sys = {}

local _isAiming = false
local _camOffset = Vector3.new()
local _camRotOffset = Vector3.new()

function setCamOffset(offset : Vector3)
    _camOffset = offset
end
function getCamOffset()
    return _camOffset
end
function setCamRotOffset(offset : Vector3)
    _camRotOffset = offset
end
function getCamRotOffset()
    return _camRotOffset
end
function getPlayerState(plr : Player) : PlayerState
    return {
        IsAiming = plr:GetAttribute("IsAiming") :: boolean,
    }
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

function sys.onWeaponEquipped(gun : Tool)
    if gun:IsA("Tool") then
        local _maid = Maid.new()

        local _fuse = ColdFusion.fuse(_maid)
        local _new = _fuse.new
        local _import = _fuse.import
        local _bind = _fuse.bind
        local _clone = _fuse.clone
        local _Computed = _fuse.Computed
        local _Value = _fuse.Value

        
        local char = if gun.Parent and Players:GetPlayerFromCharacter(gun.Parent) then gun.Parent :: Model else nil; assert(char and char.PrimaryPart)
        local humanoid = char:FindFirstChild("Humanoid") :: Humanoid;  assert(humanoid)
        local handle = gun:FindFirstChild("GunMesh") :: BasePart? ;assert(handle)
       
        local camera = if char == Player.Character then workspace.CurrentCamera else nil

        local leftLowerArm,leftUpperArm, leftHand, 
        rightLowerArm, rightUpperArm, rightHand = char:FindFirstChild("LeftLowerArm") :: BasePart, 
            char:FindFirstChild("LeftUpperArm") :: BasePart, 
            char:FindFirstChild("LeftHand") :: BasePart, 
            char:FindFirstChild("RightLowerArm") :: BasePart, 
            char:FindFirstChild("RightUpperArm") :: BasePart,
            char:FindFirstChild("RightHand") :: BasePart
		assert(leftLowerArm and leftUpperArm and leftHand and  rightLowerArm and rightUpperArm and rightHand)
        local head  = char:FindFirstChild("Head") :: BasePart?; assert(head)
        local humanoidRootPart = char:FindFirstChild("HumanoidRootPart") :: BasePart?; assert(humanoidRootPart)

        local leftShoulder, leftElbow, rightShoulder, rightElbow = leftUpperArm:FindFirstChild("LeftShoulder") :: Motor6D,
            leftLowerArm:FindFirstChild("LeftElbow") :: Motor6D,
            rightUpperArm:FindFirstChild("RightShoulder") :: Motor6D,
            rightLowerArm:FindFirstChild("RightElbow") :: Motor6D

		local animator = humanoid:WaitForChild("Animator") :: Animator
		
		local a_l = leftLowerArm.Size.Y
		local b_l = leftUpperArm.Size.Y
		
		local a_r = rightLowerArm.Size.Y
		local b_r = rightUpperArm.Size.Y
		
		local weld = _maid:GiveTask(Instance.new("Weld")) --rightHand:WaitForChild("WeaponWeld") :: Weld --Instance.new("Weld")
		weld.Part0 = handle
		weld.Part1 = rightHand
		weld.C0 = CFrame.new()
			--*CFrame.new(0,0,handle.Size.Z*0.5)
			--*CFrame.Angles(math.pi/2, 0, 0)
		weld.C1 = CFrame.new()
			*CFrame.Angles(math.pi, 0, 0) --weld.Part1.CFrame:Inverse()*(weld.Part0.CFrame*weld.C0)
		weld.Parent = rightHand
		
        if camera then 
            Player.CameraMode = Enum.CameraMode.LockFirstPerson
            humanoid.CameraOffset = Vector3.new(0, 0, -1) 
        end
		for i, v in pairs(char:GetChildren()) do
			if v:IsA("BasePart") and v.Name ~= "Head" then

				v:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
					v.LocalTransparencyModifier = v.Transparency
				end)

				v.LocalTransparencyModifier = v.Transparency
			end
		end
		
		local animateScript = char:WaitForChild("Animate")
        local runAnim  = animateScript:WaitForChild("run"):WaitForChild("RunAnim") :: Animation
        local walkAnim  = animateScript:WaitForChild("walk"):WaitForChild("WalkAnim") :: Animation

		local function customInverseKinematicsCfAndAngles(a : number, b : number, startV3 : Vector3, targetV3 : Vector3): (CFrame, number, number, number)
            local c = math.clamp((startV3 - targetV3).Magnitude, 0, (a + b))
            --local handDestPos = if (startV3 - targetV3).Magnitude > a + b then startV3 + (targetV3 - startV3).Unit*c else targetV3
			local A = math.acos((-(a^2) + b^2 + c^2)/(2*b*c))
			local B = math.acos((a^2 - b^2 + c^2)/(2*a*c))
			local C = math.acos((a^2 + b^2 - c^2)/(2*a*b))

            local cf = 	CFrame.new(startV3, targetV3)  
            cf = ((CFrame.new(startV3)*(char.PrimaryPart.CFrame - char.PrimaryPart.CFrame.Position)):ToObjectSpace(cf))*CFrame.Angles(math.pi/2,0,0)
			cf -= cf.Position
            return cf, A, B, C
		end

        local function resetJoints()
            leftShoulder.C0, leftElbow.C0, rightShoulder.C0, rightElbow.C0 = CFrame.new(leftShoulder.C0.Position),  CFrame.new(leftElbow.C0.Position), CFrame.new(rightShoulder.C0.Position), CFrame.new(rightElbow.C0.Position)
        end


        local function createAim()
            local out = _new("Frame")({
                AnchorPoint = Vector2.new(0.5,0.5),
                Size = UDim2.new(0, 15,0,15),
                Parent = UITarget,
                Children = {
                    _new("UICorner")({
                        CornerRadius = UDim.new(1, 0)
                    })
                }
            }) :: Frame
            return out
        end
        local function cleanup()
            _maid:Destroy()

          
            if camera then 
                runAnim.AnimationId = "rbxassetid://913376220"
                walkAnim.AnimationId = "rbxassetid://913376220"
        
                humanoid.CameraOffset = Vector3.new()

                Player.CameraMode = Enum.CameraMode.Classic

                freezePlayer()
                task.wait(0.15)
                thawPlayer()

                camera.FieldOfView = camFOV
            end
            resetJoints()
        end
        local function getIsAiming()
            local plr = Players:GetPlayerFromCharacter(char)
            assert(plr)
            local isAiming =  getPlayerState(plr).IsAiming
            return isAiming
        end
        
        local aimFrame 
        if camera then 
            aimFrame = createAim()
            freezePlayer()
            task.wait(0.15)
            thawPlayer()
            runAnim.AnimationId = "rbxassetid://18908827149"
            walkAnim.AnimationId = "rbxassetid://18908827149"
        
            for _,v in pairs(animator:GetPlayingAnimationTracks()) do
                v:Stop(0)
            end
            resetJoints()
        end
		_maid:GiveTask(RunService.Stepped:Connect(function()
			if camera then 
                humanoid.CameraOffset = humanoidRootPart.CFrame:VectorToObjectSpace(camera.CFrame.UpVector*head.Size.Y*0.75 + camera.CFrame.LookVector*head.Size.Z*0.5 + getCamOffset()) --Vector3.new(0,char.Head.Size.Y*0.25,-char.Head.Size.Z)
			    camera.CFrame *= CFrame.Angles(getCamRotOffset().X, getCamRotOffset().Y, getCamOffset().Z)
            end

			local leftTorsoToArmPos = leftUpperArm.CFrame*(Vector3.new(0,leftUpperArm.Size.Y*0.5,0)) 
			local rightTorsoToArmPos = rightUpperArm.CFrame*(Vector3.new(0,rightUpperArm.Size.Y*0.5,0)) 
			
			local deg = math.acos(((-(char.PrimaryPart.CFrame.LookVector*handle.Size.Z) + (rightTorsoToArmPos - char.PrimaryPart.Position) + Vector3.new(0, -1, 0)) ).Unit:Dot(-(char.PrimaryPart.CFrame.LookVector*handle.Size.Z).Unit))
			local directionSourceCf =  if getIsAiming() then ((if camera then camera.CFrame else head.CFrame)*CFrame.new(0, -handle.Size.Y, 0))
				else (char.PrimaryPart.CFrame*CFrame.Angles(-deg, 0, 0))
			
			--local destPos : Vector3 = directionSourceCf*Vector3.new(0, if getIsAiming() then -handle.Size.Y*0.5 else 0, -handle.Size.Z)
			local destPos = directionSourceCf*Vector3.new(0, 0, -handle.Size.Z*0.5)	
            local rayRange = 1000
            local ray = workspace:Raycast(handle.CFrame*Vector3.new(0,0,handle.Size.Z*-0.5), handle.CFrame.LookVector*rayRange)
            local aimWorldPos = if ray then ray.Position else nil

			local c_l = math.clamp((leftTorsoToArmPos - destPos).Magnitude, 0, (a_l + b_l))
			local c_r = math.clamp((rightTorsoToArmPos - destPos).Magnitude, 0, (a_r + b_r))

			for _,v in pairs(animator:GetPlayingAnimationTracks()) do
				if not v.Name:lower():find("walk") and not v.Name:lower():find("run") then  
				    v:Stop(0)
				end
			end
			
			local handDestPos = if (rightTorsoToArmPos - destPos).Magnitude > a_r + b_r then rightTorsoToArmPos + (destPos - rightTorsoToArmPos).Unit*c_r else destPos
			
            local cfrot_l, A_l, B_l, C_l = customInverseKinematicsCfAndAngles(a_l, b_l, leftTorsoToArmPos, handDestPos)
            local cfrot_r, A_r, B_r, C_r = customInverseKinematicsCfAndAngles(a_r, b_r, rightTorsoToArmPos, handDestPos)
          
            --hand dest pos check
			weld.C1 = weld.C1:Lerp(
				rightHand.CFrame:Inverse()*directionSourceCf*CFrame.new(0,0, -handle.Size.Z*0.5), 
				0.3
			)
			leftShoulder.C0 = leftShoulder.C0:Lerp(
				CFrame.new(leftShoulder.C0.Position)*cfrot_l*CFrame.Angles(-A_l, 0, 0), 0.3
			)
			leftElbow.C0 = leftElbow.C0:Lerp(
				CFrame.new(leftElbow.C0.Position)*CFrame.Angles(-C_l + math.rad(180), 0, 0), 0.3
			)
			
			rightShoulder.C0 = rightShoulder.C0:Lerp(
				CFrame.new(rightShoulder.C0.Position)*cfrot_r*CFrame.Angles(-A_r, 0, 0), 0.3
			)
			rightElbow.C0 = rightElbow.C0:Lerp(
				CFrame.new(rightElbow.C0.Position)*CFrame.Angles(-C_r + math.rad(180) ,0, 0), 0.3
			) 
			
            if camera and aimFrame then 
                if getIsAiming() then
                    camera.FieldOfView = MathUtil.lerp(camera.FieldOfView , camFOV*1.04, 0.25)
                else
                    camera.FieldOfView = MathUtil.lerp(camera.FieldOfView*1.04, camFOV, 0.25)
                end

                local hitV3 = aimWorldPos or (handle.Position + handle.CFrame.LookVector*rayRange)
                local screenV3 = camera:WorldToViewportPoint(hitV3)
                aimFrame.Visible = getIsAiming()
                aimFrame.Position = UDim2.fromOffset(screenV3.X, screenV3.Y) 
            end
            -- local p = Instance.new("Part")
            -- p.CanCollide = false 
            -- p.Size = Vector3.one*1
            -- p.Transparency = 0.5
            -- p.Position = destPos
            -- p.Anchored = true
            -- p.Parent = workspace
            -- task.delay(0.1, function()
            --     p:Destroy()
            -- end)
		end))
		
		_maid:GiveTask(gun.AncestryChanged:Connect(function()
            local plrEquipping = if gun.Parent then Players:GetPlayerFromCharacter(gun.Parent) else nil 
            if not plrEquipping then
                cleanup()
            end
		end))
        
	end
end

function onCharAdded(char : Model)
    local _maid = Maid.new()
    
    _maid:GiveTask(char.ChildAdded:Connect(function(weapon : Instance)
        if weapon:IsA("Tool") then
            sys.onWeaponEquipped(weapon)
        end
    end))

    _maid:GiveTask(char.AncestryChanged:Connect(function()
        if char.Parent == nil then
            _maid:Destroy()
        end
    end))
end

function onPlayerAdded(plr : Player)
    local _maid = Maid.new()

    onCharAdded(plr.Character or plr.CharacterAdded:Wait())
    _maid:GiveTask(plr.CharacterAdded:Connect(onCharAdded))
    _maid:GiveTask(plr.AncestryChanged:Connect(function() 
        if plr.Parent == nil then 
            _maid:Destroy()
        end
    end))
end

function shoot(weapon : Tool)
    local conn
    local i = 0

    local camera = workspace.CurrentCamera
    local handle = weapon:FindFirstChild("GunMesh") :: BasePart?; assert(handle)
    
    camera.CFrame = camera.CFrame*CFrame.Angles(math.rad(math.random(2,5)), 0, 0)

    local offsetAmp = math.random(1, 3)/10
    local rotOffsetAmp = math.random(10, 40)/1000

    conn = RunService.Stepped:Connect(function()
        i += 0.3
        setCamOffset(Vector3.new(-math.sin(i)*offsetAmp, 0, 0))
        setCamRotOffset(Vector3.new(math.sin(i*2)*rotOffsetAmp, 0, 0))
        if i >= math.pi then
            if conn then conn:Disconnect() end
            setCamOffset(Vector3.new(0, 0, 0))
            setCamRotOffset(Vector3.new(0, 0, 0))
        end
    end)
    NetworkUtil.fireServer(ON_WEAPON_SHOT, handle.CFrame*CFrame.new(0,0,-handle.Size.Z*0.5))
    --spawnBullet(handle.CFrame*CFrame.new(0,0,-handle.Size.Z*0.5))
end

function sys.init(maid : Maid)
    local _maid = maid:GiveTask(Maid.new())
    local inputHandler = maid:GiveTask(InputHandler.new())

    local function onGunActivatedEvent()
        local char = Player.Character
        assert(char)
        local weapon = getWeaponFromPlayer(Player)
        assert(weapon)
        local handle = weapon:FindFirstChild("GunMesh") :: BasePart?; assert(handle)

        do
            local t = 0
            _maid.Shoot = RunService.Stepped:Connect(function(_, dt : number)
                if t >= 0.25 then 
                    t = 0
                    shoot(weapon)
                end
                t += dt
            end)
            shoot(weapon)
        end
    end
    local function onAim(isAiming : boolean)
        NetworkUtil.fireServer(ON_AIMING, isAiming)
    end

    local function updateHeadDirection(plr : Player, directionCf: CFrame)
        local char = plr.Character; assert(char and char.PrimaryPart)
        local head = char:FindFirstChild("Head") :: BasePart?; assert(head)

        local neck = head:FindFirstChild("Neck") :: Motor6D?; assert(neck)

        local relativeOrientation = (char.PrimaryPart.CFrame:Inverse()*directionCf) - (char.PrimaryPart.CFrame:Inverse()*directionCf).Position
        neck.C0 = CFrame.new(neck.C0.Position)*relativeOrientation
    end

    inputHandler:Map("OnGunActivatedEventPC", "Keyboard", {Enum.UserInputType.MouseButton1}, "Hold", function() 
        onGunActivatedEvent()
    end, function() 
        _maid.Shoot = nil
    end)

    inputHandler:Map("OnGunAim1PC", "Keyboard", {Enum.UserInputType.MouseButton2}, "Hold", function()
        onAim(true)
    end, function() 
        onAim(false)
    end)
    inputHandler:Map("OnGunAim2PC", "Keyboard", {Enum.UserInputType.MouseButton1}, "Hold", function()
        onAim(true)
    end, function() 
        if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            onAim(false)
        end
    end)

    maid:GiveTask(NetworkUtil.onClientEvent(ON_PLAYER_AIM_DIRECTION_UPDATE, function(otherPlr : Player, dirCf : CFrame) 
        if otherPlr ~= Player then
            updateHeadDirection(otherPlr, dirCf)
        end
    end))

    NetworkUtil.onClientInvoke(GET_CLIENT_WEAPON_STATE_INFO, function()
        local camera = workspace.CurrentCamera
        assert(camera)
        return {
            CFrame = camera.CFrame,
            IsAiming = getPlayerState(Player).IsAiming
        }
    end)

    -- maid:GiveTask(NetworkUtil.onClientEvent(ON_WEAPON_EQUIP, function(plrEquipping : Player) 
    --     if plrEquipping == Player then return end 
    -- end))

    for _, plr : Player in pairs(Players:GetPlayers()) do 
        onPlayerAdded(plr)
    end

    maid:GiveTask(Players.PlayerAdded:Connect(onPlayerAdded))
 
end

return sys