--!strict
--services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
--packages
local Maid = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Maid"))
--modules
local CustomEnums = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums"))
local AnimationSet = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AnimationSet"))
--types
type Maid = Maid.Maid
--constants
--variables
local Animations : {[string] : AnimationTrack} = {}
--references
local player = Players.LocalPlayer
--local functions
local function getAnim(name : string | CustomEnums.AnimationAction) : AnimationTrack
	return Animations[if type(name) == "string" then name else name.Name]
end

--class
local animationManager = {}

function animationManager.getAnimLength(animName : string)
	return getAnim(animName).Length
end

function animationManager.isPlaying(animName : string)
	return getAnim(animName).IsPlaying
end

function animationManager.setTimePosition(animName : string, timePos : number)
	getAnim(animName).TimePosition = timePos
end

function animationManager.playAnim(animName : string | CustomEnums.AnimationAction, priority : Enum.AnimationPriority ?, isLoop : boolean?, fadeTime : number?, weight :number?, speed :number?)
	local animTrack = getAnim(animName)
    animTrack.Priority = priority or Enum.AnimationPriority.Action
    animTrack.Looped = if isLoop ~= nil then isLoop else false
	if animTrack.IsPlaying == false then
		animTrack:Play(fadeTime or 0, weight, speed)
	end
	-- task.spawn(function()
	-- 	repeat wait() print("Anim track playing") until animTrack.IsPlaying == false
	-- end)
	return animTrack
end
function animationManager.stopAnim(animName : string | CustomEnums.AnimationAction, fadeTime : number?) -- string = name, number = animid
	local animTrack = getAnim(animName)
	if animTrack.IsPlaying == true then
		animTrack:Stop(fadeTime)
	end
	return animTrack
end

function animationManager.stopAllPlayerAnims(fadeTime : number?)
	--print(debug.traceback())
	for _, animTrack in pairs(Animations) do
		animTrack:Stop(fadeTime)
	end
end

function animationManager.adjustAnimProperty(animName : string | CustomEnums.AnimationAction, propertyName : "Weight" | "Speed", ...)
	local animTrack = getAnim(animName)
	
	if propertyName == "Weight" then
		local weight : number, fadeTime : number = ...
		
		animTrack:AdjustWeight(weight, fadeTime)
		return
	elseif propertyName == "Speed" then
		local speed : number = ...
		--print(`speed: {speed}`)
		animTrack:AdjustSpeed(speed)
		return
	end
	error(string.format("Property not found: %s!", propertyName))
	return 
end


function animationManager.init(maid : Maid)
	local animMaid = maid:GiveTask(Maid.new())
	local function onCharacterAdded(char : Model)
		--clearing 
        for k,v in pairs(Animations) do
			Animations[k] = nil
		end
		animMaid:DoCleaning()
		--

		local humanoid = char:WaitForChild("Humanoid")

		--registring animations

		local Animator = humanoid:WaitForChild("Animator") :: Animator

		for animName, animId in pairs(AnimationSet) do
			local animationInstance = animMaid:GiveTask(Instance.new("Animation"))
			animationInstance.Name = animName
			animationInstance.AnimationId = animId
            animationInstance.Parent = Animator

            local animTrack =  Animator:LoadAnimation(animationInstance)
			Animations[animName] = animTrack
		end
		
	end
	
	onCharacterAdded(player.Character or player.CharacterAdded:Wait())
	animMaid:GiveTask(player.CharacterAdded:Connect(onCharacterAdded))

end

return animationManager
