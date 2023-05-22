local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")
local GuiUtility = require(script.Parent.Parent:WaitForChild('GuiUtility'))
local PopUpHandler = require(script.Parent.Parent:WaitForChild("Popups"):WaitForChild("PopUpHandler"))

local eventsFolder = game.ReplicatedStorage:WaitForChild('Events')
local clientDisplayMainMenuEvent = eventsFolder.GUI.ClientDisplayMainMenu
local displayAchievementMenuEvent = eventsFolder.GUI.ClientDisplayAchievementMenu
local displayAchievementPopUpEvent = eventsFolder.GUI.DisplayAchievementPopUp
local requestAchievementDataEvent = eventsFolder.RequestAchievementData
local claimAchievementEvent = eventsFolder.ClaimAchievement
local createPopUpEvent = eventsFolder.GUI.CreatePopUp

local guiElements = game.ReplicatedStorage:WaitForChild('GuiElements')
local physicalAchievementMenu = workspace:WaitForChild('AchievementMenu')
local achievementMenu = script.Parent:WaitForChild('AchievementMenu')
local barriers = script.Parent:WaitForChild('Barriers')
local backButton = barriers:WaitForChild('BackButton')
local amountDisplay = script.Parent:WaitForChild('AmountDisplay')
local rewardDisplay = physicalAchievementMenu:WaitForChild("AchievementPlatform"):WaitForChild("Display")

local pressSound = script.Parent.Parent.ButtonPress
local hoverSound = script.Parent.Parent.ButtonHover
local errorSound = script.Parent.Parent.Error
local switchSound = script.Parent.Parent.Switch

local LOCKED_STATIC = "rbxassetid://10084426105"
local LOCKED_HOVER = "rbxassetid://10084440734"
local LOCKED_PRESSED = "rbxassetid://10087162361"
local CLAIM_STATIC = "rbxassetid://10098368456"
local CLAIM_HOVER = "rbxassetid://10098396887"
local CLAIM_PRESSED = "rbxassetid://10098418226"
local CLAIMED_STATIC = "rbxassetid://10265810441"
local GENERALTILE_STATIC = "rbxassetid://9842202392"
local GENERALTILE_HOVER = "rbxassetid://9864919949"
local GENERALTILE_SELECTED = "rbxassetid://9866930927"
local WHITE_TEXT_COLOR = Color3.fromRGB(240, 240, 240)
local BLUE_TEXT_COLOR = Color3.fromRGB(1, 196, 255)


--[[
	Display the reward for the currently-selected achievement tile
	@param currentTile  Tile currently selected by the client
]]
local function displayTileInfo(currentTile)
	if currentTile then
		local achievementName = string.gsub(currentTile.TextLabel.Text, "<b>", "")
		achievementName = string.gsub(achievementName, "</b>", "")
		local status,value,achievementInfo = requestAchievementDataEvent:InvokeServer(achievementName)

		-- Reset all buttons to non-selected color except for newly-selected tile
		for _,page in pairs (achievementMenu:GetChildren()) do
			if page:IsA("Frame") and string.match(page.Name, "Page") ~= nil then
				for _,tile in pairs (page:GetChildren()) do
					if tile == currentTile then
						tile.Image = GENERALTILE_SELECTED
						tile.HoverImage = GENERALTILE_SELECTED
						tile.TextLabel.TextColor3 = WHITE_TEXT_COLOR
					else
						tile.Image = GENERALTILE_STATIC
						tile.HoverImage = GENERALTILE_HOVER
						tile.TextLabel.TextColor3 = BLUE_TEXT_COLOR
					end
				end
			end
		end

		-- Display the reward on the right side of the screen
		local reward = achievementInfo["Reward"]
		if typeof(reward) == "table" then
			if currentTile.ClaimButton.Image == CLAIMED_STATIC then
				achievementMenu.Claimed.Visible = true
			else
				achievementMenu.Claimed.Visible = false
			end
			
			if rewardDisplay:FindFirstChild("DisplayedItem") then
				rewardDisplay.DisplayedItem:Destroy()
			end
			
			local displayedItem
			if reward["Name"] then -- Show a rotating tablet with the name of the item (like an IOU)
				amountDisplay.Screen.Amount.Text = reward["Name"]
				if reward["Color"] then
					displayedItem = script.Parent.PaintSet:Clone()
					for _,colorPart in pairs (displayedItem.Paint:GetChildren()) do
						if not reward['Color']:FindFirstChild('ShipEffect') and colorPart:FindFirstChild('ShipEffect') then
							colorPart.ShipEffect:Destroy()
						end
						if colorPart.Name == "Color" then
							GuiUtility.applyColorData(colorPart, reward["Color"])
						end
						if colorPart.Name == 'Neon' then
							colorPart.Color = reward['Color'].Color
						end
					end
					
				elseif reward["Folder"].Parent == game.ReplicatedStorage.EquipData.Trails then
					displayedItem = script.Parent.TrailDisplay:Clone() -- Thrusters
					local thrusterEffect = reward["Folder"].Thruster:Clone()
					thrusterEffect.Parent = displayedItem.ThrusterDisplay.Thruster
					thrusterEffect.Speed = NumberRange.new(10)
					thrusterEffect.SpreadAngle = Vector2.new(0, 0)
					local laserEffect = reward["Folder"].Laser:Clone()
					laserEffect.Parent = displayedItem.LaserDisplay.Thruster
					laserEffect.Speed = NumberRange.new(10)
					laserEffect.SpreadAngle = Vector2.new(0, 0)
					
				end
				
				-- TODO: If ship show a blueprint for a ship
								
				
				
			else -- Need to update display to show the amount of currency that would be gained!
				amountDisplay.Screen.Amount.Text = tostring(GuiUtility.simplifyNumber(reward[3]))	
				if reward[2] == "Gems" then
					displayedItem = script.Parent.GemPile:Clone()
					amountDisplay.Screen.Amount.Text = amountDisplay.Screen.Amount.Text .. " Gems"
				else
					displayedItem = script.Parent.CoinPile:Clone()
					amountDisplay.Screen.Amount.Text = amountDisplay.Screen.Amount.Text .. " Coins"
				end
			end
			
			displayedItem.Parent = rewardDisplay
			displayedItem.Name = "DisplayedItem"
			displayedItem:SetPrimaryPartCFrame(rewardDisplay.CFrame)
		else
			warn("No reward for achievement: ", achievementInfo)
		end
	end
end

--[[
	Load pages, load tiles, and denote what happens when those tiles are clicked
]]
local function fillAchievementMenu()
	local TILES_PER_PAGE = 5
	local achievementData, achievementCount = requestAchievementDataEvent:InvokeServer()
	GuiUtility.pageLoad(achievementMenu, achievementData, achievementCount)

	-- For each tile, check which button type it should have (claim, claimed, or locked)
	for _,page in pairs (achievementMenu:GetChildren()) do
		if page:IsA("Frame") and string.match(page.Name, "Page") ~= nil then
			for _,tile in pairs (page:GetChildren()) do
				if tile:IsA("ImageButton") and string.match(tile.Name, "Tile") ~= nil then
					local achievementName = string.gsub(tile.TextLabel.Text, "</b>", "")
					achievementName = string.gsub(achievementName, "<b>", "")

					-- Check achievement
					local status,value,specificData = requestAchievementDataEvent:InvokeServer(achievementName)
					print("STATUS FOR " .. achievementName .. " is " .. tostring(status))
					if status == "Claim" then
						tile.ClaimButton.Image = CLAIM_STATIC
						tile.ClaimButton.HoverImage = CLAIM_HOVER
						tile.ClaimButton.PressedImage = CLAIM_PRESSED
					elseif status == "Claimed" then
						tile.ClaimButton.Image = CLAIMED_STATIC
						tile.ClaimButton.HoverImage = CLAIMED_STATIC
						tile.ClaimButton.PressedImage = CLAIMED_STATIC
					else -- Locked
						tile.ClaimButton.Image = LOCKED_STATIC
						tile.ClaimButton.HoverImage = LOCKED_HOVER
						tile.ClaimButton.PressedImage = LOCKED_PRESSED
					end
					
					-- Depending on the achievementType, display either #/# or Highscore
					local tracker = specificData["ReferenceTracker"]
					if string.match(tracker, "Best") == "Best" then -- Highscore-based
						tile.Progress.Text = "Best: " .. value
						
						if string.match(tracker, "Kills") then
							tile.Progress.Text = tile.Progress.Text .. " Kills"
						elseif string.match(tracker, "Time") then
							tile.Progress.Text = GuiUtility.ToDHMS(value)
						elseif string.match(tracker, "Level") then
							tile.Progress.Text = tile.Progress.Text .. " Levels"
						elseif string.match(tracker, "Coins") then
							tile.Progress.Text = tile.Progress.Text .. " Materials"
						end
					else -- Must be a Sum achievement
						local denomenator = specificData["ReferenceAmount"]
						if string.match(tracker, "Time") then -- Convert to minutes
							tile.Progress.Text = GuiUtility.ToDHMS(tonumber(value)) .. "/" .. GuiUtility.ToDHMS(denomenator)
						else
							tile.Progress.Text = value .. "/" .. tostring(denomenator)
						end
					end
					
					-- Give functionality to the tiles when they're clicked
					tile.Activated:Connect(function()
						pressSound:Play()
						achievementMenu.TileName.Value = achievementName
						displayTileInfo(tile)
					end)
					GuiUtility.resizeButtonEffect(tile, hoverSound)
					
					-- Give functionality to ClaimButton
					local claimButton = tile.ClaimButton
					claimButton.Activated:Connect(function()
						if claimButton.Image == CLAIM_STATIC then -- Claim achievement (if possible)
							local success = claimAchievementEvent:InvokeServer(achievementName)
							if success then
								script.Parent.AchievementClaim:Play()
								
								claimButton.Image = CLAIMED_STATIC
								claimButton.HoverImage = CLAIMED_STATIC
								claimButton.PressedImage = CLAIMED_STATIC
								
								if achievementMenu.TileName.Value == achievementName then
									achievementMenu.Claimed.Visible = true
								end
							end	
						else -- Locked or already claimed
							errorSound:Play()
						end
					end)
				end
			end
		end
	end
end

--[[
	Load the achievement menu; the player pressed the AchievementButton on the main menu
	@param display  True if the achievement menu should be displayed
]]
displayAchievementMenuEvent.Event:Connect(function(display)
	for _,gui in pairs (script.Parent:GetChildren()) do
		pcall(function()
			gui.Visible = false
		end)
	end
	amountDisplay.Screen.Amount.Text = ""
	
	if display then
		clientDisplayMainMenuEvent:Fire(false) -- Invis main menu

		-- Move the camera into the proper position
		local cameraTweenInfo = TweenInfo.new(3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		TweenService:Create(camera, cameraTweenInfo, {CFrame = physicalAchievementMenu.AchievementMenuCamera.CFrame}):Play()
		
		-- Load the pages that will be displayed on the menu
		fillAchievementMenu()
		
		wait(camera.CFrame == physicalAchievementMenu.AchievementMenuCamera.CFrame)
		-- Display the achievement menu
		local barrierTweenInfo = TweenInfo.new(.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		barriers.TopBarrier.Position = UDim2.new(0, 0, -0.1, 0)
		barriers.BottomBarrier.Position = UDim2.new(0, 0, 1.1, 0)
		barriers.BackButton.Position = UDim2.new(barriers.BackButton.Position.X.Scale, 0, 1.1, 0)
		barriers.MenuLabel.Position = UDim2.new(0.5, 0, -.15, 0)
		for _,gui in pairs (script.Parent:GetChildren()) do
			pcall(function()
				gui.Visible = true
			end)
		end
		TweenService:Create(barriers.BottomBarrier,  barrierTweenInfo, {Position = UDim2.new(0, 0, 0.905, 0)}):Play()
		TweenService:Create(barriers.TopBarrier,  barrierTweenInfo, {Position = UDim2.new(0, 0, -0.035, 0)}):Play()
		TweenService:Create(barriers.BackButton,  barrierTweenInfo, {Position = UDim2.new(barriers.BackButton.Position.X.Scale, 0, 0.887, 0)}):Play()
		
		-- Display the first page
		if achievementMenu:FindFirstChild("Page1") then
			achievementMenu.Page1.Position = UDim2.new(-0.55, 0, 0, 0)
			achievementMenu.UpArrow.Position = UDim2.new(-0.2, 0, achievementMenu.UpArrow.Position.Y.Scale, 0)
			achievementMenu.DownArrow.Position = UDim2.new(-0.2, 0, achievementMenu.DownArrow.Position.Y.Scale, 0)
			
			local tweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			TweenService:Create(achievementMenu.Page1, tweenInfo, {Position = UDim2.new(0, 0, 0, 0)}):Play()
			TweenService:Create(achievementMenu.UpArrow, tweenInfo, {Position = UDim2.new(0.235, 0, 0.078, 0)}):Play()
			TweenService:Create(achievementMenu.DownArrow, tweenInfo, {Position = UDim2.new(0.235, 0, 0.88, 0)}):Play()
			
			-- Select the first item
			displayTileInfo(achievementMenu.Page1:FindFirstChild("Tile1"))
		end
		wait(.5)
		TweenService:Create(barriers.MenuLabel,  barrierTweenInfo, {Position = UDim2.new(.5, 0, .034, 0)}):Play()
		
	else -- Reset the achievement menu
		for _,page in pairs (achievementMenu:GetChildren()) do
			if page:IsA("Frame") and string.match(page.Name, "Page") ~= nil then
				page:Destroy()
			end
		end
		
		-- Fade out and display the main menu
		wait(GuiUtility.blackMenuFade(true, 0.05))
		clientDisplayMainMenuEvent:Fire(true)
		wait(0.5)
		GuiUtility.blackMenuFade(false, 0.05)
	end
end)

achievementMenu.UpArrow.MouseEnter:Connect(function()
	hoverSound:Play()
end)
achievementMenu.DownArrow.MouseEnter:Connect(function()
	hoverSound:Play()
end)
achievementMenu.UpArrow.Activated:Connect(function()
	GuiUtility.changePage(achievementMenu, -1)
end)
achievementMenu.DownArrow.Activated:Connect(function()
	GuiUtility.changePage(achievementMenu, 1)
end)

--[[
	Go back to the main menu after the player pressed the back button
]]
local backButtonAvailable = true
backButton.Activated:Connect(function()
	if backButtonAvailable then
		backButtonAvailable = false
		pressSound:Play()
		
		wait(GuiUtility.blackMenuFade(true, 0.05))
		clientDisplayMainMenuEvent:Fire(true, false)
		wait(0.5)
		displayAchievementMenuEvent:Fire(false) 
		wait(GuiUtility.blackMenuFade(false, 0.05))

		backButtonAvailable = true
	end
end)

--[[
	Communication from stat management to make an achievement popup upon reaching achievement criteria
	@param newPopUp  PopUp that will be used to showcase achievement gained
	@param text1  Name of the achievement that was gained
]]
createPopUpEvent.OnClientEvent:Connect(function(newPopUp, text1)
	PopUpHandler.createPopUp(newPopUp, text1)
end)
