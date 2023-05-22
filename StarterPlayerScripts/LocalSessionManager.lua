local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService('SoundService')

local eventsFolder = game.ReplicatedStorage:WaitForChild('Events')
local initiatePlayerControlEvent = eventsFolder:WaitForChild('InitiatePlayerControl')
local removePlayerControlEvent = eventsFolder:WaitForChild('RemovePlayerControl')
local clientPlaceShipInGameEvent = eventsFolder:WaitForChild('ClientPlaceShipInGame')
local clientDestroyPlayerShipEvent = eventsFolder:WaitForChild('ClientDestroyPlayerShip')
local spawnShipPopUpEvent = eventsFolder:WaitForChild('SpawnShipPopUp')

local guiEventsFolder = eventsFolder:WaitForChild('GUI')
local updateGUI_DisplayEvent = guiEventsFolder:WaitForChild('UpdateGUI_DisplayEvent')
local resetPressedEvent = guiEventsFolder:WaitForChild('ResetPressed')

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
	Destroy player ship when they press the reset button
]]
resetPressedEvent.Event:Connect(function()
	clientDestroyPlayerShipEvent:FireServer(true, true)
end)

--[[
	Create explosion effect where player died
	@param playerShipPosition  Position the ship was destroyed at
]]
local function explosionEffect(playerShipPosition)
	local deathExplosion = game.ReplicatedStorage.Effects.DeathExplosion:Clone()
	deathExplosion.Parent = workspace
	deathExplosion.Position = playerShipPosition
	SoundService:PlayLocalSound(deathExplosion.ExplosionSound)
	wait(.2)
	deathExplosion.Explosion.Enabled = false
	deathExplosion.Smoke.Enabled = false
	
	-- Move Skull
	local skull = deathExplosion.Skull
	skull.SurfaceGui.ImageLabel.ImageTransparency = 0
	skull.Position = playerShipPosition + Vector3.new(0, 3, 0)
	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
	TweenService:Create(skull, TweenInfo.new(1.5), {Position = skull.Position}):Play() -- Keep in position
	TweenService:Create(skull, tweenInfo, {Size = Vector3.new(skull.Size.X + 7, skull.Size.Y, skull.Size.Z + 7)}):Play()
	
	-- Fade out skull
	wait(2)
	for t = 1,20 do
		wait(.03)
		skull.SurfaceGui.ImageLabel.ImageTransparency += 0.05
	end
	wait(1)
	deathExplosion:Destroy()
end

--[[
	Called by server when it's time to destroy the player ship. Replicated to all clients
	@param playerUserId  UserId of the player whose ship is destroyed
	@param reset  If player used the reset button
]]
clientDestroyPlayerShipEvent.OnClientEvent:Connect(function(playerUserId)
	local playerShip = workspace.Ships:FindFirstChild(tostring(playerUserId) .. "'s Ship")
	if playerShip then
		local playerShipPosition = playerShip.Position
		playerShip:Destroy()
		explosionEffect(playerShipPosition)
		
		applyColorScriptEffects(playerUserId)
		
		-- OLD: Broken-Heart Symbol
		--local healthBar = playerShip.GUI_Display.SurfaceGui.HealthBar.Background
		--healthBar.TextLabel.Visible = false
		--healthBar.BrokenHeart.Visible = true
		
		-- Reset KeyCode Booleans
		for _,bool in pairs (script:WaitForChild('LocalController'):GetChildren()) do
			if bool:IsA('BoolValue') then
				bool.Value = false
			end
		end
		
		-- Camera zoom out (only for destroyed player)
		if player.UserId == playerUserId then
			
			-- Check to see if player has already gone to the menu
			if not player.PlayerGui.MainMenu.MainMenu.Visible then
				TweenService:Create(
					camera, 
					TweenInfo.new(3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), 
					{CFrame = camera.CFrame + Vector3.new(0, 100, 0)}
				):Play()
			end
		end
	end
end)


-- Prevent player from seeing other players loaded into game
local function invisPlayers()
	for _,player in pairs (workspace.Players:GetChildren()) do

		-- Keep track of who you have already invised
		if not player:FindFirstChild("Invised") then
			local invisRef = Instance.new("BoolValue", player)
			invisRef.Name = "Invised"
			invisRef.Value = false
		end

		if not player.Invised.Value then
			for _,part in pairs (player:GetChildren()) do
				if (part:IsA("BasePart")) then
					part.Transparency = 1
				end
			end
			player.Invised.Value = true
		end
	end
end

--[[
	Give player Local controller now that they're in-game
	@param levelUp: True if from levelUp, check if hitbox exists
]]
initiatePlayerControlEvent.OnClientEvent:Connect(function(levelUp)
	camera.FieldOfView = 70 -- Reset after likely camera bobbing in menu
	script.LocalController.Disabled = false
	script.CameraMovement.Disabled = false
end)

removePlayerControlEvent.OnClientEvent:Connect(function(noInvis)
	script.LocalController.Disabled = true
	script.CameraMovement.Disabled = true
	if not noInvis then
		invisPlayers() -- Call every control remove in case new players joined
	end
end)

--[[
	Client is responsible for positioning the physical ship (not hitbox) into the game
	@param playerShip  Model info of ship (reference stored within player, alreadyed colored/trailed)
	@param levelUp: True if the player is leveling up (ensure the player has hitbox in game)
]]
clientPlaceShipInGameEvent.OnClientEvent:Connect(function(playerShip, levelUp)
	if workspace.Ships:FindFirstChild(tostring(player.UserId) .. "'s Ship") then
		local oldShip = workspace.Ships:FindFirstChild(tostring(player.UserId) .. "'s Ship")
		if oldShip:FindFirstChild("MatSpawnerPointerArrow") then
			oldShip.MatSpawnerPointerArrow.Parent = playerShip
		end
		
		oldShip:Destroy()
	end

	playerShip = playerShip:Clone()
	playerShip.Name = tostring(player.UserId) .. "'s Ship"
	playerShip.Parent = workspace.Ships
	playerShip.CFrame = workspace.Ships:WaitForChild(tostring(player.UserId) .. "'s Hitbox").CFrame
	applyColorScriptEffects(player.UserId, playerShip)
	
	-- Move Ship's CFrame to y-value of 0
	playerShip.CFrame *= CFrame.new(0, -playerShip.Position.Y, 0)
	
	-- Must update position of GUI_Display as well since it is not welded to the main Handle
	local upAmount = 10
	local usingControllerRef = player.PlayerGui.ControllerPrompt.UsingController
	if usingControllerRef and usingControllerRef.Value then
		upAmount = 20
	end
	if playerShip:FindFirstChild('GUI_Display') then
		playerShip.GUI_Display.Position = playerShip.Position + Vector3.new(0, upAmount, 0) -- up a bit
		playerShip.GUI_Display.CFrame *= CFrame.new(0, 0, playerShip.GUI_Display.Distance.Value) -- Offset downward by set amount for that ship
	end
end)

--[[
	Spawn a small pop up near the player's GUI_Display for player-driven feedback
	[NOT REPLICATED ACROSS ALL CLIENTS, ONLY PLAYER SEES THEIR OWN POP UPS]
	@param popUp  The popUp that will be shown (already made and ready to go, simply has to be displayed)
]]
spawnShipPopUpEvent.OnClientEvent:Connect(function(popUp)
	if workspace.Ships:FindFirstChild(tostring(player.UserId) .. "'s Ship") then
		local playerShip = workspace.Ships:FindFirstChild(tostring(player.UserId) .. "'s Ship")
		local guiDisplay = playerShip.GUI_Display
		
		popUp.Parent = guiDisplay
		popUp.Position = Vector3.new(
			guiDisplay.Position.X+3.749,
			guiDisplay.Position.Y+0.505,
			guiDisplay.Position.Z+1.629
		)

		-- Add as a debris so it expires after some time
		local PLAY_LENGTH = 1
		Debris:AddItem(popUp, PLAY_LENGTH+.5)

		coroutine.resume(coroutine.create(function()
			-- Move and rotate popUp
			local tweenInfo = TweenInfo.new(
				PLAY_LENGTH,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out,
				0
			)
			local tween = TweenService:Create(popUp, tweenInfo, {Position = Vector3.new(
				popUp.Position.X + 3.394,
				popUp.Position.Y + 2,
				popUp.Position.Z - 4.089
				)})
			tween:Play()
			tween = TweenService:Create(popUp, tweenInfo, {Orientation = Vector3.new(
				popUp.Orientation.X,
				popUp.Orientation.Y - 20,
				popUp.Orientation.Z
				)})
			tween:Play()

			-- Fade out the GUI
			for i = 1,20 do
				wait(PLAY_LENGTH/20)
				if popUp:FindFirstChild("SurfaceGui") then -- Can sometimes error if ship destroyed
					popUp.SurfaceGui.Frame.TextLabel.TextTransparency += PLAY_LENGTH/20
				end
			end
		end))
	end
end)

--[[
	Appropriately update the GUI_Display for some playerName's Ship
	@param playerUserId  UserId of the player whose ship's health bar is updating
	@param propHealth  Proportion of player's health remaining
	@param totalMaterials  The amount of materials the player has
]]
local function updateGUI_Display(playerUserId, propHealth, totalMaterials)
	local playerShip = workspace.Ships:FindFirstChild(tostring(playerUserId) .. "'s Ship")
	
	if playerShip then
		local healthBar = playerShip.GUI_Display.SurfaceGui.HealthBar
		local materialDisplay = playerShip.GUI_Display.SurfaceGui.PlayerInfo.MaterialCount
		
		if propHealth ~= nil then -- Show and update health bar	
			if propHealth < 1 then
				healthBar.Visible = true
				healthBar.Background.Health.Size = UDim2.new(1, 0, propHealth, 0)
			else
				healthBar.Background.Health.Size = UDim2.new(1, 0, 1, 0)

				-- TODO: Special animation for getting full health?
				
				
				healthBar.Visible = false
			end	
		end
		
		-- Update the display for how many materials the player has
		local materialDisplay = playerShip.GUI_Display.SurfaceGui.PlayerInfo.MaterialCount
		materialDisplay.Text = tostring(totalMaterials)
	end
end
updateGUI_DisplayEvent.OnClientEvent:Connect(updateGUI_Display)

-- Start local game
wait(game.Players.LocalPlayer == nil)
eventsFolder:WaitForChild('StartPlayer'):FireServer()

