local PointerArrow = require(script.Parent)

local eventsFolder = game.ReplicatedStorage:WaitForChild('Events')
local createPointerArrowEvent = eventsFolder:WaitForChild('CreatePointerArrow')

local player = game.Players.LocalPlayer

--[[
	Create a pointer arrow for a specific player pointing towards the target
	@param player: Player who sees the pointer arrow
	@param target: What the pointer arrow will be pointing towards
]]
createPointerArrowEvent.OnClientEvent:Connect(function(target, label, color, lifetime)
	local playerShip = game.Workspace:WaitForChild('Ships'):FindFirstChild(tostring(player.UserId) .. "'s Ship")
	if playerShip then
		local pointerArrow = PointerArrow.new(player, playerShip, label, color, nil)
		wait(lifetime)
		pointerArrow:Destroy()
	end
end)
