local TutorialUtility = {}

local TweenService = game:GetService("TweenService")

--[[
	Create a finger pointer and animate it
	@param location: Position of the finger Pointer
	@param rotation: Rotation of the finger Pointer
	@param pointerId: Name of this created finger Pointer
]]
function TutorialUtility.fingerPointer(location, rotation, pointerId)
	local newPointer = script.PointerHand:Clone()
	newPointer.Parent = script.Parent
	newPointer.Position = location; newPointer.Rotation = rotation
	newPointer.Name = pointerId
	
	local netPush = 0.015
	local xPush = netPush*math.sin(math.rad(rotation)); local yPush = -netPush*math.cos(math.rad(rotation))
	local targetLocation = UDim2.new(location.X.Scale + xPush, 0, location.Y.Scale + yPush, 0)
	
	local upTween = TweenService:Create(newPointer, TweenInfo.new(.4, Enum.EasingStyle.Quint), {Position = targetLocation})
	local downTween = TweenService:Create(newPointer, TweenInfo.new(.6, Enum.EasingStyle.Back), {Position = location})
	coroutine.resume(coroutine.create(function()
		while newPointer do
			wait(1.5)
			upTween:Play()
			wait(.4)
			downTween:Play()
		end
	end))
end







return TutorialUtility
