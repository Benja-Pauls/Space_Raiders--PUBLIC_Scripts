local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera

local GuiUtility = require(player.PlayerGui:WaitForChild('GuiUtility'))
local Players = game:GetService("Players")
local TweenService = game:GetService('TweenService')

local eventsFolder = game.ReplicatedStorage:WaitForChild('Events')
local guiEventsFolder = eventsFolder:WaitForChild('GUI')
local requestShopDataEvent = eventsFolder:WaitForChild('RequestShopData')
local purchaseItemEvent = eventsFolder:WaitForChild('PurchaseItem')
local checkPurchaseEvent = eventsFolder:WaitForChild('CheckPurchase')
local displayShopMenuEvent = guiEventsFolder:WaitForChild('ClientDisplayShopMenu')
local clientDisplayMainMenuEvent = guiEventsFolder:WaitForChild('ClientDisplayMainMenu')
local updateGUIEvent = guiEventsFolder:WaitForChild('UpdateGUI')
local getCurrenciesEvent = guiEventsFolder:WaitForChild('GetCurrencies')
local displayGemShopMenuEvent = guiEventsFolder:WaitForChild('ClientDisplayGemShopMenu')
local displayCoinShopMenuEvent = guiEventsFolder:WaitForChild('ClientDisplayCoinShopMenu')

local physicalShopMenu = workspace:WaitForChild("ShopMenu")
local shopMenu = script.Parent:WaitForChild("ShopMenu")
local nextPage = shopMenu:WaitForChild('NextPage')
local prevPage = shopMenu:WaitForChild('PrevPage')
local singleProductMenu = script.Parent:WaitForChild('SingleProductMenu')
local barriers = script.Parent:WaitForChild('Barriers')
local backButton = barriers:WaitForChild('BackButton')

-- Common Assets
local guiElements = game.ReplicatedStorage:WaitForChild('GuiElements')
local COINS_IMAGE = "rbxassetid://9780032113"
local GEMS_IMAGE = "rbxassetid://9780164018"
local purcahseButtonSTATIC = "rbxassetid://10430823031"
local purcahseButtonHOVER = "rbxassetid://10430826928"
local purchaseButtonPRESSED = "rbxassetid://10430830003"
local grayPurchaseButtonSTATIC = "rbxassetid://10434840606"

local pressSound = player.PlayerGui:WaitForChild('ButtonPress')
local selectSound = script.Parent:WaitForChild('SelectSound')
local purchaseSound = script.Parent:WaitForChild('PurchaseSound')
local finalizedPurchaseSound = script.Parent:WaitForChild('FinalizedPurchase')
local errorSound = player.PlayerGui:WaitForChild('Error')
--[[ Dimensional Constants
 (1,1): .209,.242
 (2,1): .354, .242
 (1,2): .209, .499
]]
local X_ORIGIN, Y_ORIGIN = .209, .242
local SIZE_JUMP = .14 -- Size scaled of inner tile is 1 for both x and y
local X_JUMP, Y_JUMP, IN_JUMP = .145, .257, .018
local barrierTweenInfo = TweenInfo.new(.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

--[[Update the "Coins" and "Gems" currency displays]]
local function updateCurrencyDisplays()
	local coins,gems = getCurrenciesEvent:InvokeServer()
	if coins ~= nil then
		barriers.Coins.Outline.TextLabel.Text = GuiUtility.simplifyNumber(coins)
		barriers.Gems.Outline.TextLabel.Text = tostring(gems)
	end
end


local function scrollThroughShips()
	
	
	
	
	
	
end

-------------------<< Single-Product Display Menu >>--------------------------------------
local productDisplay = physicalShopMenu:WaitForChild("Display")
local purchaseButton = singleProductMenu:WaitForChild('PurchaseButton')
local itemDisplay1 = singleProductMenu:WaitForChild('ItemName1')
local itemDisplay2 = singleProductMenu:WaitForChild('ItemName2')
local categoryDisplay = singleProductMenu:WaitForChild('Category')
local costDisplay = singleProductMenu:WaitForChild('CostDisplay')
local purchasedDisplay = singleProductMenu:WaitForChild('Purchased')

--[[
	If small screen on pedestal for items should be visible or not
	@param display  True if the screen should be displayed
]]
local function displayScreen(display)
	local t = 1; if display then t = 0 end
	for _,part in pairs (physicalShopMenu.Platform.Screen:GetChildren()) do
		if part:IsA("Part") then
			part.Transparency = t
		end
	end
end

--[[ 
	Return everything in the product menu to its default positions and values 
	@param special  True if should be tweened off rather than positioned off
]]
local resetDebounce = false
local backButtonAvailable = true
local function resetProductMenu(special)
	if not resetDebounce then
		resetDebounce = true
		
		-- Get rid of any ship being displayed
		for _,part in pairs (script.Parent.MyShipView.ShipViewPort.Physics:GetChildren()) do
			part:Destroy()
		end
		
		if special then
			TweenService:Create(purchaseButton, TweenInfo.new(.7), {Position = UDim2.new(purchaseButton.Position.X.Scale, 0, 1.05, 0)}):Play()
			TweenService:Create(itemDisplay1, TweenInfo.new(.7), {Position = UDim2.new(itemDisplay1.Position.X.Scale, 0, -.2, 0)}):Play()
			TweenService:Create(itemDisplay2, TweenInfo.new(.7), {Position = UDim2.new(itemDisplay2.Position.X.Scale, 0, -.2, 0)}):Play()
			TweenService:Create(categoryDisplay, TweenInfo.new(.7), {Position = UDim2.new(-.5, 0, categoryDisplay.Position.Y.Scale, 0)}):Play()
			TweenService:Create(costDisplay, TweenInfo.new(.7), {Position = UDim2.new(-.5, 0, costDisplay.Position.Y.Scale, 0)}):Play()
			TweenService:Create(barriers.Coins, TweenInfo.new(1.5), {Position = UDim2.new(barriers.Coins.InPosition.Value, 0, barriers.Coins.Position.Y.Scale, 0)}):Play()
			TweenService:Create(barriers.Gems, TweenInfo.new(1.5), {Position = UDim2.new(barriers.Gems.InPosition.Value, 0, barriers.Gems.Position.Y.Scale, 0)}):Play()
			TweenService:Create(purchasedDisplay, TweenInfo.new(.7), {Position = UDim2.new(0.5, 0, -0.5, 0)}):Play()
			
			wait(.7)
			singleProductMenu.Visible = false
			wait(1)
		else
			singleProductMenu.Visible = false
			purchaseButton.Position = UDim2.new(purchaseButton.Position.X.Scale, 0, 1.05, 0)
			itemDisplay1.Position = UDim2.new(itemDisplay1.Position.X.Scale, 0, -.2, 0)
			itemDisplay2.Position = UDim2.new(itemDisplay2.Position.X.Scale, 0, -.2, 0)
			categoryDisplay.Position = UDim2.new(-.5, 0, categoryDisplay.Position.Y.Scale, 0)
			costDisplay.Position = UDim2.new(-.5, 0, costDisplay.Position.Y.Scale, 0)
			purchasedDisplay.Position = UDim2.new(.5, 0, -.5, 0)
		end
		
		-- Delete whatever was being displayed
		if productDisplay:FindFirstChild("DisplayedItem") then
			productDisplay.DisplayedItem:Destroy()
		end
		resetDebounce = false
	end
end

--[[ 
	From selected item, display its info and a visual at the product display 
	@param t  Table filled with info about the tile
]]
local function displayNewProduct(t)
	local productInfo = t["Item"]
	local name = productInfo["Name"]
	itemDisplay1.Text = name; itemDisplay2.Text = name
	
	-- Delete whatever was being displayed
	if productDisplay:FindFirstChild("DisplayedItem") then
		productDisplay.DisplayedItem:Destroy()
	end
	
	-- Cost Display
	local cost = t["Cost"]
	local ableToBePurchased = false; local coins,gems = getCurrenciesEvent:InvokeServer()
	if cost[2] == "Gems" then
		costDisplay.ImageLabel.Image = GEMS_IMAGE
		if gems >= cost[3] then
			ableToBePurchased = true
		end
	else
		costDisplay.ImageLabel.Image = COINS_IMAGE
		if coins >= cost[3] then
			ableToBePurchased = true
		end
	end
	costDisplay.Amount.Text = tostring(cost[3])
	
	if ableToBePurchased then
		purchaseButton.Image = purcahseButtonSTATIC
		purchaseButton.HoverImage = purcahseButtonHOVER
		purchaseButton.PressedImage = purchaseButtonPRESSED
	else
		purchaseButton.Image = grayPurchaseButtonSTATIC
		purchaseButton.HoverImage = grayPurchaseButtonSTATIC
		purchaseButton.PressedImage = grayPurchaseButtonSTATIC
	end
	
	-- Display the different categories like the Achievement Menu
	local displayedItem
	local category = t["Category"]
	if category == "Color" then
		categoryDisplay.Text = "New Paint"
		displayedItem = script.Parent.PaintSet:Clone()
		for _,colorPart in pairs (displayedItem.Paint:GetChildren()) do
			if not productInfo['Color']:FindFirstChild('ShipEffect') and colorPart:FindFirstChild('ShipEffect') then
				colorPart.ShipEffect:Destroy()
			end
			if colorPart.Name == "Color" then
				GuiUtility.applyColorData(colorPart, productInfo['Color'])
			end
			if colorPart.Name == 'Neon' then
				colorPart.Color = productInfo['Color'].Color
			end
		end
		displayScreen(false)
	elseif category == "Trail" then
		categoryDisplay.Text = "New Trail"
		displayedItem = script.Parent.TrailDisplay:Clone()
		local thrusterEffect = productInfo["Folder"].Thruster:Clone()
		thrusterEffect.Parent = displayedItem.ThrusterDisplay.Thruster
		thrusterEffect.Speed = NumberRange.new(10)
		thrusterEffect.SpreadAngle = Vector2.new(0, 0)
		local laserEffect = productInfo["Folder"].Laser:Clone()
		laserEffect.Parent = displayedItem.LaserDisplay.Thruster
		laserEffect.Speed = NumberRange.new(10)
		laserEffect.SpreadAngle = Vector2.new(0, 0)
		displayScreen(false)
	elseif category == "Ship" then
		-- Scroll through all the ship previews of this ship
		local shipDisplay = physicalShopMenu:WaitForChild('ShipViewport')
		local shipViewPort = script.Parent:WaitForChild('MyShipView'):WaitForChild('ShipViewPort')
		
		coroutine.resume(coroutine.create(function()
			local displayedShipLevel = 1
			while singleProductMenu and singleProductMenu.Visible do
				wait(2)
				if displayedShipLevel == 11 then
					displayedShipLevel = 1
				end

				local shipData = game.ReplicatedStorage.EquipData.Ship:FindFirstChild(name)
				GuiUtility.displayPlayerShip(player, shipViewPort, displayedShipLevel, shipData)
				displayedShipLevel += 1
			end
		end))
		
		categoryDisplay.Text = "New Ship"
		displayScreen(false)
	end
	
	if displayedItem then
		displayedItem.Name = "DisplayedItem"
		displayedItem.Parent = productDisplay
		displayedItem:SetPrimaryPartCFrame(productDisplay.CFrame)
	end
end

local purchaseDebounce = false
local confetti = physicalShopMenu:WaitForChild('Confetti')
purchaseButton.Activated:Connect(function()
	if purchaseButton.Image ~= grayPurchaseButtonSTATIC then
		if not purchaseDebounce and singleProductMenu.Visible and purchaseButton.Visible then
			purchaseDebounce = true
			purchaseSound:Play()
			backButtonAvailable = false
			
			purchaseItemEvent:FireServer(itemDisplay1.Text)
			purchaseButton.Image = grayPurchaseButtonSTATIC
			purchaseButton.HoverImage = grayPurchaseButtonSTATIC
			purchaseButton.PressedImage = grayPurchaseButtonSTATIC
			
			-- Move confetti into view
			confetti.Position = confetti.Start.Value
			TweenService:Create(confetti, TweenInfo.new(3.5, Enum.EasingStyle.Circular), {Position = confetti.End.Value}):Play()

			-- Pop up that purchase was successful (change purchase button as well)
			wait(1.5)
			TweenService:Create(purchasedDisplay, TweenInfo.new(2.5, Enum.EasingStyle.Bounce), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
			wait(.5)
			finalizedPurchaseSound:Play()
			
			-- Update purchased marker on tile this purchase was made from
			local itemTile
			for _,page in pairs (shopMenu:GetChildren()) do
				for _,tile in pairs (page:GetChildren()) do
					if itemTile == nil and tile.Frame.InnerButton.ItemName.Text == itemDisplay1.Text then
						itemTile = tile
					end
				end
			end
			itemTile.Frame.InnerButton.Purchased.Visible = true
			
			wait(3.5)
			confetti.Position = confetti.Start.Value
			
			-- Bring back to shop menu
			local cameraTweenInfo = TweenInfo.new(2.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			TweenService:Create(camera, cameraTweenInfo, {CFrame = physicalShopMenu.ShopCamera.CFrame}):Play()
			resetProductMenu(true)
			TweenService:Create(shopMenu, barrierTweenInfo, {Position = UDim2.new(0, 0, 0, 0)}):Play()
			updateCurrencyDisplays()
			purchaseDebounce = false
			backButtonAvailable = true
		end
	else
		player.PlayerGui.Error:Play()
	end
end)

-------------------<< First Shop Menu Management >>---------------------------------------------

-- Likely have the underlying frame actually stay the same size so positioning is easier
-- Then, changing the size will be an inner button that the player actually clicks (What sizing goes off then too)

--[[ Return everything in the shop menu to its default positions and values ]]
local function resetShopMenu()
	resetProductMenu()
	
	-- Remove all pages
	for _,page in pairs (shopMenu:GetChildren()) do
		if page:IsA("Frame") and string.match(page.Name, "Page") then
			page:Destroy()
		end
	end

	-- Reset visibility to the first menu GUI, not the Single-Product GUI
	shopMenu.Visible = true
	barriers.Visible = true
	singleProductMenu.Visible = false
end

--[[
	Given tile info, position the tile on the current page
	@param t  Tile info table
	@param tile  Frame representing tile
]]
local function positionTile(t, tile)
	local xDim = t["Dimensions"][1]
	local yDim = t["Dimensions"][2]
	local xPos = t["Position"][1]-1
	local yPos = t["Position"][2]-1

	tile.Position = UDim2.new(X_ORIGIN+(xPos*X_JUMP), 0, Y_ORIGIN+(yPos*Y_JUMP), 0)
	tile.Frame.Size = UDim2.new(xDim + (SIZE_JUMP*(xDim-1)), 0, yDim + (SIZE_JUMP*(yDim-1)), 0)
end

--[[
	For tinier tiles on first shop menu, add info to their tile
	@param t  Tile info table
	@param tile  Frame representing tile
	@param purchased  True if the item in the tile has been purchased
]]
local function addProductInfoToTile(t, tile, purchased)
	local innerButton = tile.Frame.InnerButton
	local color = t["Color"]
	local cost = t["Cost"]
	local item = t["Item"]
	local category = t["Category"]
	
	tile.Frame.InnerButton.Purchased.Visible = purchased
	
	-- Easy-to-place info
	tile.Frame.BackgroundColor3 = color
	innerButton.Cost.BackgroundColor3 = color
	innerButton.AccentColor.BackgroundColor3 = color
	innerButton.Cost.Amount.Text = GuiUtility.simplifyNumber(cost[3])
	innerButton.ItemName.Text = item["Name"]
	innerButton.Particles.Visible = false
	
	-- Special coloring
	if color == Color3.fromRGB(0, 0, 0) then
		tile.Frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		innerButton.AccentColor.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		local gradient = game.ReplicatedStorage.GuiElements.RainbowGradient:Clone()
		gradient.Parent = tile.Frame
	end
	
	-- Appropriate Image for currency type
	if cost[2] == "Gems" then
		innerButton.Cost.ImageLabel.Image = GEMS_IMAGE
	else
		innerButton.Cost.ImageLabel.Image = COINS_IMAGE
	end
	
	if category == "Color" then
		GuiUtility.displayPlayerShip(player, innerButton.ShipViewPort, 1)
		local displayedShip = innerButton.ShipViewPort.Physics.Model.RootPart
		for _,part in pairs (displayedShip:GetChildren()) do
			if not item['Color']:FindFirstChild('ShipEffect') and part:FindFirstChild('ShipEffect') then
				part.ShipEffect:Destroy()
			end
			if part.Name == "PrimaryColorPart" or part.Name == "SecondaryColor" then
				GuiUtility.applyColorData(part, item['Color'])
			end
			if part.Name == "Number" then -- Destroy number display
				part:Destroy()
			end
		end
		
		-- Determine if particles are with this color
		if #item['Color']:GetChildren() > 0 then
			innerButton.Particles.Visible = true
		end
		
	elseif category == "Trail" then
		innerButton.Image.Visible = true
		innerButton.Image.Image = item["Folder"].Thruster.Texture
		innerButton.Image.ImageColor3 = item['Folder'].Thruster.Color.Keypoints[1].Value
		
	elseif category == "Laser" then
		
		
	elseif category == "Ship" then
		coroutine.resume(coroutine.create(function()
			local displayedShipLevel = 1
			while tile and tile.Visible do
				wait(2)
				if displayedShipLevel == 11 then
					displayedShipLevel = 1
				end
				
				local shipData = game.ReplicatedStorage.EquipData.Ship:FindFirstChild(item["Name"])
				GuiUtility.displayPlayerShip(player, innerButton.ShipViewPort, displayedShipLevel, shipData)
				displayedShipLevel += 1
			end
		end))
	end
	
	if t["Limited"] ~= nil then
		innerButton.Limited.Visible = true
		innerButton.Limited:FindFirstChild(t['Limited']).Visible = true
	else
		innerButton.Limited.Visible = false
	end
	
	if t["EndTick"] then -- Temporary item in the store
		
		
		
		
	end
	
	if t["Discount"] then -- Dicounted item
		-- Slash through normal price display and display new price
		
	
	end
end

--[[
	Create pages for shop based on given shopData
	@param shopData  Data acquired from server about how pages should be layed out for shop
]]
local function createShop(shopData)
	for i,p in pairs(shopData) do
		local page = guiElements.GenericPage:Clone()
		page.Parent = shopMenu
		page.Name = "Page"..tostring(i)
		
		for _,t in pairs(p) do -- Tiles within page
			local tile = guiElements.ShopTile:Clone()
			tile.Parent = page
			
			positionTile(t, tile)
			
			if t['Item'] ~= 'Coming Soon' then
				local purchased = checkPurchaseEvent:InvokeServer(t['Item']["Name"])
				addProductInfoToTile(t, tile, purchased)
				
				tile.Frame.InnerButton.Activated:Connect(function()
					if not purchased then
						selectSound:Play()
						local cameraTweenInfo = TweenInfo.new(2.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
						TweenService:Create(camera, cameraTweenInfo, {CFrame = physicalShopMenu.SecondShopCamera.CFrame}):Play()
						displayProductPage(t)
					else
						errorSound:Play()
					end
				end)
			else
				-- Invis everything and set image as a question mark
				tile.Frame.InnerButton.Cost.Visible = false
				tile.Frame.InnerButton.AccentColor.Visible = false
				tile.Frame.InnerButton.Particles.Visible = false
				tile.Frame.InnerButton.Purchased.Visible = false
				tile.Frame.InnerButton.ItemName.Text = 'Coming Soon'
				tile.Frame.InnerButton.Image.Image = 'rbxassetid://10954785441' -- Question mark icon
				tile.Frame.InnerButton.Image.ImageColor3 = Color3.fromRGB(85, 170, 255)
				tile.Frame.InnerButton.Image.ScaleType = Enum.ScaleType.Fit
				
				tile.Frame.InnerButton.Activated:Connect(function()
					errorSound:Play()
				end)
			end
			
			-- Hover resize effect
			local startXSize, startYSize = tile.Size.X.Scale, tile.Size.Y.Scale
			local sizeTweenInfo = TweenInfo.new(.5, Enum.EasingStyle.Quint)
			tile.Frame.InnerButton.MouseEnter:Connect(function() -- Too-specific of changes to utilize GuiUtility.resizeButtonEffect()
				script.Parent.HoverSound:Play()
				TweenService:Create(tile, sizeTweenInfo, {Size = UDim2.new(startXSize+.007, 0, startYSize+.007, 0)}):Play()
			end)
			tile.Frame.InnerButton.MouseLeave:Connect(function()
				TweenService:Create(tile, sizeTweenInfo, {Size = UDim2.new(startXSize, 0, startYSize, 0)}):Play()					
			end)
		end
	end
end

-------------------<< Display Menus >>---------------------------------------------------------

--[[
	Show/Invis single-product menu
	@param t  Table with information about the shop tile
]]
function displayProductPage(t)
	resetProductMenu()
	singleProductMenu.Visible = true
	
	-- Move shop menu out of way
	TweenService:Create(shopMenu, barrierTweenInfo, {Position = UDim2.new(0, 0, -1, 0)}):Play()
	TweenService:Create(barriers.Coins, TweenInfo.new(1.5), {Position = UDim2.new(barriers.Coins.OutPosition.Value, 0, barriers.Coins.Position.Y.Scale, 0)}):Play()
	TweenService:Create(barriers.Gems, TweenInfo.new(1.5), {Position = UDim2.new(barriers.Gems.OutPosition.Value, 0, barriers.Gems.Position.Y.Scale, 0)}):Play()
	
	displayNewProduct(t)
	
	-- Bring in additional GUI
	wait(.4)
	TweenService:Create(purchaseButton, TweenInfo.new(2.5, Enum.EasingStyle.Elastic), {Position = UDim2.new(purchaseButton.Position.X.Scale, 0, 0.875)}):Play()
	wait(1)
	TweenService:Create(itemDisplay1, TweenInfo.new(.7, Enum.EasingStyle.Quint), {Position = UDim2.new(itemDisplay1.Position.X.Scale, 0, .119, 0)}):Play()
	TweenService:Create(itemDisplay2, TweenInfo.new(.7, Enum.EasingStyle.Quint), {Position = UDim2.new(itemDisplay2.Position.X.Scale, 0, .127, 0)}):Play()
	TweenService:Create(categoryDisplay, TweenInfo.new(.7), {Position = UDim2.new(.024, 0, categoryDisplay.Position.Y.Scale, 0)}):Play()
	TweenService:Create(costDisplay, TweenInfo.new(.7), {Position = UDim2.new(.021, 0, costDisplay.Position.Y.Scale, 0)}):Play()
end

--[[
	Display/Hide the shop menu
	@param display  True if menu should be displayed
]]
displayShopMenuEvent.Event:Connect(function(display)
	resetShopMenu()
	
	if display then
		updateCurrencyDisplays()
		clientDisplayMainMenuEvent:Fire(false) -- Invis main menu
		
		-- Keep barriers out of frame
		barriers.TopBarrier.Position = UDim2.new(0, 0, -0.2, 0)
		barriers.BottomBarrier.Position = UDim2.new(0, 0, 1.1, 0)
		barriers.BackButton.Position = UDim2.new(barriers.BackButton.Position.X.Scale, 0, 1.1, 0)
		barriers.Coins.Position = UDim2.new(.331, 0, 1.08, 0); barriers.Gems.Position = UDim2.new(.511, 0, 1.08, 0)
		barriers.MenuLabel.Position = UDim2.new(.5, 0, -.15, 0)
		shopMenu.NextPage.Position = UDim2.new(1, 0, shopMenu.NextPage.Position.Y.Scale, 0)
		shopMenu.PrevPage.Position = UDim2.new(-.1, 0, shopMenu.PrevPage.Position.Y.Scale, 0)
		
		-- Move camera over to physical location
		local cameraTweenInfo = TweenInfo.new(7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		TweenService:Create(camera, cameraTweenInfo, {CFrame = physicalShopMenu.ShopCamera.CFrame}):Play()
		createShop(requestShopDataEvent:InvokeServer())
		wait(cameraTweenInfo.Time-6)

		-- Move everything into frame
		if shopMenu:FindFirstChild("Page1") then
			shopMenu.Page1.Position = UDim2.new(0, 0, -.55, 0)
			shopMenu.Page1.Visible = true
			TweenService:Create(shopMenu.Page1, TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
		end
		TweenService:Create(barriers.BottomBarrier,  barrierTweenInfo, {Position = UDim2.new(0, 0, 0.905, 0)}):Play()
		TweenService:Create(barriers.TopBarrier,  barrierTweenInfo, {Position = UDim2.new(0, 0, -0.035, 0)}):Play()
		TweenService:Create(barriers.BackButton,  barrierTweenInfo, {Position = UDim2.new(barriers.BackButton.Position.X.Scale, 0, 0.887, 0)}):Play()
		TweenService:Create(barriers.Coins,  barrierTweenInfo, {Position = UDim2.new(barriers.Coins.InPosition.Value, 0, 0.985, 0)}):Play()
		TweenService:Create(barriers.Gems,  barrierTweenInfo, {Position = UDim2.new(barriers.Gems.InPosition.Value, 0, 0.985, 0)}):Play()
		TweenService:Create(shopMenu.NextPage, barrierTweenInfo, {Position = UDim2.new(0.854, 0, 0.472, 0)}):Play()
		TweenService:Create(shopMenu.PrevPage, barrierTweenInfo, {Position = UDim2.new(0.045, 0, 0.472, 0)}):Play()
		wait(.5)
		TweenService:Create(barriers.MenuLabel,  barrierTweenInfo, {Position = UDim2.new(.5, 0, .035, 0)}):Play()
		
	else
		shopMenu.Visible = false
		barriers.Visible = false

		-- Fade out and display the main menu
		wait(GuiUtility.blackMenuFade(true, 0.05))
		clientDisplayMainMenuEvent:Fire(true)
		wait(0.5)
		GuiUtility.blackMenuFade(false, 0.05)
	end
end)

--[[
	Signal sent by PlayerStatManager whenever data changes
	@param statName  Name of the data that has been updated
	@param value  Value of the data
]]
updateGUIEvent.OnClientEvent:Connect(function(statName, value)
	-- Update currency displays
	if statName == "Coins" or statName == "Gems" then
		barriers:FindFirstChild(statName).Outline.TextLabel.Text = tostring(value)
	end
end)

-------------------------<< Button Activation >>---------------------------------------------------

--[[
	Go back to the main menu after the player pressed the back button
]]
backButton.Activated:Connect(function()
	if backButtonAvailable then
		backButtonAvailable = false
		pressSound:Play()
		
		if singleProductMenu.Visible then -- Back to shop menu
			local cameraTweenInfo = TweenInfo.new(2.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			TweenService:Create(camera, cameraTweenInfo, {CFrame = physicalShopMenu.ShopCamera.CFrame}):Play()
			resetProductMenu(true)
			TweenService:Create(shopMenu, barrierTweenInfo, {Position = UDim2.new(0, 0, 0, 0)}):Play()
		else -- Back to main menu
			wait(GuiUtility.blackMenuFade(true, 0.05))
			clientDisplayMainMenuEvent:Fire(true, false)
			wait(0.5)
			displayShopMenuEvent:Fire(false) 
			wait(GuiUtility.blackMenuFade(false, 0.05))
		end	
		backButtonAvailable = true		
	end
end)

nextPage.Activated:Connect(function()
	GuiUtility.changePage(shopMenu, 1, true)
end)

prevPage.Activated:Connect(function()
	GuiUtility.changePage(shopMenu, -1, true)
end)

barriers:WaitForChild('Gems'):WaitForChild('Outline'):WaitForChild('AddGems').Activated:Connect(function()
	if not script.Parent.Parent.CoinShop.CoinShop.Visible then
		displayGemShopMenuEvent:Fire(true)
	end
end)
barriers:WaitForChild('Gems'):WaitForChild('Outline'):WaitForChild('Plus'):WaitForChild('TextButton').Activated:Connect(function()
	if not script.Parent.Parent.CoinShop.CoinShop.Visible then
		displayGemShopMenuEvent:Fire(true)
	end
end)

barriers:WaitForChild('Coins'):WaitForChild('Outline'):WaitForChild('AddCoins').Activated:Connect(function()
	if not script.Parent.Parent.GemShop.GemShop.Visible then
		displayCoinShopMenuEvent:Fire(true)
	end
end)
barriers:WaitForChild('Coins'):WaitForChild('Outline'):WaitForChild('Plus'):WaitForChild('TextButton').Activated:Connect(function()
	if not script.Parent.Parent.GemShop.GemShop.Visible then
		displayCoinShopMenuEvent:Fire(true)
	end
end)

-----------<< RunTime Events >>------------------------------------

-- Update coin/gem displays with player's info
updateCurrencyDisplays()

