--!strict
--services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
--packages
local _Packages = ReplicatedStorage:WaitForChild("Packages")

local Maid = require(_Packages:WaitForChild("Maid"))
local MathUtil = require(_Packages:WaitForChild("MathUtil"))
local InputHandler = require(_Packages:WaitForChild("InputHandler"))
--modules
--types
type Maid = Maid.Maid
--constants
--remotes
--variables
--references
local Player = Players.LocalPlayer
--local functions
--class
local sys = {}

function otherPlayerHit(plr : Player)
	
end
function onGunInit()
    
end

function getWeaponFromPlayer(plr : Player)
    local char = Player.Character
    local gun = char:FindFirstChild("Gun") :: Tool?
    return if gun and gun:FindFirstChild("Handle") then gun else nil
end

function sys.onGunWeapon(gun : Tool)
    print("1")
    if gun:IsA("Tool") then
        print("2")
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

		runAnim.AnimationId = "rbxassetid://18908827149"
		walkAnim.AnimationId = "rbxassetid://18908827149"
		--default
		--animateScript.run.RunAnim.AnimationId = "rbxassetid://18908827149"
		--animateScript.walk.WalkAnim.AnimationId = "rbxassetid://913376220"
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

		local camFOV = camera.FieldOfView
		game["Run Service"].Stepped:Connect(function()
			humanoid.CameraOffset = humanoidRootPart.CFrame:VectorToObjectSpace(camera.CFrame.UpVector*head.Size.Y*0.5 + camera.CFrame.LookVector*head.Size.Z*0.5) --Vector3.new(0,char.Head.Size.Y*0.25,-char.Head.Size.Z)
			--Player.CameraMaxZoomDistance = 12
			--Player.CameraMinZoomDistance = 0
			--camera.CameraType = Enum.CameraType.Scriptable 
			--camera.CFrame = char.Head.CFrame*CFrame.new(0,0,-char.Head.Size.Z*0.65)
			--char.Head.Transparency = 1
			--tracking camera cframe
			local isAiming = game.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
			
			local rh_cf = char.PrimaryPart.CFrame:ToObjectSpace(rightHand.CFrame)
			local x, y, z = rh_cf:ToOrientation()
			
			local leftTorsoToArmPos = leftUpperArm.CFrame*(Vector3.new(0,leftUpperArm.Size.Y*0.5,0)) 
			local rightTorsoToArmPos = rightUpperArm.CFrame*(Vector3.new(0,rightUpperArm.Size.Y*0.5,0)) 
			
			local deg = math.acos(((-char.PrimaryPart.Position - (char.PrimaryPart.CFrame.LookVector*handle.Size.Z) + rightTorsoToArmPos + Vector3.new(0, -1, 0)) ).Unit:Dot(-(char.PrimaryPart.CFrame.LookVector*handle.Size.Z).Unit))
			local directionSourceCf =  if isAiming then camera.CFrame*CFrame.new(0, -handle.Size.Y*0.5, 0)
				else (char.PrimaryPart.CFrame*CFrame.Angles(-deg, 0, 0))
			
			local destPos : Vector3 = directionSourceCf*Vector3.new(0, 0, -handle.Size.Z*(if isAiming then 2 else 1))
				
			weld.C1 = weld.C1:Lerp(
				CFrame.new(0,-handle.Size.Z*0.5,0)*((rightHand.CFrame:Inverse()*(directionSourceCf)) - (rightHand.CFrame:Inverse()*(directionSourceCf)).Position), 
				0.3
			)
		
			local c_l = math.clamp((leftTorsoToArmPos - destPos).Magnitude, 0, (a_l + b_l))
			local c_r = math.clamp((rightTorsoToArmPos - destPos).Magnitude, 0, (a_r + b_r))

			for _,v in pairs(animator:GetPlayingAnimationTracks()) do
				--if v.Name:lower():find("toolnoneanim") or v.Name:lower():find("animation1") or v.Name:lower():find("idle") then 
				v:Stop()
				--end
			end
			
			local handDestPos = if (rightTorsoToArmPos - destPos).Magnitude > a_r + b_r then rightTorsoToArmPos + (destPos - rightTorsoToArmPos).Unit*c_r else destPos
			
            local cfrot_l, A_l, B_l, C_l = customInverseKinematicsCfAndAngles(a_l, b_l, leftTorsoToArmPos, handDestPos)
            local cfrot_r, A_r, B_r, C_r = customInverseKinematicsCfAndAngles(a_r, b_r, rightTorsoToArmPos, handDestPos)
          
            local leftShoulder, leftElbow, rightShoulder, rightElbow = leftUpperArm:FindFirstChild("LeftShoulder") :: Motor6D,
                leftLowerArm:FindFirstChild("LeftElbow") :: Motor6D,
                rightUpperArm:FindFirstChild("RightShoulder") :: Motor6D,
                rightLowerArm:FindFirstChild("RightElbow") :: Motor6D

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
		end)
		
		
	end
end

function onCharAdded(char : Model)
    local _maid = Maid.new()
    
    _maid:GiveTask(char.ChildAdded:Connect(function(weapon : Instance)
        if weapon:IsA("Tool") then
            sys.onGunWeapon(weapon)
        end
    end))

    _maid:GiveTask(char.AncestryChanged:Connect(function()
        if char.Parent == nil then
            _maid:Destroy()
        end
    end))
end
function sys.init(maid : Maid)
    print("test1?")
    local inputHandler = maid:GiveTask(InputHandler.new())

    inputHandler:Map("OnShoot", "Keyboard", {Enum.UserInputType.MouseButton1}, "Hold", function() 
        local char = Player.Character
        assert(char)
        local weapon = getWeaponFromPlayer(Player)
        assert(weapon)
        local handle = weapon:FindFirstChild("Handle") :: BasePart?; assert(handle)
        --Player.CameraMaxZoomDistance = 0
        --Player.CameraMinZoomDistance = 0

        --create raycast with distance 1000
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {char}
        raycastParams.IgnoreWater = true
        raycastParams.CollisionGroup = "Default"
        raycastParams.RespectCanCollide = true
        local raycastResult = workspace:Raycast(handle.Position, handle.CFrame.LookVector * 1000, raycastParams)
        if raycastResult then
            --create part at position
            raycastResult.Instance.Color = Color3.fromRGB(255,0,0)
        end

        local p = Instance.new("Part")
        p.Anchored = true
        p.CanCollide = false
        p.Size = Vector3.new(0.5,0.5,2)
        p.CFrame = handle.CFrame + handle.CFrame.LookVector*handle.Size.Y
        p.Material = Enum.Material.Neon
        p.Parent = workspace		

        --bullet init
        for i = 0, 500 do 
            p.CFrame += p.CFrame.LookVector*6
            local parts = p:GetTouchingParts()
            if #parts > 0 then
                for _,v in pairs(parts) do
                    local plrHit = game.Players:GetPlayerFromCharacter(v.Parent)
                    local _char = v.Parent
                    if plrHit then
                        otherPlayerHit(plrHit)
                    end
                end

                break
            end
            task.wait()
        end
        p:Destroy()
    end, function() end)

    print("keun")
    onCharAdded(Player.Character or Player.CharacterAdded:Wait())
    maid:GiveTask(Player.CharacterAdded:Connect(onCharAdded))
end

return sys