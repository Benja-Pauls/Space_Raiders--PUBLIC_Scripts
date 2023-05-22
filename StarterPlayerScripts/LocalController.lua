local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local GuiUtility = require(script.Parent.Parent.Parent.PlayerGui:WaitForChild('GuiUtility'))
local Constants = require(script.Parent.Parent:WaitForChild('Constants'))
local FIRE_DELAY = Constants.FIRE_DELAY
local BOLT_LIFE = Constants.BOLT_LIFE
local boostAvailableRef = script:WaitForChild("BoostAvailable")
boostAvailableRef.Value = 1 -- Make 1 on level up
script:WaitForChild('Enum.KeyCode.Space').Value = false -- Reset boost on level up and ship instantiation

local eventsFolder = game.ReplicatedStorage:WaitForChild('Events')
local shipMovementEvent = eventsFolder:WaitForChild('ShipMovement')
local fireWeaponsEvent = eventsFolder:WaitForChild('FireWeapons')
local getEquippedInfoEvent = eventsFolder:WaitForChild('GetEquippedInfo')
local forceShipStraightEvent = eventsFolder:WaitForChild('ForceShipStraight')
local clientForceShipStraightEvent = eventsFolder:WaitForChild('ClientForceShipStraight')
local boostShipEvent = eventsFolder:WaitForChild('BoostShip')
local bouncePlayerShipEvent = eventsFolder:WaitForChild("BouncePlayerShip")
local getFieldUpgradeDataEvent = eventsFolder:WaitForChild('GetFieldUpgradeData')

local player = Players.LocalPlayer
local character = player.Character
local humanoid = character:WaitForChild("Humanoid")
local playerShip = workspace.Ships:WaitForChild(tostring(player.UserId) .. "'s Ship")

local PointerArrow = require(player.PlayerGui:WaitForChild('PointerArrow'))
for _,button in pairs(player.PlayerGui.PointerArrows:GetChildren()) do button:Destroy() end
local centerArrow, bestPlayerArrow = PointerArrow.new(player, playerShip, "Center", Color3.fromRGB(1, 111, 255), "rbxassetid://10337006386"), nil
local bestPlayerRef = workspace.BestPlayer
if bestPlayerRef.Value and bestPlayerRef.Value:IsA("Player") and bestPlayerRef.Value ~= player then
	bestPlayerArrow = PointerArrow.new(player, playerShip, "Best", Color3.fromRGB(184, 73, 0), "rbxassetid://10336929620")
end

local camera = workspace.CurrentCamera
local mouse = player:GetMouse()

local sendToServer = true

--[[
	Update orientation of text on pointerArrow for best readability
	@param pointerArrow  Arrow that will be updated
]]
local function updatePointerTextOrientation(pointerArrow)
	local currentY = pointerArrow.PrimaryPart.Orientation.Y
	if currentY <= 0 and currentY >= -179 then
		pointerArrow.PointerArrow.SurfaceGui.Frame.Rotation = 180
	else
		pointerArrow.PointerArrow.SurfaceGui.Frame.Rotation = 0
	end	
end

--[[
	Update the orientation of pointer arrows
]]
local function updatePointerArrows()
	local bestPlayer = workspace:WaitForChild('BestPlayer').Value
	if bestPlayerArrow and bestPlayer and bestPlayer ~= player then
		local bestPlayerHitbox = workspace.Ships:FindFirstChild(tostring(bestPlayer.UserId) .. "'s Hitbox")
		if bestPlayerHitbox then
			bestPlayerArrow.PrimaryPart.CFrame = CFrame.new(playerShip.Position, bestPlayerHitbox.Position)
			updatePointerTextOrientation(bestPlayerArrow)
		end
	elseif not bestPlayerArrow and bestPlayer and bestPlayer ~= player then
		bestPlayerArrow = PointerArrow.new(player, playerShip, "Best", Color3.fromRGB(184, 73, 0), "rbxassetid://10336929620")
	elseif bestPlayerArrow then
		PointerArrow.destroy(bestPlayerArrow, "Best")
		bestPlayerArrow = nil
	end
	centerArrow.PrimaryPart.CFrame = CFrame.new(playerShip.Position, workspace.MapCenter.Position)
	updatePointerTextOrientation(centerArrow)
	
	-- Update the location of material spawner arrow if there is one
	pcall(function()
		if playerShip:FindFirstChild('MatSpawnerPointerArrow') then
			local matSpawner = workspace:FindFirstChild('MatSpawner')
			if matSpawner then
				playerShip.MatSpawnerPointerArrow.PrimaryPart.CFrame = CFrame.new(playerShip.Position, matSpawner.Primary.Position)
				
				local currentTick = tick(); local arrowTick = playerShip.MatSpawnerPointerArrow.ExpireTime.Value
				if currentTick >= arrowTick then
					playerShip.MatSpawnerPointerArrow:Destroy()
				else
					updatePointerTextOrientation(playerShip.MatSpawnerPointerArrow)
				end
			end
		end
	end)
end

--------------<< Player Input Functions >>-----------------------------
local MOVE_OFFSET = .005 -- Base Level
local TURN_OFFSET = .025 -- Base Level
local UPDATE_COUNT = 15

--[[
local keyCodeToIsPressedMap = {
	[Enum.KeyCode.W] = false,
	[Enum.KeyCode.A] = false,
	[Enum.KeyCode.S] = false,
	[Enum.KeyCode.D] = false,
	[Enum.KeyCode.Space] = false,
}
]]

--[[
	Return upStatus, rightStatus, leftStatus, and downStatus
]]
local function getAllKeyStatuses()
	local upStatus = script:FindFirstChild('Enum.KeyCode.W').Value
	local leftStatus = script:FindFirstChild('Enum.KeyCode.A').Value
	local downStatus = script:FindFirstChild('Enum.KeyCode.S').Value
	local rightStatus = script:FindFirstChild('Enum.KeyCode.D').Value
	return {upStatus, leftStatus, downStatus, rightStatus}
end

--[[
    A utility function that returns `true` if the given `input` is relevant to
    this "controller".

    @param {InputObject} input

    @returns {boolean}
]]
local function isRelevantInput(input)
	if input.KeyCode == Enum.KeyCode.Up then
		input.KeyCode = Enum.KeyCode.W
	elseif input.KeyCode == Enum.KeyCode.Left then
		input.KeyCode = Enum.KeyCode.A
	elseif input.KeyCode == Enum.KeyCode.Right then
		input.KeyCode = Enum.KeyCode.D
	elseif input.KeyCode == Enum.KeyCode.Down then
		input.KeyCode = Enum.KeyCode.S
	end
	
	return (
		input.KeyCode == Enum.KeyCode.W -- Up
			or input.KeyCode == Enum.KeyCode.A -- Left
			or input.KeyCode == Enum.KeyCode.S -- Down
			or input.KeyCode == Enum.KeyCode.D -- Right
			or input.KeyCode == Enum.KeyCode.Space -- Shoot (also called with Mouse event)
	)
end

--[[
    An event handler that is meant to listen to `UserInputService.InputBegan`.
    It modifies `keyCodeToIsPressedMap` accounting for engine context.
    
    @param {InputObject} input
    @param {boolean} gameProcessedEvent

    @returns {nil}
]]
local function registerKeyPressed(input, gameProcessedEvent)
	if gameProcessedEvent or not isRelevantInput(input) then
		return -- End function
	end
	
	script:FindFirstChild(tostring(input.KeyCode)).Value = true
end

--[[
    An event handler that is meant to listen to `UserInputService.InputEnded`.
    It modifies `keyCodeToIsPressedMap` accounting for engine context.

    @param {InputObject} input
    @param {boolean} gameProcessedEvent

    @returns {nil}
]]
local function unregisterKeyPressed(input, gameProcessedEvent)
	local success = pcall(function()
		if gameProcessedEvent or not isRelevantInput(input) then
			return -- End function
		end
		script:FindFirstChild(tostring(input.KeyCode)).Value = false
	end)
	if not success then -- From forceShipStraight function, meaning input's key is already defined
		script:FindFirstChild(tostring(input)).Value = false
	end
end

--[[
    A utility function that returns which directions should be processed by the
    moving part's manager.

	@param keysPressed the keys pressed currently by the player
    @returns {Vector3[]}
]]
local function getDirectionsToProcess(keysPressed)
	local directions = {}
	for keyCode, isPressed in pairs(keysPressed) do
		if isPressed then
			local keyCodeToDirectionMap = {
				CFrame.new(0, 0, MOVE_OFFSET), -- W
				CFrame.Angles(0, math.rad(TURN_OFFSET), 0), -- A
				CFrame.new(0, 0, MOVE_OFFSET/5), -- S
				CFrame.Angles(0, -math.rad(TURN_OFFSET), 0) -- D
			}
			local direction = keyCodeToDirectionMap[keyCode]	
			table.insert(directions, direction)
		end
	end
	return directions
end

--[[ [MOBILE/CONSOLE ONLY]
	Alternative movement scheme that better-suits analog sticks
	@param hitbox  Hitbox the player is related to
	@param keysPressed  Boolean table correlating to directions
	@param moveSpeed  Movement speed of the player at their current level
	@param turnSpeed Turn speed of the player at their current level
]]
local function alternativeControlInput(hitbox, keysPressed, moveSpeed, turnSpeed)
	local currentOrient = playerShip.Orientation.Y
	local x = humanoid.MoveDirection.X
	local z = humanoid.MoveDirection.Z
	local targetOrientation = 0
	
	-- Calculate wait time based on current level (slowing mobile turning)
	local delayAmount = math.floor(((-.0005)*turnSpeed+0.095)*1000)/1000
	
	if not (x == 0 and z == 0) then -- Don't move ship if no input from player
		-- Player only moves towards direction of nose
		playerShip.CFrame *= CFrame.new(0, 0, -moveSpeed*MOVE_OFFSET)

		-- Determine if the player is moving in a diagonal direction
		local diagonal = false
		if math.abs(x) + .15 >= math.abs(z) and math.abs(x) - .15 <= math.abs(z) then
			diagonal = true
		end

		-- Determine Right/Left Movement of playerShip
		if math.abs(x) >= math.abs(z) or diagonal then
			if x > 0 then -- Right
				local closeToNeg = currentOrient - -90
				local closeToPos = currentOrient - 270
				if math.abs(closeToNeg) < math.abs(closeToPos) then
					targetOrientation = -90
				else
					targetOrientation = 270
				end
			else -- Left
				local closeToNeg = currentOrient - 90
				local closeToPos = currentOrient - -270
				if math.abs(closeToNeg) < math.abs(closeToPos) then
					targetOrientation = 90
				else
					targetOrientation = -270
				end
			end
		end

		-- Determine Up/Down Movement of the playerShip
		if math.abs(z) > math.abs(x) or diagonal then
			if z > 0 then -- Down
				if not diagonal then
					local closeToNeg = currentOrient - -180
					local closeToPos = currentOrient - 180
					if math.abs(closeToNeg) < math.abs(closeToPos) then
						targetOrientation = -180
					else
						targetOrientation = 180
					end
				end
				if diagonal then
					if targetOrientation == 90 then
						targetOrientation += 45
					else
						targetOrientation -= 45
					end
				end
			else -- Up
				if not diagonal then
					targetOrientation = 0
				end
				if diagonal then
					if targetOrientation == 90 then
						targetOrientation -= 45
					else
						targetOrientation += 45
					end
				end
			end
		end

		-- See if orientation player is moving to is what player already wants to happen
		if playerShip.MovingToOrientation.Value ~= targetOrientation then
			playerShip.MovingToOrientation.Value = targetOrientation
			local difference = targetOrientation - playerShip.Orientation.Y
			
			if math.abs(difference) < 181 then
				-- Apply the changing value of the CFrame to the actual CFrame of the ship (Custom "tween")
				coroutine.resume(coroutine.create(function()
					local change = difference/UPDATE_COUNT
					for s = 1,UPDATE_COUNT do
						if playerShip.MovingToOrientation.Value == targetOrientation then
							playerShip.CFrame *= CFrame.Angles(0, math.rad(change), 0)
							wait(delayAmount)
						else
							break
						end
					end

					-- Ensure player has appropriately been pointed in the correct direction (avoid rounding errors)
					if playerShip.MovingToOrientation.Value == targetOrientation then
						local trueDiff = targetOrientation - playerShip.Orientation.Y
						playerShip.CFrame *= CFrame.Angles(0, math.rad(trueDiff), 0)
					end
				end))
			end
		end

		-- Replicate this movement on the server (mobile/console)
		if sendToServer then
			shipMovementEvent:FireServer(keysPressed, targetOrientation, playerShip.CFrame)
		end
		sendToServer = not sendToServer
	end
end


-----------------------------<<|| Movement ||>>--------------------------------------------------------------------------------------
local playerShip = workspace.Ships:WaitForChild(tostring(player.UserId) .. "'s Ship")
local hitbox = workspace.Ships:WaitForChild(tostring(player.UserId) .. "'s Hitbox")

--[[
	Determine the hit direction for two colliding objects
	@param hit1: First hitbox being hit
	@param hit2: Second hitbox being hit
]]
local function getBounceDirections(hit1, hit2, constant)
	-- Determine positive or negative direction for each of the bounced players
	local x_diff, z_diff = hit1.CFrame.X - hit2.CFrame.X, hit1.CFrame.Z - hit2.CFrame.Z
	local other_x_dir, other_z_dir, player_x_dir, player_z_dir
	if x_diff < 0 then
		player_x_dir = 1; other_x_dir = -1
	else
		player_x_dir = -1; other_x_dir = 1
	end
	if z_diff < 0 then
		player_z_dir = 1; other_z_dir = -1
	else
		player_z_dir = -1; other_z_dir = 1
	end

	-- Move the ship proportional to the half lengths of the other ship
	local other_x_dim, other_z_dim = hit1.Size.X/3, hit1.Size.Z/3
	local player_x_dim, player_z_dim = hit2.Size.Z/3, hit2.Size.Z/3
	if constant then
		other_x_dim = constant; other_z_dim = constant
		player_x_dim = constant; player_z_dim = constant
	end
	local player_push = Vector3.new(other_x_dim*player_x_dir, 0, other_z_dim*player_z_dir)
	local other_push = Vector3.new(player_x_dim*other_x_dir, 0, player_z_dim*other_z_dir)
	return player_push,other_push
end

--[[
	Go back the way each of the players came (make a unit vector from current and prev CFrame)
	@param player  Player who is being bounced
	@param hitbox  The hitbox that will be moved (and used as movement reference)
	@param pushDirection Vector3 representing direction player will be bounced towards
]]
local function bouncePlayer(pushDirection)
	hitbox.Bounce:Play()
	local success = pcall(function()
		player.InControl.Value = false

		--local nextCFrame -- If player should keep being pushed or if they hit something else
		bouncePlayerShipEvent:FireServer(pushDirection)
		for m = 1,5 do

			--if nextCFrame == nil or (Constants.withinMargin(nextCFrame.X, playerShip.CFrame.X, 2.5) and Constants.withinMargin(nextCFrame.Z, playerShip.CFrame.Z, 2.5)) then
			wait()


			playerShip.CFrame += pushDirection/2
			playerShip.CFrame += Vector3.new(0, -playerShip.Position.Y, 0) -- Ensure staying on y-plane
			--nextCFrame = hitbox.CFrame.Position + pushDirection/3
			-- hitbox.Rotation = Vector3.new(0, hitbox.Rotation.Y, 0)

			--for _,p in pairs (game.Players:GetChildren()) do
			--shipMovementEvent:FireClient(p, player.UserId, hitbox.CFrame)
			--end
			--else
			--print("BROKE OUT")
			--break
			--end
		end

		hitbox.PreviousCFrame.Value = hitbox.CFrame -- Update from bounce
		wait(.15)
		player.InControl.Value = true
	end)

	if not success then
		warn('Problem ocurred while bouncing player')
	end
end

playerShip.Touched:Connect(function(hit)
	if hit.Name == "Bounce" or hit.Name == "AsteroidBounce" or hit.Name == "CrackedBounce" then -- Asteroid, wall
		local player_push,other_push = getBounceDirections(hit, hitbox, 2.5)
		bouncePlayer(player_push)
	elseif hit.Name == "BarrierMain" then
		local barrier = hit.Parent
		local pushDirection = barrier.Push.Value
		hitbox.Bounce:Play()

		player.InControl.Value = false
		if math.abs(pushDirection.Z) == 1 then
			local change = hitbox.Position.Z - (barrier.Wall.Position.Z + pushDirection.Z)
			pushDirection = Vector3.new(0, 0, change+1)
		else -- Change in X Direction
			local change = hitbox.Position.X - (barrier.Wall.Position.X + pushDirection.X)
			pushDirection = Vector3.new(change+1, 0, 0)
		end

		bouncePlayer(pushDirection)
		player.InControl.Value = true
	end
end)



--[[
	Boost the player's ship forward
]]
local function boostShip(keysPressed, targetOrientation)
	local hitbox = workspace.Ships:FindFirstChild(tostring(player.UserId) .. "'s Hitbox")
	if hitbox then
		local moveSpeed = hitbox.MoveSpeed.Value
	
		if boostAvailableRef.Value == 1 then
			local boostDelay = getFieldUpgradeDataEvent:InvokeServer("Boost Regen")
			boostAvailableRef.Value = 0
			TweenService:Create(boostAvailableRef, TweenInfo.new(boostDelay, Enum.EasingStyle.Linear), {Value = 1}):Play()
			-- TweenService:Create(boostAvailableRef, TweenInfo.new(BOOST_DELAY, Enum.EasingStyle.Linear), {Value = 1}):Play()
			
			-- Effects
			local boostParticle1 = game.ReplicatedStorage.Effects.BoostParticle1:Clone()
			local boostParticle2 = game.ReplicatedStorage.Effects.BoostParticle2:Clone()
			boostParticle1.Parent = playerShip
			boostParticle2.Parent = playerShip
			workspace.Ships:FindFirstChild(tostring(player.UserId).."'s Hitbox").BoostSound:Play()
			
			coroutine.resume(coroutine.create(function()
				for i = 1,8 do -- Boost player's ship forward
					if player.InControl.Value then -- Stop boost if no longer in control
						wait(.01)
						forceShipStraight(player)
						playerShip.CFrame *= CFrame.new(0, 0, 4*(-moveSpeed*MOVE_OFFSET))
					end
				end
			end))

			-- Replicate movement to server
			boostShipEvent:FireServer(keysPressed, targetOrientation)
			
			wait(.3)
			boostParticle1.Enabled = false
			boostParticle2.Enabled = false
			wait(boostDelay - .6) -- Cut some slack with upload time
			wait(1.5)
			boostParticle1:Destroy()
			boostParticle2:Destroy()
		end
	end
end

--[[
    An event handler that is meant to listen to `RunService.Heartbeat`. It
    manages the part to be moved, taking into consideration the time elapsed
    between frames. Refer to `targetVelocity` to adjust how fast the part moves.
    @param step  The time (in seconds) that has elapsed since the previous frame.
]]
local go = false
local function managePartInput(step)
	-- Events cannot pass dictionaries, only tables
	local keysPressed = getAllKeyStatuses()
	if (keysPressed[1] or keysPressed[2] or keysPressed[3] or keysPressed[4]) and player.InControl.Value then -- Not all false
		if playerShip and hitbox then
			local moveSpeed, turnSpeed = hitbox.MoveSpeed.Value, hitbox.TurnSpeed.Value

			-- [PC ONLY] Get directions based on keys pressed
			local directions = {}
			local usingControllerRef = player.PlayerGui.ControllerPrompt.UsingController
			if not (player.PlayerGui:FindFirstChild("TouchGui") or (usingControllerRef and usingControllerRef.Value)) then
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

			local usingControllerRef = player.PlayerGui.ControllerPrompt.UsingController
			if player.PlayerGui:FindFirstChild("TouchGui") or (usingControllerRef and usingControllerRef.Value) then
				alternativeControlInput(hitbox, keysPressed, moveSpeed, turnSpeed)
			else
				for _,direction in pairs(directions) do -- Does not require diagonal-movement check
					playerShip.CFrame *= direction
				end

				-- Replicate this movement on the server (PC)
				if sendToServer then
					shipMovementEvent:FireServer(keysPressed, nil, playerShip.CFrame)
				end
				sendToServer = not sendToServer
			end

			-- Update location of ship's GUI display (no need to update rotation)
			local upAmount = 10
			if usingControllerRef and usingControllerRef.Value then
				upAmount = 20
			end
			playerShip.GUI_Display.Position = playerShip.Position + Vector3.new(0, upAmount, 0) -- up a bit
			playerShip.GUI_Display.CFrame *= CFrame.new(0, 0, playerShip.GUI_Display.Distance.Value) -- Offset downward by set amount for that ship

			-- Can only boost if moving in some direction
			if script:FindFirstChild('Enum.KeyCode.Space').Value then
				boostShip()
			end

			updatePointerArrows()
		end
	end
end


---------------<< Laser Bolt Handling >>----------------------------------------------
local debounce = false -- Fire delay
local IN_FIRE_TWEENINFO = TweenInfo.new(.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local OUT_FIRE_TWEENINFO = TweenInfo.new(.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

--[[
	Fires all weapons on player ship. Registered from space or Button1 click
	-- Z is up an down
	-- X is left and right
	-- The changing rotation is in the Y direction
]]
local function fireWeapons() 
	if not debounce then
		debounce = true
		
		-- Slight camera effect when firing
		coroutine.resume(coroutine.create(function()
			local camFOV = camera.FieldOfView
			TweenService:Create(camera, IN_FIRE_TWEENINFO, {FieldOfView = camFOV - .4}):Play()
			wait(IN_FIRE_TWEENINFO.Time)
			TweenService:Create(camera, OUT_FIRE_TWEENINFO, {FieldOfView = camFOV}):Play()
		end))
		
		-- Fire each blaster on the ship
		local firstBlasterReached = false
		for _,blaster in pairs (playerShip:GetChildren()) do
			if blaster.Name == "Blaster" and blaster:IsA("BasePart") then
				coroutine.resume(coroutine.create(function()
					
					-- Spawn in physical laser bolt
					local equipData = getEquippedInfoEvent:InvokeServer(player)
					local projectile = equipData[2]["Model"]:Clone()
					
					-- Provide Behavior; Just visuals displayed on client (hit reg is on server)
					projectile.Touched:Connect(function(hit)
						if hit:IsDescendantOf(workspace.Ships) then
							if string.match(hit.Name, "'s Hitbox") ~= nil and hit.Name ~= tostring(player) .. "'s Hitbox" then
								local hitPlayerUserId = string.gsub(hit.Name, "'s Hitbox", "")
								local hitPlayer
								if string.match(hitPlayerUserId, "Bot") then
									hitPlayer = workspace.Ships:FindFirstChild(hitPlayerUserId)
								else
									hitPlayer = Players:GetPlayerByUserId(tonumber(hitPlayerUserId))
								end
									
								if hitPlayer and hitPlayer ~= player then -- Ensure player exists and isn't invincible
									Constants.boltExplosionEffect(projectile)	
								end
							end
						elseif hit.Name == 'Bounce' or hit.Name == "AsteroidBounce" then
							Constants.boltExplosionEffect(projectile, true)
						elseif hit.Name == "CrackedBounce" then
							Constants.boltExplosionEffect(projectile)
						end
					end)

					local particles = equipData[4]["Folder"].Laser:Clone()
					projectile.CanCollide = false
					particles.Parent = projectile
					projectile.Color = equipData[7]["Color"].Color
					projectile.PointLight.Color = projectile.Color

					-- Position with ship
					projectile.Parent = workspace.Projectiles
					projectile.CFrame = blaster.CFrame
					SoundService:PlayLocalSound(projectile.Sound)
					Debris:AddItem(projectile, BOLT_LIFE)
					
					if firstBlasterReached then
						fireWeaponsEvent:FireServer(projectile.Position, projectile.Rotation)
					else
						firstBlasterReached = true
						fireWeaponsEvent:FireServer(projectile.Position, projectile.Rotation, true)
					end
				
					Constants.speedManipulation(projectile)
				end))
			end
		end

		wait(FIRE_DELAY)
		debounce = false
	end
end

UserInputService.InputBegan:Connect(registerKeyPressed)
UserInputService.InputEnded:Connect(unregisterKeyPressed)
RunService.RenderStepped:Connect(managePartInput)
-- Heartbeat:Connect(managePartInput) -- Always run

if player:WaitForChild("PlayerGui"):FindFirstChild("TouchGui") then -- MOBILE User
	UserInputService.TouchTapInWorld:Connect(fireWeapons)
	ContextActionService:BindAction("Boost", boostShip, true, Enum.KeyCode.Space)
	ContextActionService:SetImage("Boost", "rbxassetid://10361507794")
else -- PC/CONSOLE User
	ContextActionService:BindAction("Shoot", fireWeapons, false, Enum.KeyCode.ButtonR2)
	mouse.Button1Down:Connect(fireWeapons)
	ContextActionService:BindAction("Shoot", fireWeapons, false, Enum.KeyCode.RightControl) -- Connor Request
end

--[[
	Simple utility function to either register or unregister key from analog movement
	@param keyCode  The keyCode that will be checked
	@param keysPressed  The 'keys' that have actually been pressed
]]
local function checkKeyPresence(keyCode, keysPressed)
	local pressed = false
	for _,v in pairs (keysPressed) do
		if not pressed and keyCode == v then
			pressed = true
		end
	end
	
	script:FindFirstChild(tostring(keyCode)).Value = pressed
end

--[[
	Relate humanoid movement input to input for space ship without direct keyboard input
]]
local function calculateAlternativeMovement()
	if humanoid.MoveDirection ~= Vector3.new() then
		local x = humanoid.MoveDirection.X
		local z = humanoid.MoveDirection.Z
		local keysPressed = {}

		local diagonal = false
		if math.abs(x) + .15 >= math.abs(z) and math.abs(x) - .15 <= math.abs(z) then
			diagonal = true
		end

		if math.abs(x) >= math.abs(z) or diagonal then -- Right/Left Movement
			if x > 0 then -- Right
				table.insert(keysPressed, Enum.KeyCode.D)
			else -- Left
				table.insert(keysPressed, Enum.KeyCode.A)
			end
		end

		if math.abs(z) > math.abs(x) or diagonal then -- Up/Down Movement
			if z > 0 then -- Down
				table.insert(keysPressed, Enum.KeyCode.S)
			else -- Up
				table.insert(keysPressed, Enum.KeyCode.W)
			end
		end

		-- Apply movement
		checkKeyPresence(Enum.KeyCode.W, keysPressed)
		checkKeyPresence(Enum.KeyCode.A, keysPressed)
		checkKeyPresence(Enum.KeyCode.S, keysPressed)
		checkKeyPresence(Enum.KeyCode.D, keysPressed)
	end
end

-- Convert MOBILE movement to actual movement
UserInputService.TouchMoved:Connect(function(input, gameProcessed)
	calculateAlternativeMovement()
end)

-- Convert Analog stick movement to actual movement
local usingControllerRef = player.PlayerGui.ControllerPrompt.UsingController
if usingControllerRef and usingControllerRef.Value then
	UserInputService.InputChanged:Connect(function(input, gameProcessed)
		calculateAlternativeMovement()
	end)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.ButtonA then
			boostShip()
		end
	end)
end




-- When player stops using joystick, stop moving the ship
UserInputService.TouchEnded:Connect(function(input, gameProcessed)
	script:FindFirstChild('Enum.KeyCode.W').Value = false
	script:FindFirstChild('Enum.KeyCode.A').Value = false
	script:FindFirstChild('Enum.KeyCode.S').Value = false
	script:FindFirstChild('Enum.KeyCode.D').Value = false
end)


--[[
	Because the hitbox and client-view of the ship model can be messed up, forcing them to go straight keeps the hitbox and client-model aligned
]]
function forceShipStraight(player)
	unregisterKeyPressed(Enum.KeyCode.A, false)
	unregisterKeyPressed(Enum.KeyCode.D, false)
end
forceShipStraightEvent.OnClientEvent:Connect(forceShipStraight)
clientForceShipStraightEvent.OnInvoke = forceShipStraight


-- This controller is reset when player dies, first joins the game, or when they're levelling up

-- Because this controller is reset on level-up, check what their key-presses are
for _,key in ipairs (UserInputService:GetKeysPressed()) do
	if key ~= Enum.KeyCode.A and key ~= Enum.KeyCode.D then
		registerKeyPressed(key, false)
	end
end
forceShipStraight()

------------------------<< Boost Management >>------------------------------------------------
local boostBarGUI = playerShip.GUI_Display.SurfaceGui.BoostBar
local background = boostBarGUI.Background
local BACKGROUND_X_SIZE = background.Size.X.Scale
local BACKGROUND_Y_SIZE = background.Size.Y.Scale
local boost = background.Boost
background.BackgroundTransparency = 1
boost.BackgroundTransparency = 1

-- Update the player's boost GUI when the boostAvailableRef changes
local appearBackgroundTween = TweenService:Create(background, TweenInfo.new(.7), {BackgroundTransparency = 1})
local appearBoostTween = TweenService:Create(boost, TweenInfo.new(.7), {BackgroundTransparency = 1})
boostAvailableRef.Changed:Connect(function(newValue)
	if newValue == 1 then -- Fade-out boostbar
		appearBackgroundTween:Play()
		appearBoostTween:Play()
	else
		appearBackgroundTween:Cancel()
		appearBoostTween:Cancel()
		background.BackgroundTransparency = 0
		boost.BackgroundTransparency = 0
		
		if boost.Size.Y.Scale == 1 then -- Emptying BoostBar
			background.BackgroundColor3 = Color3.fromRGB(0, 170, 255) -- Color effect
			TweenService:Create(background.Flash, TweenInfo.new(.1, Enum.EasingStyle.Linear), {BackgroundTransparency = 0}):Play()
			TweenService:Create(background, TweenInfo.new(.1, Enum.EasingStyle.Linear), {Size = UDim2.new(BACKGROUND_X_SIZE+.15, 0, BACKGROUND_Y_SIZE+.1)}):Play()
			wait(.3)
			TweenService:Create(background, TweenInfo.new(.45), {BackgroundColor3 = Color3.fromRGB(157, 157, 157)}):Play()
			TweenService:Create(background, TweenInfo.new(.3), {Size = UDim2.new(BACKGROUND_X_SIZE, 0, BACKGROUND_Y_SIZE)}):Play()
			wait(.07)
			TweenService:Create(background.Flash, TweenInfo.new(.1), {BackgroundTransparency = 1}):Play()
		end
	end
	boost.Size = UDim2.new(1, 0, newValue, 0)
end)

updatePointerArrows()




