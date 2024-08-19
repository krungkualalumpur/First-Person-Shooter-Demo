--This is an auto generated script, please do not modify this!
--!strict
--services
--packages
--modules
--types
type CustomEnum <N> = {
	Name : N,
	GetEnumItems : (self : CustomEnum<N>) -> {[number] : CustomEnumItem<CustomEnum<N>, string>}
}

type CustomEnumItem <E, N> = {
	Name : N,
	Value : number,
	EnumType : E
}
type AnimationActionEnum = CustomEnum<"AnimationAction">
export type AnimationAction = CustomEnumItem<AnimationActionEnum, "Reload">

export type CustomEnums = {

	AnimationAction : 	{		
		Reload : CustomEnumItem <AnimationActionEnum, "Reload">,
	} & AnimationActionEnum,

}
--constants
--remotes
--local function


local AnimationAction = {
	Name = "AnimationAction",
	GetEnumItems = function(self)
		local t = {}
		for _,v in pairs(self) do
			if type(v) == "table" then 
				 table.insert(t, v)  
			end
		end
		return t
	end,
}

AnimationAction.Reload = {
	Name = "Reload",
	Value = 1,
	EnumType = AnimationAction
}

local CustomEnum = {	
	AnimationAction = AnimationAction :: any,
} :: CustomEnums

return CustomEnum