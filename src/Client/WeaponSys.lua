--!strict
--services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
--packages
local _Packages = ReplicatedStorage:WaitForChild("Packages")

local Maid = require(_Packages:WaitForChild("Maid"))
local ColdFusion = require(_Packages:WaitForChild("ColdFusion8"))
local MathUtil = require(_Packages:WaitForChild("MathUtil"))
local InputHandler = require(_Packages:WaitForChild("InputHandler"))
--modules
--types
type Maid = Maid.Maid

type Fuse = ColdFusion.Fuse
type State<T> = ColdFusion.State<T>
type ValueState<T> = ColdFusion.ValueState<T>
type CanBeState<T> = ColdFusion.CanBeState<T>
--constants
local WALK_SPEED = 15
local JUMP_POWER = 50
--remotes
--variables
local camFOV = 70
--references
local Player = Players.LocalPlayer
local UITarget = Player:WaitForChild("PlayerGui"):WaitForChild("ScreenGui")
--local functions
--class
local sys = {}

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

function otherPlayerHit(plr : Player)
	
end

function onInstanceHit(hit : BasePart, cf : CFrame)
    local p = Instance.new("Part")
    p.Anchored = true
    p.Transparency = 1
    p.CFrame = cf
    p.Parent = hit.Parent
    local smoke = Instance.new("Smoke")
    smoke.Size = 2
    smoke.Opacity = 0.06
    smoke.Parent = p
    task.delay(0.4, function()
        smoke.Enabled = false 
        task.delay(3, function()
            smoke:Destroy()
            p:Destroy()
        end)
    end)
end

function getWeaponFromPlayer(plr : Player)
    local char = Player.Character
    local gun = char:FindFirstChild("Gun") :: Tool?
    return if gun and gun:FindFirstChild("Handle") then gun else nil
end

function spawnBullet(startCf : CFrame)
    local _maid = Maid.new()

    local p = _maid:GiveTask(Instance.new("Part"))
    p.Anchored = true
    p.CanCollide = true
    p.Size = Vector3.new(0.2,0.2,1)
    p.CFrame = startCf-- handle.CFrame + handle.CFrame.LookVector*handle.Size.Y
    p.Material = Enum.Material.Neon
    p.Parent = workspace		

    --bullet init
    local i = 0
    _maid:GiveTask(RunService.Stepped:Connect(function(t, dt : number)
        i += dt*10
        p.CFrame += p.CFrame.LookVector*3
        local parts = workspace:GetPartsInPart(p)
        if #parts > 0 then
            for _,v in pairs(parts) do
                local plrHit = game.Players:GetPlayerFromCharacter(v.Parent)
                local _char = v.Parent
                if plrHit then
                    otherPlayerHit(plrHit)
                    return
                end
                onInstanceHit(v, p.CFrame)
            end
            _maid:Destroy() 
        end
        if i >= 100 then
            _maid:Destroy()
        end
    end))

    return p
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

        local camera = workspace.CurrentCamera
        
        local char = if gun.Parent and Players:GetPlayerFromCharacter(gun.Parent) then gun.Parent :: Model else nil; assert(char and char.PrimaryPart)
        local humanoid = char:FindFirstChild("Humanoid") :: Humanoid;  assert(humanoid)
        local handle = gun:FindFirstChild("Handle") :: BasePart? ;assert(handle)

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
		
		local weld = Instance.new("Weld")
		weld.Part0 = handle
		weld.Part1 = rightHand
		weld.C0 = CFrame.new()
			--*CFrame.new(0,0,handle.Size.Z*0.5)
			--*CFrame.Angles(math.pi/2, 0, 0)
		weld.C1 = CFrame.new()
			--*CFrame.Angles(math.pi, 0, 0) --weld.Part1.CFrame:Inverse()*(weld.Part0.CFrame*weld.C0)
		weld.Parent = rightHand
		
		
		Player.CameraMode = Enum.CameraMode.LockFirstPerson
		humanoid.CameraOffset = Vector3.new(0, 0, -1) 
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

            runAnim.AnimationId = "rbxassetid://913376220"
		    walkAnim.AnimationId = "rbxassetid://913376220"

            humanoid.CameraOffset = Vector3.new()

            Player.CameraMode = Enum.CameraMode.Classic

            resetJoints()

            camera.FieldOfView = camFOV
        end
        
        local aimFrame = createAim()

        freezePlayer()
        task.wait(0.15)
        thawPlayer()
        runAnim.AnimationId = "rbxassetid://18908827149"
		walkAnim.AnimationId = "rbxassetid://18908827149"
	
        for _,v in pairs(animator:GetPlayingAnimationTracks()) do
            v:Stop(0)
        end
        resetJoints()
        
		_maid:GiveTask(RunService.Stepped:Connect(function()
			humanoid.CameraOffset = humanoidRootPart.CFrame:VectorToObjectSpace(camera.CFrame.UpVector*head.Size.Y*0.75 + camera.CFrame.LookVector*head.Size.Z*0.5 + getCamOffset()) --Vector3.new(0,char.Head.Size.Y*0.25,-char.Head.Size.Z)
			camera.CFrame *= CFrame.Angles(getCamRotOffset().X, getCamRotOffset().Y, getCamOffset().Z)
        
			local isAiming = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
			
			local rh_cf = char.PrimaryPart.CFrame:ToObjectSpace(rightHand.CFrame)
			local x, y, z = rh_cf:ToOrientation()
			
			local leftTorsoToArmPos = leftUpperArm.CFrame*(Vector3.new(0,leftUpperArm.Size.Y*0.5,0)) 
			local rightTorsoToArmPos = rightUpperArm.CFrame*(Vector3.new(0,rightUpperArm.Size.Y*0.5,0)) 
			
			local deg = math.acos(((-(char.PrimaryPart.CFrame.LookVector*handle.Size.Z) + (rightTorsoToArmPos - char.PrimaryPart.Position) + Vector3.new(0, -1, 0)) ).Unit:Dot(-(char.PrimaryPart.CFrame.LookVector*handle.Size.Z).Unit))
			local directionSourceCf =  if isAiming then camera.CFrame*CFrame.new(0, -handle.Size.Y*0.5, 0)
				else (char.PrimaryPart.CFrame*CFrame.Angles(-deg, 0, 0))
			
			local destPos : Vector3 = directionSourceCf*Vector3.new(0, if isAiming then -handle.Size.Y*0.5 else 0, -handle.Size.Z)
				
            local rayRange = 1000
            local ray = workspace:Raycast(handle.CFrame*Vector3.new(0,0,handle.Size.Z*-0.5), handle.CFrame.LookVector*rayRange)
            local aimWorldPos = if ray then ray.Position else nil

			weld.C1 = weld.C1:Lerp(
				CFrame.new(0,-handle.Size.Z*0.5,0)*((rightHand.CFrame:Inverse()*(directionSourceCf)) - (rightHand.CFrame:Inverse()*(directionSourceCf)).Position), 
				0.3
			)
		
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
			
			if isAiming then
				camera.FieldOfView = MathUtil.lerp(camera.FieldOfView , camFOV*1.04, 0.25)
			else
				camera.FieldOfView = MathUtil.lerp(camera.FieldOfView*1.04, camFOV, 0.25)
			end

            local hitV3 = aimWorldPos or (handle.Position + handle.CFrame.LookVector*rayRange)
            local screenV3 = camera:WorldToViewportPoint(hitV3)
            aimFrame.Visible = isAiming
            aimFrame.Position = UDim2.fromOffset(screenV3.X, screenV3.Y) 

            -- local p = Instance.new("Part")
            -- p.Position = hitV3
            -- p.Anchored = true
            -- p.Parent = workspace
            -- task.delay(0.1, function()
            --     p:Destroy()
            -- end)
		end))
		
		_maid:GiveTask(gun.AncestryChanged:Connect(function()
            if not Player.Character or not gun:IsAncestorOf(Player.Character) then
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

function shoot(weapon : Tool)
    local conn
    local i = 0

    local camera = workspace.CurrentCamera
    local handle = weapon:FindFirstChild("Handle") :: BasePart?; assert(handle)
    
    camera.CFrame = camera.CFrame*CFrame.Angles(math.rad(3), 0, 0)

    conn = RunService.Stepped:Connect(function()
        i += 0.3
        setCamOffset(Vector3.new(-math.sin(i)*0.2, 0, 0))
        setCamRotOffset(Vector3.new(math.sin(i*2)*0.035, 0, 0))
        if i >= math.pi then
            if conn then conn:Disconnect() end
            setCamOffset(Vector3.new(0, 0, 0))
            setCamRotOffset(Vector3.new(0, 0, 0))
        end
    end)
    spawnBullet(handle.CFrame*CFrame.new(0,0,-handle.Size.Z*0.5))

end
function sys.init(maid : Maid)
    local _maid = maid:GiveTask(Maid.new())
    local inputHandler = maid:GiveTask(InputHandler.new())

    local function onGunActivatedEvent()
        local char = Player.Character
        assert(char)
        local weapon = getWeaponFromPlayer(Player)
        assert(weapon)
        local handle = weapon:FindFirstChild("Handle") :: BasePart?; assert(handle)

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

    inputHandler:Map("OnGunActivatedEvent", "Keyboard", {Enum.UserInputType.MouseButton1}, "Hold", function() 
        onGunActivatedEvent()
    end, function() 
        _maid.Shoot = nil
    end)

    onCharAdded(Player.Character or Player.CharacterAdded:Wait())
    maid:GiveTask(Player.CharacterAdded:Connect(onCharAdded))
end

return sys