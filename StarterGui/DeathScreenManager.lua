local GuiUtility = require(script.Parent.Parent:WaitForChild("GuiUtility"))
local Constants = require(script.Parent.Parent.Parent:WaitForChild('PlayerScripts'):WaitForChild("Constants"))
local MusicPlayer = require(script.Parent.Parent:WaitForChild('Music'):WaitForChild('MusicPlayer'))
local PointerArrow = require(script.Parent.Parent:WaitForChild('PointerArrow'))
local TweenService = game:GetService('TweenService')
local player = game.Players.LocalPlayer

local guiEventsFolder = game.ReplicatedStorage:WaitForChild('Events'):WaitForChild('GUI')
local displayDeathScreenEvent = guiEventsFolder:WaitForChild('DisplayDeathScreen')
local clientDisplayMainMenu = guiEventsFolder:WaitForChild('ClientDisplayMainMenu')
local checkTutorialProgressEvent = game.ReplicatedStorage:WaitForChild('Events'):WaitForChild('CheckTutorialProgress')
local getEquippedInfoEvent = game.ReplicatedStorage:WaitForChild('Events'):WaitForChild('GetEquippedInfo')
local requestAchievementDataEvent = game.ReplicatedStorage:WaitForChild('Events'):WaitForChild('RequestAchievementData')

local deathScreen = script.Parent:WaitForChild('DeathScreen')
local blackScreen = script.Parent.Parent:WaitForChild("BlackScreen").BlackScreen
local mainMenuButton = deathScreen:WaitForChild('MainMenu')
deathScreen.Visible = false -- Do not display UI on login

--[[
	Small pop up that goes below diplays showcasing player's overall wealth on death screen
	@param changeDisplay  The popup that's within the current currency display
	@param amountGained  Amount of wealth player actually gained in current session
	@param currencyName  Quick reference; either "Coins" or "Gems"
]]
local function displayChangeNotify(changeDisplay, amountGained, currencyName)
	if amountGained <= 0 then
		changeDisplay.Text = "+0 " .. currencyName
		changeDisplay.TextColor3 = Color3.new(0.29, 0.29, 0.29)
		deathScreen.GainedZero:Play()
	else
		changeDisplay.Text = "+" .. Constants.simplifyNumber(amountGained) .. " " .. currencyName .. "!"
		changeDisplay.TextColor3 = Color3.new(0.18, 1, 0)
		changeDisplay.Parent.Gained:Play()
	end
	changeDisplay:TweenSize(UDim2.new(1,0,5.56,0), "Out", "Back", 0.3)
end

--[[ RECURSIVE
	Change coin/gem display to show player how much they earned throughout the game
	@param display  GUI display that showcases the player's coins/gems
	@param amountGained  Amount of coins/gems the player earned throughout their session
	@param iterations  Amount of times the display should update (gained/100)
	
]]
local function displayDataChange(display, amountGained, iterations)
	local sound = display.Sound
	
	if iterations ~= 0 then-- Satisfying "animations" (NUMBER INCREASE FUNCTION)
		-- Calculate some random integer amount that will be applied to the sum
		local add = math.random(1, math.round(amountGained/iterations))
		if iterations == 1 then
			add = amountGained
		end
		
		local amount = tonumber(display.Outline.TextLabel.Text)
		local text = display.Outline.TextLabel
		text.Text = tostring(amount + add)
		sound:Play()
		sound.PlaybackSpeed += .05 -- Get higher pitched as player gets more rewards!
		text:TweenSize(UDim2.new(0.507, 0, .138, 0), "Out", "Back", 0.075)
		wait(.075)
		text:TweenSize(UDim2.new(0.5, 0, 0.131, 0), "Out", "Back", 0.075)
		wait(0.075)
		
		displayDataChange(display, amountGained - add, iterations - 1)
	end -- else end recursion
end

--[[
	Change if the main menu is being displayed or not
	@param display  True if death screen should be displayed
	@param coins  Total coins player currently has
	@param coinsGained  Amount of coins player has gained in session
	@param gems  Total gems player currently has
	@param gemsGained  Amount of gems player has gained in session
]]
local function displayDeathScreen(display, coins, coinsGained, gems, gemsGained)
	if display then
		-- Display the main menu button
		mainMenuButton.Position = UDim2.new(mainMenuButton.Position.X.Scale, 0, 1, 0)
		mainMenuButton.Visible = true
		TweenService:Create(
			mainMenuButton, 
			TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), 
			{Position = UDim2.new(mainMenuButton.Position.X.Scale, 0, 0.859, 0)}
		):Play()
		
		-- Initial setup for coin & gem displays
		pcall(function()
			local coinDisplay = deathScreen.Coins
			local gemDisplay = deathScreen.Gems
			coinDisplay.Outline.Size = UDim2.new(1,0,0,0)
			gemDisplay.Outline.Size = UDim2.new(1,0,0,0)
			coinDisplay.ChangeDisplay.Size = UDim2.new(1,0,0,0)
			gemDisplay.ChangeDisplay.Size = UDim2.new(1,0,0,0)
			coinDisplay.Outline.TextLabel.Text = coins
			gemDisplay.Outline.TextLabel.Text = gems

			PointerArrow.destroy()
			
			-- Killed-By Info
			deathScreen.KilledBy.Text = "Killed By: "
			if game.Players:FindFirstChild(deathScreen.Parent.KilledBy.Value) then
				local killedById = game.Players:FindFirstChild(deathScreen.Parent.KilledBy.Value).UserId
				local imageType = Enum.ThumbnailType.HeadShot
				local imageSize = Enum.ThumbnailSize.Size420x420
				local image = game.Players:GetUserThumbnailAsync(killedById, imageType, imageSize)
				deathScreen.CallingCard.ProfilePic.Image = image
				deathScreen.CallingCard.Username.Text = deathScreen.Parent.KilledBy.Value
				deathScreen.CallingCard.Title.Text = getEquippedInfoEvent:InvokeServer(player)[8]
				
				-- Sum Kills Display
				local status,value,achievementInfo = requestAchievementDataEvent:InvokeServer("Novice Pilot")
				deathScreen.CallingCard["Career Kills"].Text = "Career Kills: " .. tostring(value)

				deathScreen.CallingCard.Visible = true
			elseif string.match(deathScreen.Parent.KilledBy.Value, 'Bot') then
				deathScreen.CallingCard.ProfilePic.Image = "rbxassetid://11905322775"
				deathScreen.CallingCard.Username.Text = "Space Bot"
				deathScreen.CallingCard.Title.Text = "Property of Galactic Mining"
				deathScreen.CallingCard["Career Kills"].Text = "Damaged"
				deathScreen.CallingCard.Visible = false
			else
				deathScreen.CallingCard.Visible = false
			end
			
			-- Fade-in death screen
			deathScreen.Visible = true
			GuiUtility.fadeMenu(deathScreen, false)
			
			-- Display FirstDeath tutorial if necessary
			local firstDeath = checkTutorialProgressEvent:InvokeServer("FirstDeath")
			if not firstDeath then
				local tutorialGUI = script.Parent.Parent:WaitForChild('TutorialPopups'):WaitForChild('FirstDeath')
				local tutorialScript = tutorialGUI:WaitForChild('TutorialHandler')
				tutorialScript.Disabled = true; tutorialScript.Disabled = false -- Reset everything within the script
				tutorialGUI:WaitForChild('TutorialHandler'):WaitForChild('Trigger'):Fire()
			end
			wait(2)
			
			-- Showcase coin earnings for that game
			coinDisplay.Outline:TweenSize(UDim2.new(1,0,55.058,0), "Out", "Quint", 1) -- Strech coin display to full size
			wait(1.2)
			local iterations = math.round(coinsGained/500)
			if iterations == 0 and coinsGained ~= 0 then
				iterations = 1
			end
			coinDisplay.Sound.PlaybackSpeed = 0.9 -- Reset pitch
			displayDataChange(coinDisplay, coinsGained, iterations)
			wait(0.3)
			displayChangeNotify(coinDisplay.ChangeDisplay, coinsGained, "Coins")
			wait(0.3)

			-- Showcase gem earnings for that game
			gemDisplay.Outline:TweenSize(UDim2.new(1,0,56.501,0), "Out", "Quint", 1) -- Stretch gem display to full size
			wait(1.2)
			gemDisplay.Sound.PlaybackSpeed = 1
			displayDataChange(gemDisplay, gemsGained, gemsGained)
			wait(0.3)
			displayChangeNotify(gemDisplay.ChangeDisplay, gemsGained, "Gems")
		end)

	else
		-- Fade to black screen
		blackScreen.Visible = true
		GuiUtility.fadeMenu(blackScreen, false)
		deathScreen.Visible = false
		
		clientDisplayMainMenu:Fire(true)

		-- Fade out of the black screen
		GuiUtility.fadeMenu(blackScreen, true)
	end
end

displayDeathScreenEvent.OnClientEvent:Connect(displayDeathScreen)

mainMenuButton.Activated:Connect(function()
	script.Parent.Parent.ButtonPress:Play()
	MusicPlayer.shuffle("MainMenu")
	displayDeathScreen(false)
end)

mainMenuButton.MouseEnter:Connect(function()
	script.Parent.Parent.ButtonHover:Play()
end)

-- Perpetually shake YouDied GUI
local shakeIntensity = 2
local youDied = deathScreen:WaitForChild('YouDied')
local absolutePosition = youDied.AbsolutePosition
while youDied do
	wait(.2)
	local desiredPosition = absolutePosition + Vector2.new(math.random(-shakeIntensity, shakeIntensity), math.random(-shakeIntensity, shakeIntensity))
	local newPosition = (desiredPosition - youDied.Parent.AbsolutePosition) -- subtract the parent's position from the desired position to get its offset
	youDied.Position = UDim2.fromOffset(newPosition.X, newPosition.Y)
end

