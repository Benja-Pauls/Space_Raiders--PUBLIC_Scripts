local TweenService = game:GetService("TweenService")
local GuiUtility = require(script.Parent.Parent:WaitForChild("GuiUtility"))
local MusicPlayer = require(script.Parent.Parent:WaitForChild("Music"):WaitForChild("MusicPlayer"))

local eventsFolder = game.ReplicatedStorage:WaitForChild('Events')
local guiEventsFolder = eventsFolder:WaitForChild("GUI")
local updateGUIEvent = guiEventsFolder:WaitForChild('UpdateGUI')
local displayMainMenuEvent = guiEventsFolder:WaitForChild('DisplayMainMenu')
local clientDisplayMainMenuEvent = guiEventsFolder:WaitForChild('ClientDisplayMainMenu')
local displayMyShipMenuEvent = guiEventsFolder:WaitForChild('ClientDisplayMyShipMenu')
local displayAchievementMenuEvent = guiEventsFolder:WaitForChild('ClientDisplayAchievementMenu')
local displayShopMenuEvent = guiEventsFolder:WaitForChild('ClientDisplayShopMenu')
local getCurrenciesEvent = guiEventsFolder:WaitForChild("GetCurrencies")
local displayGemShopMenuEvent = guiEventsFolder:WaitForChild('ClientDisplayGemShopMenu')
local displayCoinShopMenuEvent = guiEventsFolder:WaitForChild('ClientDisplayCoinShopMenu')
local displayCodeMenuEvent = guiEventsFolder:WaitForChild('ClientDisplayCodeMenu')
local displayBoostMenuEvent = guiEventsFolder:WaitForChild('ClientDisplayBoostMenu')
local checkTutorialProgressEvent = eventsFolder:WaitForChild('CheckTutorialProgress')
local getEquippedInfoEvent = eventsFolder:WaitForChild('GetEquippedInfo')
local requestAchievementDataEvent = eventsFolder:WaitForChild('RequestAchievementData')

local camera = game.Workspace.CurrentCamera
local player = game.Players.LocalPlayer
local mainMenu = script.Parent:WaitForChild("MainMenu")
local gameTitle = script.Parent:WaitForChild("TitleFrame"):WaitForChild("GameTitle")

local playButton = mainMenu:WaitForChild('PlayButton')
local shipButton = mainMenu:WaitForChild('ShipButton')
local shopButton = mainMenu:WaitForChild('ShopButton')
local achievementsButton = mainMenu:WaitForChild('AchievementsButton')

local buttonHoverSound = script.Parent.Parent:WaitForChild("ButtonHover")
local buttonPressSound = script.Parent.Parent:WaitForChild("ButtonPress")
local menuOpenSound = script.Parent.Parent:WaitForChild("MenuOpen")

local function simpleAddHoverSound(button)
	button.MouseEnter:Connect(function()
		buttonHoverSound:Play()
	end)
end

-------------------<< Menu Management >>--------------------------
local tweenEnabled = true
local menuButtonDebounce = false
local myShipMenu = script.Parent.Parent:WaitForChild('MyShipMenu')
local achievementMenu = script.Parent.Parent:WaitForChild('AchievementMenu')
local shopMenu = script.Parent.Parent:WaitForChild('ShopMenu')

--[[Update the values presented in the currency displays]]
local function updateCurrencies()
	local coins,gems = getCurrenciesEvent:InvokeServer()
	if coins ~= nil then
		mainMenu.Coins.Outline.TextLabel.Text = GuiUtility.simplifyNumber(coins)
		mainMenu.Gems.Outline.TextLabel.Text = tostring(gems)
	end
end

--[[
	Simple utility function to invis entire menu
	@param menu  Menu to be invised
]]
local function invisSubMenu(menu)
	for _,gui in pairs (menu:GetChildren()) do
		if gui:IsA("Frame") then
			gui.Visible = false
		end
	end
end

--[[
	Change if the main menu is being displayed or not
	@param display  True if main menu should be displayed
	@param special  Simple fade-out rather than moving GUI objects
	@param nofade  True when special but no black fade required
]]
local function displayMainMenu(display, special, nofade)
	local tweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	
	if display then
		script.Parent.Parent.Music.BobEnabled.Value = true
		invisSubMenu(myShipMenu)
		invisSubMenu(achievementMenu)
		invisSubMenu(shopMenu)
		
		updateEventProgress()
		
		-- Update the PlayerInfo Frame
		updateCurrencies()
		GuiUtility.displayPlayerShip(player, mainMenu:WaitForChild('PlayerInfo').ShipViewPort, 1)
		mainMenu.PlayerInfo:FindFirstChild("Name").Text = tostring(player) .. "'s Ship"
		
		-- Move camera to eagle-eyed view of the map
		local spawnCamera = workspace:WaitForChild("SpawnCamera")
		camera.CameraType = "Scriptable"
		camera.CameraSubject = spawnCamera:WaitForChild('NewSubject')
		camera.CFrame = spawnCamera.CFrame
		
		-- Determine if BoostedIcon should be visible
		if player:FindFirstChild("BoostedStart") then
			playButton.BoostedIcon.Visible = true
		else
			playButton.BoostedIcon.Visible = false
		end
		
		-- Display changed values depending on what was displayed on death screen
		local deathScreen = script.Parent.Parent:WaitForChild('DeathScreen'):WaitForChild('DeathScreen')
		local coinChange = deathScreen:WaitForChild('Coins'):WaitForChild('ChangeDisplay')
		local gemChange = deathScreen:WaitForChild('Gems'):WaitForChild('ChangeDisplay')
		mainMenu:WaitForChild('Coins'):WaitForChild('ChangeDisplay').Text = coinChange.Text
		mainMenu.Coins.ChangeDisplay.TextColor3 = coinChange.TextColor3
		mainMenu:WaitForChild('Gems'):WaitForChild('ChangeDisplay').Text = gemChange.Text
		mainMenu.Gems.ChangeDisplay.TextColor3 = gemChange.TextColor3
		
		-- Display the main menu GUI
		mainMenu.Visible = true
		gameTitle.Parent.Visible = true
		gameTitle.Visible = true
		TweenService:Create(gameTitle, tweenInfo, {Position = UDim2.new(0.5, 0, 0.545, 0)}):Play()
		mainMenu:WaitForChild('PlayerInfo').Visible = true
		mainMenu.UpdateNews.Visible = false
		mainMenu.PlayerInfo.Visible = true
		
		-- Display the Calling Card w/ Appropriate Info
		local callingCard = mainMenu:WaitForChild('CallingCard')
		callingCard.Visible = true
		TweenService:Create(callingCard, tweenInfo, {Position = UDim2.new(0.05, 0, 0.836, 0)}):Play()
		callingCard.Username.Text = player.Name
		callingCard.ProfilePic.Image = game.Players:GetUserThumbnailAsync(
			player.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size420x420
			
		)
		callingCard.Title.Text = getEquippedInfoEvent:InvokeServer(player)[8]
		local status,value,achievementInfo = requestAchievementDataEvent:InvokeServer("Novice Pilot")
		callingCard["Career Kills"].Text = "Career Kills: " .. tostring(value)
		
		-- Ensure that all the elements on the main menu are visible
		TweenService:Create(mainMenu.Gems, tweenInfo, {Position = UDim2.new(0.877, 0, 0.755, 0)}):Play()
		TweenService:Create(mainMenu.Coins, tweenInfo, {Position = UDim2.new(0.876, 09, 0.536, 0)}):Play()
		-- TweenService:Create(mainMenu.BottomInfo, tweenInfo, {Position = UDim2.new(0.239, 0, 0.926, 0)}):Play()
		TweenService:Create(mainMenu.SkeletonShipEvent, tweenInfo, {Position = UDim2.new(0.326, 0, 0.489, 0)}):Play()
		TweenService:Create(mainMenu.PlayerInfo, tweenInfo, {Position = UDim2.new(0.55, 0, 0.282, 0)}):Play()
		TweenService:Create(mainMenu.Codes, tweenInfo, {Position = UDim2.new(0.818, 0, 0.914, 0)}):Play()
		
		
		-- Display the first-time tutorial if this is first time player has joined (or they have not interacted with tutorial yet)
		local firstJoin = checkTutorialProgressEvent:InvokeServer("FirstJoin2")
		if not firstJoin then
			local tutorialGUI = script.Parent.Parent:WaitForChild('TutorialPopups'):WaitForChild('FirstJoin')
			local tutorialScript = tutorialGUI:WaitForChild('TutorialHandler')
			tutorialScript.Disabled = true; tutorialScript.Disabled = false -- Reset everything within the script
			tutorialGUI:WaitForChild('TutorialHandler'):WaitForChild('Trigger'):Fire()
		end
		
		wait(2) -- Ensure player has appropriate background
		if camera.CFrame ~= spawnCamera.CFrame then
			camera.CFrame = spawnCamera.CFrame
		end
	else
		script.Parent.Parent:WaitForChild('Music'):WaitForChild('BobEnabled').Value = false
		script.Parent.Parent:WaitForChild('FirstOpenNotify'):WaitForChild('Notify').Visible = false
		script.Parent.Parent:WaitForChild('FirstOpenNotify'):WaitForChild('FirstOpenNotifyHandler').Enabled = false
		if special then
			if not nofade then
				GuiUtility.blackMenuFade(true, 0.05)
			end
			mainMenu.Visible = false
			gameTitle.Visible = false
			invisSubMenu(myShipMenu)
			invisSubMenu(achievementMenu)
			invisSubMenu(shopMenu)
		else
			local positionInfo = {}
			for _,gui in pairs (mainMenu:GetChildren()) do
				if gui:FindFirstChild("TweenMove") then
					table.insert(positionInfo, gui.Position)
					local xMove = gui:WaitForChild('TweenMove').Value.X
					local yMove = gui:WaitForChild('TweenMove').Value.Y
					if xMove == 0 then
						xMove = gui.Position.X.Scale
					end
					if yMove == 0 then
						yMove = gui.Position.Y.Scale
					end
					local pos = UDim2.new(xMove, 0, yMove, 0)
					TweenService:Create(gui, tweenInfo, {Position = pos}):Play()
				end
			end

			-- Move game title
			TweenService:Create(gameTitle, tweenInfo, {Position = UDim2.new(0.5, 0, 0.3)}):Play()
			wait(0.7)

			-- Invis MainMenu and move all GUI back
			mainMenu.Visible = false
			gameTitle.Visible = false
			for i,gui in pairs (mainMenu:GetChildren()) do
				if gui:FindFirstChild("TweenMove") then
					gui.Position = positionInfo[i]
				end
			end
		end
	end
	tweenEnabled = true
end
displayMainMenuEvent.OnClientEvent:Connect(displayMainMenu)
clientDisplayMainMenuEvent.Event:Connect(displayMainMenu)
script.Parent.Parent:WaitForChild('ControllerPrompt'):WaitForChild('MainMenuReady').Value = true


-----------------<<|| Limited Event Functionality ||>>--------------------------------------------------------------
local skeletonShipUI = mainMenu:WaitForChild('SkeletonShipEvent')
local skeletonShipEvent = eventsFolder:WaitForChild('SkeletonShipEvent')

--[[
	Begin counting down on the timeNotify GUI
	@param textLabel: TextLabel that will be updated to represent the time
	@param timeLeft  Time left, in seconds, until player can claim daily reward
]]
local function startCountdown(textLabel, timeLeft)
	coroutine.resume(coroutine.create(function()
		while playButton.Visible do -- While the main menu is open
			textLabel.Text = GuiUtility.ToDHMS(timeLeft, true)
			timeLeft -= 1
			wait(60)

			if timeLeft < 0 then -- Event has expired while player was watching menu
				skeletonShipUI.Visible = false
			end
		end
	end))
end

--[[
	Update the player's progress with the skeleton ship event
]]
function updateEventProgress()
	-- Update the timer continuously
	local HALLOWEEN_END_TICK = 1667278800; local currentTick = os.time()
	local timeLeft = HALLOWEEN_END_TICK - currentTick
	if timeLeft < 1 then
		skeletonShipUI.Visible = false
	else
		local achievedKills = skeletonShipEvent:InvokeServer()

		if achievedKills ~= "Already Purchased" then
			if achievedKills > 99 then
				skeletonShipUI.Done.Visible = true
				skeletonShipUI.BackgroundColor3 = skeletonShipUI.Done.BackgroundColor3
				skeletonShipUI.BackgroundTransparency = 0

				-- Update the player's data
				skeletonShipEvent:InvokeServer(true)
			else
				skeletonShipUI.Done.Visible = false

				-- Display that amount
				skeletonShipUI.Count.Text = tostring(achievedKills) .. "/100 Kills"

				local percentageComplete = achievedKills/100
				skeletonShipUI.Progress.Bar.Size = UDim2.new(percentageComplete, 0, 1, 0)
			end
		else
			skeletonShipUI.Done.Visible = true
			skeletonShipUI.BackgroundColor3 = skeletonShipUI.Done.BackgroundColor3
			skeletonShipUI.BackgroundTransparency = 0
		end
		
		skeletonShipUI.Visible = true
		startCountdown(skeletonShipUI.TimerBar.TextLabel, timeLeft)
	end
end




-----------------<< Player Info Frame Management >>-----------------------------------------------------------------
local playerInfoFrame = mainMenu.PlayerInfo
local levelFrame = playerInfoFrame.LevelFrame

levelFrame.RightArrow.Activated:Connect(function()
	local currentLevel = string.gsub(levelFrame.Level.Text, "Level ", "")
	currentLevel = tonumber(currentLevel)
	
	local newLevel = 1
	if currentLevel < 10 then
		newLevel = currentLevel + 1
	end
	levelFrame.Level.Text = "Level " .. tostring(newLevel)
	GuiUtility.displayPlayerShip(player, playerInfoFrame.ShipViewPort, newLevel)
end)
levelFrame.LeftArrow.Activated:Connect(function()
	local currentLevel = string.gsub(levelFrame.Level.Text, "Level ", "")
	currentLevel = tonumber(currentLevel)

	local newLevel = 10
	if currentLevel > 1 then
		newLevel = currentLevel - 1
	end
	levelFrame.Level.Text = "Level " .. tostring(newLevel)
	GuiUtility.displayPlayerShip(player, playerInfoFrame.ShipViewPort, newLevel)
end)

local hideAvailable = true
playerInfoFrame.DisplayNewsButton.Activated:Connect(function()
	if hideAvailable then
		hideAvailable = false
		buttonPressSound:Play()
		local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quint)
		
		-- Move away the playerInfoFrame
		buttonPressSound:Play()
		TweenService:Create(
			playerInfoFrame, 
			tweenInfo, 
			{Position = UDim2.new(playerInfoFrame.Position.X.Scale, 0, playerInfoFrame.TweenMove.Value.Y, 0)}
		):Play()
		
		-- Move the news into position
		mainMenu.UpdateNews.Position = UDim2.new(mainMenu.UpdateNews.Position.X.Scale, 0, mainMenu.UpdateNews.TweenMove.Value.Y, 0)
		mainMenu.UpdateNews.Visible = true
		wait(tweenInfo.Time-0.1)
		TweenService:Create(
			mainMenu.UpdateNews,
			tweenInfo,
			{Position = UDim2.new(mainMenu.UpdateNews.Position.X.Scale, 0, 0.267, 0)}
		):Play()
		wait(tweenInfo.Time)
		playerInfoFrame.Visible = false
		hideAvailable = true
	end
end)

-----------------<< Button Behavior >>------------------------------------------------------------------------------
script.PlayButtonPosition_X.Value = playButton.Position.X.Scale
script.PlayButtonPosition_Y.Value = playButton.Position.Y.Scale
script.ShipButtonPosition_X.Value = shipButton.Position.X.Scale
script.ShipButtonPosition_Y.Value = shipButton.Position.Y.Scale
script.ShopButtonPosition_X.Value = shopButton.Position.X.Scale
script.ShopButtonPosition_Y.Value = shopButton.Position.Y.Scale
script.AchievementsButtonPosition_X.Value = achievementsButton.Position.X.Scale
script.AchievementsButtonPosition_Y.Value = achievementsButton.Position.Y.Scale

--[[
	Return all buttons in the main menu to their default positions
]]
local function resetMenuButtons()
	playButton.Position = UDim2.new(script:WaitForChild('PlayButtonPosition_X').Value, 0, script:WaitForChild('PlayButtonPosition_Y').Value, 0)
	shipButton.Position = UDim2.new(script:WaitForChild('ShipButtonPosition_X').Value, 0, script:WaitForChild('ShipButtonPosition_Y').Value, 0)
	shopButton.Position = UDim2.new(script:WaitForChild('ShopButtonPosition_X').Value, 0, script:WaitForChild('ShopButtonPosition_Y').Value, 0)
	achievementsButton.Position = UDim2.new(script:WaitForChild('AchievementsButtonPosition_X').Value, 0, script:WaitForChild('AchievementsButtonPosition_Y').Value, 0)
end


--[[
	Spawn in player ship and close the main menu
]]
playButton.Activated:Connect(function()
	if not menuButtonDebounce then
		menuButtonDebounce = true
		tweenEnabled = false
		playButton:WaitForChild('FirstSound'):Play()
		displayMainMenu(false, true) -- close the main menu (fade effect player sees)
		
		-- Ensure player control
		if workspace.Ships:FindFirstChild(tostring(player.UserId) .. "'s Ship") then
			workspace.Ships:FindFirstChild(tostring(player.UserId) .. "'s Ship"):Destroy()
		end
		
		-- Invis the boosted icon since it has been applied (if vis in first place)
		playButton.BoostedIcon.Visible = false
		
		MusicPlayer.stopMusic(2)
		wait(1)
		displayMainMenuEvent:FireServer(player) -- restart the player ship
		MusicPlayer.playSong("InGame", "Space Raider Chase", nil, false, false, "InGame")
		wait(0.4)
		-- playButton:WaitForChild('SecondSound'):Play()
		wait(.75)
		displayMainMenu(false, true, true) -- ENSURE all menus are invisible before player starts playing
		GuiUtility.blackMenuFade(false, 0.025) -- show screen
		playButton:WaitForChild('ThirdSound'):Play()

		wait(2)
		resetMenuButtons()
		menuButtonDebounce = false
		
		for _,tutorialPopUp in pairs (script.Parent.Parent.TutorialPopups:GetChildren()) do
			if tutorialPopUp:IsA("Frame") then
				tutorialPopUp.Visible = false
			end
		end
	end
end)

shipButton.Activated:Connect(function()
	if not menuButtonDebounce then
		menuButtonDebounce = true
		tweenEnabled = false
		shipButton.Sound:Play()
		displayMyShipMenuEvent:Fire()
		wait(2)
		resetMenuButtons()
		menuButtonDebounce = false
	end
end)

achievementsButton.Activated:Connect(function()
	if not menuButtonDebounce then
		menuButtonDebounce = true
		tweenEnabled = false
		achievementsButton.Sound:Play()
		displayAchievementMenuEvent:Fire(true)
		wait(2)
		resetMenuButtons()
		menuButtonDebounce = false
	end
end)

shopButton.Activated:Connect(function()
	if not menuButtonDebounce then
		menuButtonDebounce = true
		tweenEnabled = false
		shopButton.Sound:Play()
		displayShopMenuEvent:Fire(true)
		wait(2)
		resetMenuButtons()
		menuButtonDebounce = false
	end
end)

-- Button Effects
local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
for _,button in pairs({playButton, shipButton, shopButton, achievementsButton}) do
	local x = script:FindFirstChild(button.Name .. "Position_X").Value
	local y = script:FindFirstChild(button.Name .. "Position_Y").Value
	button.MouseEnter:Connect(function()
		if tweenEnabled == true then
			local tween = TweenService:Create(button, tweenInfo, {Position = UDim2.new(x + .02, 0, y, 0)})
			tween:Play()
			buttonHoverSound:Play()
		end
	end)
	button.MouseLeave:Connect(function()
		if tweenEnabled == true then
			local tween = TweenService:Create(button, tweenInfo, {Position = UDim2.new(x, 0, y, 0)})
			tween:Play()
		end
	end)
end

-- Settings Menu
-- Enable all particles
-- Enable only your particles
-- Disable all particles
-- Mute music
-- Mute Sound Effects (SFX)
-- 

-- Display Gem Shop Menu
local addGemsButton = mainMenu:WaitForChild('Gems'):WaitForChild('Outline'):WaitForChild('AddGems'):WaitForChild('TextButton')
addGemsButton.Activated:Connect(function()
	if GuiUtility.checkVisOfMicroMenus() then
		displayGemShopMenuEvent:Fire(true)
	end
end)
local addGemsButton2 = mainMenu:WaitForChild('Gems'):WaitForChild('Outline'):WaitForChild('AddGems2')
addGemsButton2.Activated:Connect(function()
	if GuiUtility.checkVisOfMicroMenus() then
		displayGemShopMenuEvent:Fire(true)
	end
end)
simpleAddHoverSound(addGemsButton)
simpleAddHoverSound(addGemsButton2)

-- Display Coin Shop Menu
local addCoinsButton = mainMenu:WaitForChild('Coins'):WaitForChild('Outline'):WaitForChild('AddCoins'):WaitForChild('TextButton')
addCoinsButton.Activated:Connect(function()
	if GuiUtility.checkVisOfMicroMenus() then
		displayCoinShopMenuEvent:Fire(true)
	end
end)
local addCoinsButton2 = mainMenu:WaitForChild('Coins'):WaitForChild('Outline'):WaitForChild('AddCoins2')
addCoinsButton2.Activated:Connect(function()
	if GuiUtility.checkVisOfMicroMenus() then
		displayCoinShopMenuEvent:Fire(true)
	end
end)
simpleAddHoverSound(addCoinsButton)
simpleAddHoverSound(addCoinsButton2)

-- Display Code Redeem Menu
local codeButton = mainMenu:WaitForChild('Codes')
codeButton.Activated:Connect(function()
	if GuiUtility.checkVisOfMicroMenus() then
		displayCodeMenuEvent:Fire(true)
	end
end)
simpleAddHoverSound(codeButton)

-- Display boost Menu
local boostButton = playerInfoFrame:WaitForChild('BoostButton')
boostButton.Activated:Connect(function()
	if GuiUtility.checkVisOfMicroMenus() then
		displayBoostMenuEvent:Fire(true)
	end
end)
simpleAddHoverSound(boostButton)

local hideNewsButton = mainMenu.UpdateNews.Hide
hideNewsButton.Activated:Connect(function()
	if hideAvailable then
		hideAvailable = false
		buttonPressSound:Play()
		local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quint)
		
		-- Move UpdateNews out of frame
		TweenService:Create(
			mainMenu.UpdateNews,
			tweenInfo,
			{Position = UDim2.new(mainMenu.UpdateNews.Position.X.Scale, 0, mainMenu.UpdateNews.TweenMove.Value.Y, 0)}
		):Play()

		-- Move playerInfoFrame into position
		playerInfoFrame.Visible = true
		playerInfoFrame.Position = UDim2.new(playerInfoFrame.Position.X.Scale, 0, playerInfoFrame.TweenMove.Value.Y, 0)
		wait(tweenInfo.Time-0.1)
		TweenService:Create(
			playerInfoFrame,
			tweenInfo,
			{Position = UDim2.new(playerInfoFrame.Position.X.Scale, 0, 0.282, 0)}
		):Play()
		wait(tweenInfo.Time)
		mainMenu.UpdateNews.Visible = false
		hideAvailable = true
	end
end)
simpleAddHoverSound(hideNewsButton)

---------------<< Updating GUI With Sensitive Info >>-------------------------

--[[
	Signal sent by PlayerStatManager whenever data changes
	@param statName  Name of the data that has been updated
	@param value  Value of the data
]]
updateGUIEvent.OnClientEvent:Connect(function(statName, value)
	-- Update currency displays
	if statName == "Coins" or statName == "Gems" then
		mainMenu:FindFirstChild(statName).Outline.TextLabel.Text = tostring(value)
	end
end)








---------------<< Start-Of-Game Tasks >>----------------------
local blackScreen = script.Parent.Parent:WaitForChild("BlackScreen").BlackScreen
blackScreen.BackgroundTransparency = 1
blackScreen.Visible = true

-- Rocking effect for gameTitle
local onWayBack = false
coroutine.resume(coroutine.create(function()
	while gameTitle do
		wait()
		if onWayBack then
			gameTitle.Rotation -= 0.08
			if gameTitle.Rotation <= -3 then
				onWayBack = false
			end
		else
			gameTitle.Rotation += 0.08
			if gameTitle.Rotation >= 3 then
				onWayBack = true
			end
		end
	end
end))

-- Shake effect for BoostedIcon
GuiUtility.buttonHopEffect(playButton:WaitForChild('BoostedIcon'), 0.025)
GuiUtility.buttonHopEffect(playerInfoFrame:WaitForChild('BoostButton'), 0.005)

-- Start with main menu turned off
mainMenu.Visible = false
gameTitle.Visible = false
invisSubMenu(myShipMenu)
invisSubMenu(achievementMenu)
invisSubMenu(shopMenu)

-- Update coin/gem displays with player's info
updateCurrencies()




