-- Because LocalController is disabled while MainMenu is open, this script allows other players' ships to be
-- visible while the player is not in-game (like from the main menu)
local Constants = require(script.Parent.Parent:WaitForChild("Constants"))
local Players = game:GetService("Players")
local player = game.Players.LocalPlayer

local eventsFolder = game.ReplicatedStorage:WaitForChild('Events')
local shipMovementEvent = eventsFolder:WaitForChild('ShipMovement')
local getEquippedInfoEvent = eventsFolder:WaitForChild('GetEquippedInfo')
local clientForceShipStraightEvent = eventsFolder:WaitForChild('ClientForceShipStraight')
local getFieldUpgradeDataEvent = eventsFolder:WaitForChild('GetFieldUpgradeData')

local MOVE_OFFSET = 0.005
local TURN_OFFSET = 0.025
local UPDATE_COUNT = 15
local itr = 0

--[[
	Destroy exisitng script effects and add script effects for ship
	@param playerUserId: Player UserId of the persona associated with the ship with an effect
	@param ship: Ship that will be displayed. Nil if only destroying scripts
]]
local function applyColorScriptEffects(playerUserId, ship)
	-- Delete existing script effects for colors
	for _,v in pairs (player.PlayerGui.ScriptEffects:GetChildren()) do
		if v.Name == tostring(playerUserId) .. "ShipEffect" then
			v:Destroy()
		end
	end

	-- Add the new script effects
	if ship then
		for _,part in pairs (ship:GetChildren()) do
			if string.match(part.Name, "Color") then
				if part:FindFirstChild('ShipEffect') then
					local scriptEffect = part.ShipEffect
					scriptEffect.Name = tostring(playerUserId) .. "ShipEffect"
					scriptEffect.Parent = player.PlayerGui.ScriptEffects
					scriptEffect.Enabled = true
				end
			end
		end
	end
end

--[[
	Given some threshold has been exceeded, place the ship at the hitbox
	@param playerUserId  UserId of the player who will be moved to the hitbox
]]
local function placeShipAtHitbox(playerUserId, margin)
	local playerShip = workspace.Ships:FindFirstChild(tostring(playerUserId) .. "'s Ship")
	local hitbox = workspace.Ships:FindFirstChild(tostring(playerUserId) .. "'s Hitbox")

	if playerShip and hitbox then
		local xNear = Constants.withinMargin(hitbox.Position.X, playerShip.Position.X, math.floor(hitbox.Size.X*margin))
		local zNear = Constants.withinMargin(hitbox.Position.Z, playerShip.Position.Z, math.floor(hitbox.Size.Z*margin))
		if not xNear or not zNear then
			local success = pcall(function()
				clientForceShipStraightEvent:Invoke(player) -- Bindable Function to wait for response (hitbox straighten)
				playerShip.CFrame = hitbox.CFrame
			end)
			if not success then
				warn('Failed hitbox straighten -- hitbox likely already destroyed')
			end
		end
	end
end

--[[
	Boost the player's ship forward
	@param playerUserId  Id of the player who owns the ship
	@param playerShip  Ship that will be boosted forward
	@param moveSpeeed  Move speed of the ship that will be boosted
]]
local function boostShip(playerUserId, playerShip, moveSpeed)
	-- Effects
	local boostParticle1 = game.ReplicatedStorage.Effects.BoostParticle1:Clone()
	local boostParticle2 = game.ReplicatedStorage.Effects.BoostParticle2:Clone()
	boostParticle1.Parent = playerShip
	boostParticle2.Parent = playerShip
	
	local hitbox = workspace.Ships:FindFirstChild(tostring(player.UserId).."'s Hitbox")
	if hitbox then
		hitbox:FindFirstChild('BoostSound'):Play()
	end

	coroutine.resume(coroutine.create(function()
		for i = 1,8 do -- Boost player's ship forward
			if player.InControl.Value then -- Stop boost if no longer in control
				wait(.01)
				playerShip.CFrame *= CFrame.new(0, 0, 4*(-moveSpeed*MOVE_OFFSET))
			end
		end
	end))

	-- Replicate movement to server
	-- shipMovementEvent:FireServer(nil, nil, true)

	wait(.3)
	--placeShipAtHitbox(playerUserId, 1.01)
	boostParticle1.Enabled = false
	boostParticle2.Enabled = false
	wait(getFieldUpgradeDataEvent:InvokeServer("Boost Regen"))
	wait(1.5)
	boostParticle1:Destroy()
	boostParticle2:Destroy()
end

--[[
	Signal sent from server to update the location of a player's model based on their hitbox
	@param playerUserId  UserId of the player that is moving
	@param keysPressed  Table containing booleans representing cardinal directions pressed
	@param levelChange  True if the model of the ship should be updated with a new model due to level change
	@param onlyCheck  True if sent by player who moved, only wanting to check margins for positions
	@param boost  True if the player used boost
	@param targetOrientation  Orientation of player ship for mobile users
]]
shipMovementEvent.OnClientEvent:Connect(function(playerUserId, keysPressed, levelChange, onlyCheck, boost, targetOrientation)
	if not onlyCheck then
		local playerName = tostring(Players:GetPlayerByUserId(playerUserId))
		local healthBarVisible = false

		-- Determine ship existence
		local ship
		local success = pcall(function()
			local existingShip = workspace.Ships:FindFirstChild(tostring(playerUserId) .. "'s Ship")
			if levelChange and existingShip then
				healthBarVisible = existingShip.GUI_Display.SurfaceGui.HealthBar.Visible
				existingShip:Destroy()
			end
			if not existingShip or levelChange then
				ship = game.Players:FindFirstChild(playerName):FindFirstChild("Player's Ship"):Clone()
				ship.Parent = workspace.Ships
				ship.Name = tostring(playerUserId) .. "'s Ship"
				ship.GUI_Display.SurfaceGui.HealthBar.Visible = healthBarVisible
				applyColorScriptEffects(playerUserId, ship)
			else
				ship = workspace.Ships:FindFirstChild(tostring(playerUserId) .. "'s Ship") -- Ship already in game
			end
			if levelChange and ship then
				ship.CFrame = keysPressed
			end
		end)
		if not success then
			warn(tostring(playerUserId) .. ' has a problem determining another player movement')
		end
		
		local hitbox = workspace.Ships:FindFirstChild(playerUserId .. "'s Hitbox")
		if ship and hitbox then
			local moveSpeed = hitbox.MoveSpeed.Value
			local turnSpeed = hitbox.TurnSpeed.Value
			
			if boost then
				-- placeShipAtHitbox(playerUserId, 1.01)
				boostShip(playerUserId, ship, moveSpeed)
			else
				local directions = {}
				
				if type(keysPressed) == 'table' then
					if targetOrientation == nil then
						for keyCode, isPressed in ipairs(keysPressed) do
							if isPressed then
								local keyCodeToDirectionMap = {
									CFrame.new(0, 0, -moveSpeed*MOVE_OFFSET), -- W
									CFrame.Angles(0, math.rad(turnSpeed*TURN_OFFSET), 0), -- A
									CFrame.new(0, 0, moveSpeed*MOVE_OFFSET/5), -- S
									CFrame.Angles(0, -math.rad(turnSpeed*TURN_OFFSET), 0) -- D
								}

								local direction = keyCodeToDirectionMap[keyCode]	
								table.insert(directions, direction)
							end
						end
					end
				else
					ship.CFrame = keysPressed
				end

				-- Send another signal to clients to update the model location of this player's ship (similar to projectiles)
				-- local playerShipModel = player:FindFirstChild("Player's Ship")
				local otherPlayer = game.Players:GetPlayerByUserId(playerUserId)
				local playerShipModel = otherPlayer:FindFirstChild("Player's Ship")
				if playerShipModel then
					
					-- Update the location of the hitbox on the server
					if targetOrientation then -- MOBILE/CONSOLE Control Scheme
						ship.CFrame = hitbox.CFrame -- TODO: Fix this later to be more smooth for mobile users
						--[[ship.CFrame *= CFrame.new(0, 0, -moveSpeed*MOVE_OFFSET)
						
						if ship.MovingToOrientation.Value ~= targetOrientation then
							ship.MovingToOrientation.Value = targetOrientation
							local difference = targetOrientation - ship.Orientation.Y

							-- Calculate wait time based on current level (slowing mobile turning)
							local delayAmount = math.floor(((-.0005)*turnSpeed+0.095)*1000)/1000

							-- Apply the changing value of the CFrame to the actual CFrame of the ship (Custom "tween")
							coroutine.resume(coroutine.create(function()
								local change = difference/UPDATE_COUNT
								for s = 1,UPDATE_COUNT do
									if ship.MovingToOrientation.Value == targetOrientation then
										ship.CFrame *= CFrame.Angles(0, math.rad(change), 0)
										wait(delayAmount)
									else
										break
									end
								end

								-- Ensure player has appropriately been pointed in the correct direction (avoid rounding errors)
								if ship.MovingToOrientation.Value == targetOrientation then
									local trueDiff = targetOrientation - ship.Orientation.Y
									ship.CFrame *= CFrame.Angles(0, math.rad(trueDiff), 0)
								end
							end))
						end]]
					else
						for _,direction in pairs(directions) do
							ship.CFrame *= direction
						end
					end
				end

				-- Move GUI_Display as well
				local upAmount = 10
				local usingControllerRef = player.PlayerGui.ControllerPrompt.UsingController
				if usingControllerRef and usingControllerRef.Value then
					upAmount = 20
				end
				local moveAmount = ship.GUI_Display.Distance.Value
				ship.GUI_Display.Position = Vector3.new(ship.Position.X, ship.Position.Y, ship.Position.Z + moveAmount) + Vector3.new(0, upAmount, 0) -- up a bit
			end
		end
	end
	
	-- Ensure LocalPlayer is in appropriate position with server's hitbox representation
	-- **This sanity check is placed in this script because Server->Client communication is faster than Client->Server
	if itr > 70 then -- Only use this compute every once and awhile
		itr = 0
		placeShipAtHitbox(playerUserId, 3)
	else
		itr += 1
	end
end)

