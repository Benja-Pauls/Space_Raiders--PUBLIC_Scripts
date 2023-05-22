local player = game.Players.LocalPlayer
local TweenService = game:GetService('TweenService')
local MarketPlaceService = game:GetService('MarketplaceService')
local GuiUtility = require(script.Parent.Parent:WaitForChild('GuiUtility'))

local eventsFolder = game.ReplicatedStorage:WaitForChild('Events')
local promptMarketPurchaseEvent = eventsFolder:WaitForChild('PromptMarketPurchase')
local displayGemShopMenuEvent = eventsFolder:WaitForChild('GUI'):WaitForChild('ClientDisplayGemShopMenu')

local gemShop = script.Parent:WaitForChild('GemShop')
local vaultImageFrame = gemShop:WaitForChild('VaultImage')

local vaultPressedImage = "rbxassetid://10584601745"
local vaultStaticImage = "rbxassetid://10584527943"
local hoverSound = script.Parent.Parent:WaitForChild('ButtonHover')
local pressSound = script.Parent.Parent:WaitForChild('ButtonPress')

for _,button in pairs (gemShop:GetChildren()) do
	if button:IsA("ImageButton") and string.match(button.Name, 'Purchase') then
		if button.Name == "Purchase1500" then -- Vault button has to react slightly differently
			local startXSize, startYSize = vaultImageFrame.Size.X.Scale, vaultImageFrame.Size.Y.Scale
			local sizeTweenInfo = TweenInfo.new(.5, Enum.EasingStyle.Quint)
			button.MouseEnter:Connect(function()
				hoverSound:Play()
				TweenService:Create(vaultImageFrame, sizeTweenInfo, {Size = UDim2.new(startXSize+.015, 0, startYSize+.015, 0)}):Play()
			end)
			button.MouseLeave:Connect(function()
				TweenService:Create(vaultImageFrame, sizeTweenInfo, {Size = UDim2.new(startXSize, 0, startYSize, 0)}):Play()
				vaultImageFrame.Image = vaultStaticImage
			end)
			button.MouseButton1Down:Connect(function()
				vaultImageFrame.Image = vaultPressedImage
			end)
			button.MouseButton1Up:Connect(function()
				vaultImageFrame.Image = vaultStaticImage
			end)
		else
			GuiUtility.resizeButtonEffect(button, hoverSound)
		end
		button.Activated:Connect(function()
			pressSound:Play()
			if player.MembershipType == Enum.MembershipType.Premium then
				promptMarketPurchaseEvent:FireServer(button.PREMIUM_ProductID.Value)
			else
				promptMarketPurchaseEvent:FireServer(button.ProductID.Value)
			end
		end)
	end
end

--[[
	Close the menu (function since called from button and if force closed like when game starts)
]]
local function closeMenu()
	script.Parent:WaitForChild('MenuClose'):Play()
	TweenService:Create(gemShop, TweenInfo.new(.7, Enum.EasingStyle.Quint), {Position = UDim2.new(gemShop.Position.X.Scale, 0, -.55, 0)}):Play()
	wait(.7)
	gemShop.Visible = false
end
gemShop:WaitForChild('HideMenu').Activated:Connect(function()
	closeMenu()
end)

local displayDebounce = false
displayGemShopMenuEvent.Event:Connect(function(display)
	script.Parent:WaitForChild('MenuOpen'):Play()
	if not displayDebounce then
		displayDebounce = true
		if display then
			gemShop.Position = UDim2.new(gemShop.Position.X.Scale, 0, -.55, 0)
			gemShop.Visible = true
			TweenService:Create(gemShop, TweenInfo.new(.7, Enum.EasingStyle.Quint), {Position = UDim2.new(gemShop.Position.X.Scale, 0, .5, 0)}):Play()
		else
			closeMenu()
		end
		displayDebounce = false
	end
end)
gemShop.Visible = false
