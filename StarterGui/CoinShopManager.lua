local player = game.Players.LocalPlayer
local TweenService = game:GetService('TweenService')
local MarketPlaceService = game:GetService('MarketplaceService')
local GuiUtility = require(script.Parent.Parent:WaitForChild('GuiUtility'))

local eventsFolder = game.ReplicatedStorage:WaitForChild('Events')
local promptMarketPurchaseEvent = eventsFolder:WaitForChild('PromptMarketPurchase')
local displayCoinShopMenuEvent = eventsFolder:WaitForChild('GUI'):WaitForChild('ClientDisplayCoinShopMenu')
local purchaseCoinsEvent = eventsFolder:WaitForChild('PurchaseCoins')

local coinShop = script.Parent:WaitForChild('CoinShop')
local vaultImageFrame = coinShop:WaitForChild('VaultImage')

local vaultPressedImage = "rbxassetid://11248794378"
local vaultStaticImage = "rbxassetid://11248445220"
local hoverSound = script.Parent.Parent:WaitForChild('ButtonHover')
local pressSound = script.Parent.Parent:WaitForChild('ButtonPress')

local notifyVisible = false
for _,button in pairs (coinShop:GetChildren()) do
	if button:IsA("ImageButton") and string.match(button.Name, 'Purchase') then
		if button.Name == "Purchase1000" then -- Vault button has to react slightly differently
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
			if not notifyVisible then
				pressSound:Play()
				
				-- Display message depending on player's ability to purchase
				local success = purchaseCoinsEvent:InvokeServer(button.GemAmount.Value)
				if success then
					coinShop.Notify.Message.Text = "You Purchased " .. tostring(button.GemAmount.Value) .. " Gems!"
					coinShop.Notify.ThankYou.Visible = true
				else
					coinShop.Notify.Message.Text = "You do not have enough gems to purchase this item"
					coinShop.Notify.ThankYou.Visible = false
				end
				
				-- Move notify into frame
				TweenService:Create(coinShop.Notify, TweenInfo.new(1.4, Enum.EasingStyle.Quint), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
				notifyVisible = true
				wait(3.5)
				TweenService:Create(coinShop.Notify, TweenInfo.new(1, Enum.EasingStyle.Quint), {Position = UDim2.new(0.5, 0, -0.5, 0)}):Play()
				wait(1)
				notifyVisible = false
			end
		end)
	end
end

--[[
	Close the menu (function since called from button and if force closed like when game starts)
]]
local function closeMenu()
	script.Parent:WaitForChild('MenuClose'):Play()
	TweenService:Create(coinShop, TweenInfo.new(.7, Enum.EasingStyle.Quint), {Position = UDim2.new(coinShop.Position.X.Scale, 0, -.55, 0)}):Play()
	wait(.7)
	coinShop.Visible = false
end
coinShop:WaitForChild('HideMenu').Activated:Connect(function()
	closeMenu()
end)

local displayDebounce = false
displayCoinShopMenuEvent.Event:Connect(function(display)
	script.Parent:WaitForChild('MenuOpen'):Play()
	if not displayDebounce then
		displayDebounce = true
		if display then
			coinShop.Notify.Position = UDim2.new(0.5, 0, -.5, 0)
			coinShop.Position = UDim2.new(coinShop.Position.X.Scale, 0, -.55, 0)
			coinShop.Visible = true
			TweenService:Create(coinShop, TweenInfo.new(.7, Enum.EasingStyle.Quint), {Position = UDim2.new(coinShop.Position.X.Scale, 0, .5, 0)}):Play()
		else
			closeMenu()
		end
		displayDebounce = false
	end
end)
coinShop.Visible = false
