local hand = script.Parent.Hand	
local hinge = script.Parent.Hinge
local arm = script.Parent.Arm

-- Add appropriate welds
for _,part in pairs(hand:GetChildren()) do
	local weld = Instance.new("WeldConstraint", part)
	weld.Part0 = part
	weld.Part1 = arm
	part.Anchored = false
end

local offset = hinge.CFrame:Inverse() * arm.CFrame
local direction = 1
local waitAmount = .05
while true do
	wait(waitAmount)
	local orient = arm.Orientation.Z
	if orient < -80 then
		direction = 1
	elseif orient > 70 then
		direction = -1
	end
	hinge.CFrame *= CFrame.Angles(math.rad(direction)*waitAmount*60, 0, 0)
	arm.CFrame = hinge.CFrame * offset
end


