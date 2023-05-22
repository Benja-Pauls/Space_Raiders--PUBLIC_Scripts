local player = game.Players.LocalPlayer

local TweenService = game:GetService('TweenService')
local GuiUtility = require(script.Parent.Parent:WaitForChild('GuiUtility'))

local eventsFolder = game.ReplicatedStorage:WaitForChild('Events')
local dailyRewardCheckEvent = eventsFolder:WaitForChild('DailyRewardCheck')
local dailyRewardClaimEvent = eventsFolder:WaitForChild('DailyRewardClaim')
local guiEventsFolder = eventsFolder:WaitForChild('GUI')
local clientDisplayMainMenuEvent = guiEventsFolder:WaitForChild('ClientDisplayMainMenu')

local dailyRewardMenu = script.Parent:WaitForChild('DailyReward')
local dailyRewardButton = script.Parent:WaitForChild('DailyRewardButton')
local timeNotify = script.Parent:WaitForChild('TimeNotify')
local claimButton = dailyRewardMenu:WaitForChild('BottomRibbon'):WaitForChild('ClaimButton')
local hideMenuButton = dailyRewardMenu:WaitForChild('HideMenu')
local playButton = script.Parent.Parent:WaitForChild('MainMenu'):WaitForChild('MainMenu'):WaitForChild('PlayButton')
local rewardNotify = dailyRewardMenu:WaitForChild('RewardNotify')

dailyRewardMenu.Visible = false
dailyRewardButton.Visible = false
timeNotify.Visible = false

local staticButtonImage = 'rbxassetid://10897382833'
local hoverButtonImage = 'rbxassetid://10897388591'
local pressedButtonImage = 'rbxassetid://10900297749'
local grayButtonImage = 'rbxassetid://10900300553'
local staticClaimImage = 'rbxassetid://10897935557'
local hoverClaimImage = 'rbxassetid://10897940526'
local pressedClaimImage = 'rbxassetid://10897950803'
local grayClaimImage = 'rbxassetid://10900968713'

local menuOpenSound = script.Parent:WaitForChild('MenuOpen')
local menuCloseSound = script.Parent:WaitForChild('MenuClose')
local hoverSound = script.Parent.Parent:WaitForChild('ButtonHover')
local pressSound = script.Parent.Parent:WaitForChild('ButtonPress')
local errorSound = script.Parent.Parent:WaitForChild('Error')

local borderGreen = Color3.fromRGB(23, 211, 139)
local borderGray = Color3.fromRGB(217, 217, 217)

--[[
	Begin counting down on the timeNotify GUI
	@param timeLeft  Time left, in seconds, until player can claim daily reward
]]
local function startCountdown(timeLeft)
	coroutine.resume(coroutine.create(function()
		while playButton.Visible do
			timeNotify.Time.Text = GuiUtility.ToDHMS(timeLeft, true)
			timeLeft -= 1
			wait(60)

			if timeLeft < 0 then -- Player has waited long enough
				dailyRewardButton.Image = staticButtonImage
				dailyRewardButton.HoverImage = hoverButtonImage
				dailyRewardButton.PressedImage = pressedButtonImage
				timeNotify.UIStroke.Color = borderGreen
				break
			end
		end
	end))
end

---------------<< Display Menu Functions/Events >>--------------------------------------------------------
local displayDebounce = false

--[[
	Display or hide the daily reward menu
	@param display  True if the daily reward menu should be displayed
]]
local function displayDailyRewardMenu(display)
	if not displayDebounce then
		displayDebounce = true
		if display then
			rewardNotify.Visible = false
			dailyRewardMenu.Position = UDim2.new(dailyRewardMenu.Position.X.Scale, 0, -0.55, 0)
			
			claimButton.Image = staticClaimImage
			claimButton.HoverImage = hoverClaimImage
			claimButton.PressedImage = pressedClaimImage
			claimButton.Parent.UIStroke.Color = borderGreen
			
			dailyRewardMenu.Visible = true
			menuOpenSound:Play()
			TweenService:Create(dailyRewardMenu, TweenInfo.new(.7, Enum.EasingStyle.Quint), {Position = UDim2.new(dailyRewardMenu.Position.X.Scale, 0, .5, 0)}):Play()
		else
			menuCloseSound:Play()
			TweenService:Create(dailyRewardMenu, TweenInfo.new(.7, Enum.EasingStyle.Quint), {Position = UDim2.new(dailyRewardMenu.Position.X.Scale, 0, -.55, 0)}):Play()
			wait(.7)
			dailyRewardMenu.Visible = false
		end
		displayDebounce = false
	end
end

-- Changing the clock preview next to the button
-- Get the time remaining when the main menu is shown
clientDisplayMainMenuEvent.Event:Connect(function(display, special, nofade)
	if display then
		dailyRewardButton.Visible = true
		timeNotify.Visible = true
		dailyRewardButton.Image = grayButtonImage
		dailyRewardButton.HoverImage = grayButtonImage
		dailyRewardButton.PressedImage = grayButtonImage
		timeNotify.UIStroke.Color = borderGray
		
		dailyRewardButton.Position = UDim2.new(0.627, 0, 0.914, 0)
		timeNotify.Position = UDim2.new(0.65, 0, 0.924, 0)
		
		local timeLeft = dailyRewardCheckEvent:InvokeServer()
		if timeLeft == 0 then
			dailyRewardButton.Image = staticButtonImage
			dailyRewardButton.HoverImage = hoverButtonImage
			dailyRewardButton.PressedImage = pressedButtonImage
			timeNotify.UIStroke.Color = borderGreen
			timeNotify.Time.Text = 'Claim Me!'
		else
			-- Start counting down
			startCountdown(timeLeft)
		end
	else
		if not special then
			TweenService:Create(dailyRewardButton, TweenInfo.new(.5), {Position = UDim2.new(dailyRewardButton.Position.X.Scale, 0, 1.1, 0)}):Play()
			TweenService:Create(timeNotify, TweenInfo.new(.5), {Position = UDim2.new(dailyRewardButton.Position.X.Scale, 0, 1.1, 0)}):Play()
		end
	end
end)


-----------------<< Button Handling >>-------------------------------------------------------
-- Debounce handled by displayDebounce

playButton.Activated:Connect(function()
	if not displayDebounce then
		wait(1)
		dailyRewardButton.Visible = false
		timeNotify.Visible = false
	end
end)

dailyRewardButton.Activated:Connect(function()
	if dailyRewardButton.Image == grayButtonImage then
		errorSound:Play()
	else
		pressSound:Play()
		if dailyRewardMenu.Visible then
			displayDailyRewardMenu(false)
		else
			if GuiUtility.checkVisOfMicroMenus() then
				displayDailyRewardMenu(true)
			end
		end
	end
end)
dailyRewardButton.MouseEnter:Connect(function()
	hoverSound:Play()
end)

hideMenuButton.Activated:Connect(function()
	displayDailyRewardMenu(false)
end)

-- Claim and display reward
local claimDebounce = false
claimButton.Activated:Connect(function()
	if not claimDebounce then
		claimDebounce = true
		
		if claimButton.Image ~= grayClaimImage then
			claimButton.ClaimSound:Play()
			claimButton.Image = grayClaimImage
			claimButton.HoverImage = grayClaimImage
			claimButton.PressedImage = grayClaimImage
			claimButton.Parent.UIStroke.Color = borderGray
			
			local reward = dailyRewardClaimEvent:InvokeServer()
			if reward ~= nil then
				rewardNotify.Position = UDim2.new(.5, 0, -.5, 0)
				rewardNotify.Text = 'You got ' .. reward .. '!'
				rewardNotify.Visible = true
				TweenService:Create(
					rewardNotify,
					TweenInfo.new(.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
					{Position = UDim2.new(.5, 0, 0.457, 0)}
				):Play()
				
				dailyRewardButton.Image = grayButtonImage
				dailyRewardButton.HoverImage = grayButtonImage
				dailyRewardButton.PressedImage = grayButtonImage
				timeNotify.Time.Text = 'Claimed'
				timeNotify.UIStroke.Color = borderGray
				
				wait(3)
				displayDailyRewardMenu(false)		
			else
				displayDailyRewardMenu(false)
			end
		else
			errorSound:Play()
		end
		claimDebounce = false
	end
end)
GuiUtility.resizeButtonEffect(claimButton, hoverSound)


-----------<< ReRoll Functionality >>-----------------------------------------------------------------------

-- Each Reroll costs more and more (50 * 1.5 -> 75, 75 * 1.5 -> ___(round up)___)

-- Possibly reroll with gems or coins ()





