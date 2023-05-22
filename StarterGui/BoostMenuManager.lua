local player = game.Players.LocalPlayer
local GuiUtility = require(player.PlayerGui:WaitForChild('GuiUtility'))
local TweenService = game:GetService('TweenService')
local SoundService = game:GetService('SoundService')

local eventsFolder = game.ReplicatedStorage:WaitForChild('Events')
local displayBoostMenuEvent = eventsFolder:WaitForChild('GUI'):WaitForChild('ClientDisplayBoostMenu')
local purchaseShipBoostEvent = eventsFolder:WaitForChild('PurchaseShipBoost')
local promptGamePassPurchase = eventsFolder:WaitForChild('PromptGamePassPurchase')

local buttonPress = script.Parent.Parent:WaitForChild('ButtonPress')
local buttonHover = script.Parent.Parent:WaitForChild('ButtonHover')

local boostMenu = script.Parent:WaitForChild('BoostMenu')

----------------------<<|| Product Buttons ||>>---------------------------------------------------------------------------------------

local level8Button = boostMenu:WaitForChild('Level8')
local level9Button = boostMenu:WaitForChild('Level9')
local level10Button = boostMenu:WaitForChild('Level10')

local notifyVisible = false
for _,button in pairs ({level8Button, level9Button, level10Button}) do
	local buttonLevel = string.gsub(button.Name, "Level", "")
	GuiUtility.resizeButtonEffect(button, buttonHover)
	
	button.Activated:Connect(function()
		if not notifyVisible then
			local success = purchaseShipBoostEvent:InvokeServer(buttonLevel)
			
			if success then
				boostMenu.Notify.Message.Text = "You successfully applied a boost to your ship!"
				boostMenu.Notify.ThankYou.Visible = true
				script.Parent.Parent.Success:Play()
				
				-- Show that boost has been applied on play button
				script.Parent.Parent.MainMenu.MainMenu.PlayButton.BoostedIcon.Visible = true
			else
				boostMenu.Notify.Message.Text = "You do not have enough gems to purchase this item"
				boostMenu.Notify.ThankYou.Visible = false
				script.Parent.Parent.Error:Play()
			end
			
			-- Move notify into frame
			TweenService:Create(boostMenu.Notify, TweenInfo.new(1.4, Enum.EasingStyle.Quint), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
			notifyVisible = true
			wait(3.5)
			TweenService:Create(boostMenu.Notify, TweenInfo.new(1, Enum.EasingStyle.Quint), {Position = UDim2.new(0.5, 0, -0.5, 0)}):Play()
			wait(1)
			notifyVisible = false
		end
	end)
end


--------------------<<|| Game Pass Buttons/Menus ||>>----------------------------------------------------------------------------------------

local vipButton = boostMenu:WaitForChild("VipButton")
local vipPlusButton = boostMenu:WaitForChild("VipPlusButton")
local supportButton = boostMenu:WaitForChild("SupportButton")

local vipMenu = boostMenu:WaitForChild('VipMenu')
local vipPlusMenu = boostMenu:WaitForChild('VipPlusMenu')
local supportMenu = boostMenu:WaitForChild('SupportMenu')

local function invisAllSubMenus()
	for _,menu in pairs ({vipMenu, vipPlusMenu, supportMenu}) do
		menu.Visible = false
		menu.Position = UDim2.new()
	end
end


for _,button in pairs ({vipButton, vipPlusButton, supportButton}) do
	GuiUtility.resizeButtonEffect(button, buttonHover)
	
	local associatedMenuName = string.gsub(button.Name, "Button", "") .. "Menu"
	local associatedMenu = boostMenu:FindFirstChild(associatedMenuName)
	button.Activated:Connect(function()
		if not button:FindFirstChild("ComingSoon") then
			buttonPress:Play()
			associatedMenu.Visible = true
			TweenService:Create(
				associatedMenu, 
				TweenInfo.new(0.7, Enum.EasingStyle.Quint), 
				{Position = UDim2.new(0.007, 0, 0.011, 0)}
			):Play()
		end
	end)
	
	associatedMenu.HideMenu.Activated:Connect(function()
		TweenService:Create(
			associatedMenu, 
			TweenInfo.new(0.7, Enum.EasingStyle.Quint), 
			{Position = UDim2.new(associatedMenu.Position.X.Scale, 0, -1, 0)}
		):Play()
		wait(0.7)
		associatedMenu.Visible = false
	end)
end



-- VipMenu Functionality
vipMenu.Purchase.Activated:Connect(function()
	
	
	
	
	
	
end)

-- VipPlusMenu Functionality



-- SupportMenu Functionality
for _,button in pairs ({supportMenu.Tier1, supportMenu.Tier2, supportMenu.Tier3}) do
	button.Activated:Connect(function()
		promptGamePassPurchase:FireServer(button.ProductId.Value)

	end)
end


---------------------<<|| Menu Management ||>>-----------------------------------------------------------------------------------------

--[[
	Close the menu (function since called from button and if force closed like when game starts)
]]
local function closeMenu()
	script.Parent:WaitForChild('MenuClose'):Play()
	TweenService:Create(boostMenu, TweenInfo.new(.7, Enum.EasingStyle.Quint), {Position = UDim2.new(boostMenu.Position.X.Scale, 0, -.55, 0)}):Play()
	wait(.7)
	boostMenu.Visible = false
end
boostMenu:WaitForChild('HideMenu').Activated:Connect(function()
	closeMenu()
end)

local displayDebounce = false
displayBoostMenuEvent.Event:Connect(function(display)
	script.Parent:WaitForChild('MenuOpen'):Play()
	if not displayDebounce then
		displayDebounce = true
		if display then
			invisAllSubMenus()
			boostMenu.Notify.Position = UDim2.new(0.5, 0, -.5, 0)
			boostMenu.Position = UDim2.new(boostMenu.Position.X.Scale, 0, -.55, 0)
			boostMenu.Visible = true
			
			boostMenu.Position = UDim2.new(boostMenu.Position.X.Scale, 0, -.55, 0)
			boostMenu.Visible = true
			TweenService:Create(boostMenu, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Position = UDim2.new(boostMenu.Position.X.Scale, 0, .5, 0)}):Play()
		else
			closeMenu()
		end
		displayDebounce = false
	end
end)
boostMenu.Visible = false
