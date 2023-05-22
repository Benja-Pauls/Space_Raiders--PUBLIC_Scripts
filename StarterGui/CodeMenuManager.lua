local player = game.Players.LocalPlayer
local GuiUtility = require(player.PlayerGui:WaitForChild('GuiUtility'))
local TweenService = game:GetService('TweenService')
local SoundService = game:GetService('SoundService')

local eventsFolder = game.ReplicatedStorage:WaitForChild('Events')
local checkCodeEvent = eventsFolder:WaitForChild('CheckCode')
local displayCodeMenuEvent = eventsFolder:WaitForChild('GUI'):WaitForChild('ClientDisplayCodeMenu')

local codeMenu = script.Parent:WaitForChild('CodeMenu')
local codeInput = codeMenu:WaitForChild('CodeInput')
local redeemButton = codeMenu:WaitForChild('Redeem')
local validCode = codeMenu:WaitForChild('ValidCode')
local invalidCode = codeMenu:WaitForChild('InvalidCode')
local claimedCode = codeMenu:WaitForChild('ClaimedCode')
GuiUtility.resizeButtonEffect(redeemButton, player.PlayerGui:WaitForChild('ButtonHover'))

redeemButton.Activated:Connect(function()
	local redeemed,description = checkCodeEvent:InvokeServer(codeInput.Text)
	if redeemed == 'claimed' then
		validCode.Visible = false
		invalidCode.Visible = false
		claimedCode.Visible = true
	else
		validCode.Visible = redeemed
		invalidCode.Visible = not redeemed
		claimedCode.Visible = false
	end
	
	if codeMenu.ValidCode.Visible then
		codeMenu.ValidCode.Text = 'Successfully Redeemed Code. You got ' .. description .. '!'
	end
	
	if redeemed then
		SoundService:PlayLocalSound(player.PlayerGui:WaitForChild('ButtonPress'))
	else
		SoundService:PlayLocalSound(player.PlayerGui:WaitForChild('Error'))
	end
end)

--[[
	Close the menu (function since called from button and if force closed like when game starts)
]]
local function closeMenu()
	script.Parent:WaitForChild('MenuClose'):Play()
	TweenService:Create(codeMenu, TweenInfo.new(.7, Enum.EasingStyle.Quint), {Position = UDim2.new(codeMenu.Position.X.Scale, 0, -.55, 0)}):Play()
	wait(.7)
	codeMenu.Visible = false
end
codeMenu:WaitForChild('HideMenu').Activated:Connect(function()
	closeMenu()
end)

local displayDebounce = false
displayCodeMenuEvent.Event:Connect(function(display)
	script.Parent:WaitForChild('MenuOpen'):Play()
	if not displayDebounce then
		displayDebounce = true
		if display then
			codeMenu.Position = UDim2.new(codeMenu.Position.X.Scale, 0, -.55, 0)
			codeMenu.Visible = true
			validCode.Visible = false; invalidCode.Visible = false; claimedCode.Visible = false
			TweenService:Create(codeMenu, TweenInfo.new(.7, Enum.EasingStyle.Quint), {Position = UDim2.new(codeMenu.Position.X.Scale, 0, .5, 0)}):Play()
		else
			closeMenu()
		end
		displayDebounce = false
	end
end)
codeMenu.Visible = false
