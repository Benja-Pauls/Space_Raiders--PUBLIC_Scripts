local GuiUtility = require(script.Parent.Parent:WaitForChild('GuiUtility'))
local TweenService = game:GetService("TweenService")
local player = game.Players.LocalPlayer
local camera = game.Workspace.CurrentCamera

local eventsFolder = game.ReplicatedStorage:WaitForChild('Events')
local guiEventsFolder = eventsFolder:WaitForChild('GUI')
local displayMyShipMenuEvent = guiEventsFolder:WaitForChild('ClientDisplayMyShipMenu')
local clientDisplayMainMenuEvent = guiEventsFolder:WaitForChild('ClientDisplayMainMenu')
local requestEquipDataCategoryEvent = eventsFolder:WaitForChild('RequestEquipDataCategory')
local getEquippedInfoEvent = eventsFolder:WaitForChild('GetEquippedInfo')
local equipItemEvent = eventsFolder:WaitForChild('EquipItem')
local requestAchievementDataEvent = eventsFolder:WaitForChild('RequestAchievementData')
local checkPurchaseEvent = eventsFolder:WaitForChild('CheckPurchase')

-- Menus and folders
local guiElements = game.ReplicatedStorage:WaitForChild('GuiElements')
local myShipMenu = script.Parent:WaitForChild('MyShipMenu')
local shipBay = workspace:WaitForChild('ShipBay')
local customizeMenu = script.Parent:WaitForChild('CustomizeMenu')
local colorChoiceDisplay = customizeMenu:WaitForChild('ColorChoiceDisplay')

-- Surface displays
local shipTrailDisplay = shipBay.Platform:WaitForChild("ShipTrailDisplay")
local laserTrailDisplay = shipBay.Platform:WaitForChild("LaserTrailDisplay")
local colorParticleDisplay = shipBay.Platform:WaitForChild('ColorParticleDisplay')
local shipViewport = script.Parent:WaitForChild('MyShipView'):WaitForChild("ShipViewPort")
local smallShipViewport = script.Parent:WaitForChild("SmallMyShipView"):WaitForChild('SmallShipViewPort')
local laserDisplay = script.Parent:WaitForChild('LaserView'):WaitForChild("LaserViewPort")
local sideDisplay = script.Parent:WaitForChild("SideDisplay")

-- Buttons
local upArrow = customizeMenu:WaitForChild("UpArrow")
local downArrow = customizeMenu:WaitForChild("DownArrow")
local equipButton = customizeMenu:WaitForChild("EquipButton")
local shipButton = myShipMenu:WaitForChild("ShipButton")
local trailsButton = myShipMenu:WaitForChild('TrailsButton')
local colorsButton = myShipMenu:WaitForChild('ColorsButton')
local titleButton = myShipMenu:WaitForChild("TitleButton")
local backButton = script.Parent.Barriers:WaitForChild('BackButton')

local levelDisplay = script.Parent:WaitForChild("LevelDisplay")
local levelDisplayed = 1

local hoverSound = script.Parent.Parent:WaitForChild('ButtonHover')
local pressSound = script.Parent.Parent:WaitForChild('ButtonPress')
local switchSound = script.Parent.Parent:WaitForChild('Switch')
local equipSound = script.Parent.Parent:WaitForChild('Equip')
local errorSound = script.Parent.Parent:WaitForChild('Error')


------------------<< Utility Functions >>----------------------------------------
local checkImage = "rbxassetid://9896265355"
local checkHoverImage = "rbxassetid://9896285524"
local unCheckImage = "rbxassetid://9896203011"
local unCheckHoverImage = "rbxassetid://9896223396"
local grayedOutCheckImage = "rbxassetid://9903950665"

local grayedOutEquipButton = "rbxassetid://9903264705"
local equipButtonSTATIC = "rbxassetid://9902574297"
local equipButtonHOVER = "rbxassetid://9902560875"
local equipButtonPRESSED = "rbxassetid://9902591276"

--[[
	Helper method for color-change buttons and updating their check marks
	Is also responsible for graying-out the equipbutton for the color menu
	
	@param name  First called with "Primary", then this function calls itself for the secondary/laser buttons
	@param justOne  Value of the apply if actually only updating for one button
]]
local function updateAllCheckImages(name, justOne)
	-- Update the equip button to be its proper color]
	local itemName = customizeMenu.TileName.Value
	local equipData = getEquippedInfoEvent:InvokeServer(player)
	local primaryCheck = (equipData[5]["Name"] == itemName) == colorChoiceDisplay.PrimaryApply.Value
	local secondaryCheck = (equipData[6]["Name"] == itemName) == colorChoiceDisplay.SecondaryApply.Value
	local laserCheck = (equipData[7]["Name"] == itemName) == colorChoiceDisplay.LaserApply.Value
	
	-- Update the equip button similarly
	if primaryCheck and secondaryCheck and laserCheck then
		equipButton.Image = grayedOutEquipButton
		equipButton.HoverImage = grayedOutEquipButton
		equipButton.PressedImage = grayedOutEquipButton
	else
		equipButton.Image = equipButtonSTATIC
		equipButton.HoverImage = equipButtonHOVER
		equipButton.PressedImage = equipButtonPRESSED
	end
	
	-- TODO:
	-- Need to make it so all boxes are checked when you select a new color and the effect is applied
	-- However, when you uncheck a button, it doesn't remove the status
	
	
	
	-- Change the image of the checkbox to the appropriate type
	local image = unCheckImage
	local hoverImage = unCheckHoverImage
	if colorChoiceDisplay:FindFirstChild(name .. "Apply").Value then
		image = checkImage
		hoverImage = checkHoverImage
	end
	local quickRef = {["Primary"] = 5, ["Secondary"] = 6, ["Laser"] = 7}
	local match = equipData[quickRef[name]]["Name"] == itemName
	local button = colorChoiceDisplay:FindFirstChild(name .. "Color")
	if match then
		button.Image = grayedOutCheckImage
		button.HoverImage = grayedOutCheckImage
		button.PressedImage = grayedOutCheckImage
	else
		button.Image = image
		button.HoverImage = hoverImage
		button.PressedImage = image
	end

	-- Do for rest of checkmarks if doing that
	if name == "Primary" and not justOne then
		updateAllCheckImages("Secondary")
		updateAllCheckImages("Laser")
	end
end

--[[
	Return all displays to a common 'control' point for the categories to display info
]]
local function resetAllCategoryViews()
	GuiUtility.hideOtherViewPorts()
	levelDisplay.Enabled = true
	equipButton.Visible = false
	customizeMenu.CategoryName.Value = ""
	customizeMenu.TileName.Value = ""
	customizeMenu.Locked.Visible = false
	customizeMenu.ShipView.Visible = false
	customizeMenu.CurrentShipText.Visible = false
	
	equipButton.Image = equipButtonSTATIC
	equipButton.HoverImage = equipButtonHOVER
	equipButton.PressedImage = equipButtonPRESSED
	
	shipViewport.Parent.ShipName.Value = ""
	
	-- Trails category displays
	if shipTrailDisplay:FindFirstChild("Thruster") then
		shipTrailDisplay.Thruster:Destroy()
	end
	if laserTrailDisplay:FindFirstChild("Laser") then
		laserTrailDisplay.Laser:Destroy()
	end
	for _,p in pairs (colorParticleDisplay:GetChildren()) do
		if p:IsA("ParticleEmitter") then
			p:Destroy()
		end
	end
	shipTrailDisplay.NameDisplay.SurfaceGui.Enabled = false
	laserTrailDisplay.NameDisplay.SurfaceGui.Enabled = false
	colorParticleDisplay.NameDisplay.SurfaceGui.Enabled = false

	-- Colors category displays
	colorChoiceDisplay.CurrentColor.Value = nil
	customizeMenu.ColorChoiceDisplay.Visible = false
	colorChoiceDisplay.PrimaryApply.Value = true
	colorChoiceDisplay.SecondaryApply.Value = true
	colorChoiceDisplay.LaserApply.Value = true

	-- Laser category display
	if shipBay.Platform.Viewport:FindFirstChild("Laser") then -- Also for Colors category
		shipBay.Platform.Viewport.Laser:Destroy()
	end
end

-------------------<< Menu Functions >>------------------------------------
local staticCustomizeTileImage = "rbxassetid://9842202392"
local hoverCustomizeTileImage = "rbxassetid://9864919949"
local selectedCustomizeTileImage = "rbxassetid://9866930927"
local whiteTextColor = Color3.fromRGB(240, 240, 240)
local blueTextColor = Color3.fromRGB(1, 196, 255)

--[[
	Helper method simply for appropriately coloring parts of the player's ship
	@param playerShip  Ship that will have its colors changed
	@param color  Color that will be applied to the parts of the player's ship
	@param primary  True if it's a primary color, false if secondary
	@param laser  True if color should only be applied to number
]]
local function applyColorToShip(playerShip, color, primary, laser)
	for _,part in pairs(playerShip:GetChildren()) do
		if not laser then
			if (part.Name == "PrimaryColorPart" and primary) or (part.Name == "SecondaryColorPart" and not primary) then
				if not color:FindFirstChild('ShipEffect') and part:FindFirstChild('ShipEffect') then
					part.ShipEffect:Destroy()
				end
				GuiUtility.applyColorData(part, color)
			end
		elseif part.Name == 'Number' then
			part.Color = color.Color
		end
	end
end

--[[
	Apply the currently-viewing color to the laser model
]]
local function applyColorToLaser()
	local laserModel = shipBay.Platform.Viewport:FindFirstChild("Laser")
	if laserModel then
		if colorChoiceDisplay.LaserApply.Value then
			laserModel.Color = colorChoiceDisplay.CurrentColor.Value.Color
		else
			local laserColor = getEquippedInfoEvent:InvokeServer(player)[7]["Color"].Color
			laserModel.Color = laserColor
		end
		laserModel.PointLight.Color = laserModel.Color
	end
end

--[[
	Display lock screen over item
	@param description  Description to help player understand what they need to do in order to unlock item
]]
local function showLockScreen(description)
	equipButton.Image = grayedOutEquipButton
	equipButton.HoverImage = grayedOutEquipButton
	equipButton.PressedImage = grayedOutEquipButton
	colorChoiceDisplay.Visible = false

	customizeMenu.Locked.Visible = true
	customizeMenu.Locked.Description.Text = description
end

--[[
	For tiles in customize menu, see which ones should be shown as locked
	@param categoryData: Contains info about the item for that tile
	@param tile: tile GUI
]]
local function applyLockSymbol(categoryData, tile)
	local equipItemName = string.gsub(tile.TextLabel.Text, "<b>", "")
	equipItemName = string.gsub(equipItemName, "</b>", "")
	
	-- Find achievement
	local achievementName
	for _,item in pairs (categoryData) do
		if achievementName == nil and item['Name'] == equipItemName then
			if item['ReferenceTracker'] ~= nil then -- This is a title tile being displayed
				achievementName = 'Title'
			else -- Item title being displayed (ship/color/trail)               
				achievementName = item['Required Achievement']
			end
		end
	end
	
	local locked = false
	if achievementName and achievementName ~= 'ShopPurchase' and achievementName ~= 'Title' then
		local status,value,achievementInfo = requestAchievementDataEvent:InvokeServer(achievementName)
		if status == 'Locked' or status == "Claim" then
			locked = true
		end
	elseif achievementName and achievementName == 'ShopPurchase' then
		if not checkPurchaseEvent:InvokeServer(equipItemName) then
			locked = true
		end
	elseif achievementName == 'Title' then
		local status,value,achievementInfo = requestAchievementDataEvent:InvokeServer(equipItemName)
		locked = status == 'Locked'
	end
	
	if locked then
		tile.ImageColor3 = Color3.fromRGB(117, 117, 117)
	else
		tile.ImageColor3 = Color3.fromRGB(255, 255, 255)
	end
	tile.LockedIcon.Visible = locked
	tile.Shade.Visible = locked
end

--[[
	Updates the level displayed and which ship is currently being showcased to the player
	@param direction  Changes the level by some amount
]]
local function updateShipLevelDisplayed(direction)
	levelDisplayed += direction
	if levelDisplayed < 1 then
		levelDisplayed = 10
	elseif levelDisplayed > 10 then
		levelDisplayed = 1
	end
	levelDisplay.Screen.Level.Text = "Level " .. tostring(levelDisplayed)
	
	local display
	if shipViewport.Parent.Enabled == false then
		display = smallShipViewport
		GuiUtility.displayPlayerShip(player, smallShipViewport, levelDisplayed)
	else
		display = shipViewport
	
		if shipViewport.Parent.ShipName.Value ~= "" then
			local shipInfo = game.ReplicatedStorage.EquipData.Ship:FindFirstChild(shipViewport.Parent.ShipName.Value)
			if shipInfo then
				GuiUtility.displayPlayerShip(player, shipViewport, levelDisplayed, shipInfo)
			else
				GuiUtility.displayPlayerShip(player, shipViewport, levelDisplayed)
			end
		else
			GuiUtility.displayPlayerShip(player, shipViewport, levelDisplayed)
		end
	end
	
	-- Update level displayed of tiny ship view too
	if customizeMenu.ShipView.Visible then
		GuiUtility.displayPlayerShip(player, customizeMenu.ShipView.ShipViewPort, levelDisplayed)
	end
	
	-- Upkeep the colors if the player is currently customizing their ship
	if display.Physics:FindFirstChild("Model") and display.Physics.Model:FindFirstChild("RootPart") then
		local shipModel = display.Physics.Model.RootPart
		local color = colorChoiceDisplay.CurrentColor.Value
		
		if color ~= nil then -- Has not been set yet
			if colorChoiceDisplay.PrimaryApply.Value then
				applyColorToShip(shipModel, color, true)
			end
			if colorChoiceDisplay.SecondaryApply.Value then
				applyColorToShip(shipModel, color, false)
			end
			if colorChoiceDisplay.LaserApply.Value then
				applyColorToShip(shipModel, color, false, true)
			end
		end
	end
end

--[[
	Spawn a physical laser to display so players can see the neon effect
	@param laser  The laser model that will be moved into position
	@param view  View whose CFrame will be where the laser is
]]
local function displayLaser(laser, view)
	laser.Name = "Laser"
	laser.Parent = shipBay.Platform.Viewport -- Always this parent
	laser.CFrame = view.CFrame
	laser.PointLight.Color = laser.Color
	laser.VectorForce:Destroy()
	laser.NoGrav:Destroy()
	laser.Anchored = true
	
	-- Rotate the object
	coroutine.resume(coroutine.create(function()
		while laser do
			laser.CFrame = laser.CFrame * CFrame.Angles(0, math.rad(-1), 0)
			wait()
		end
	end))
end

--[[
	Display the effects of the currently-selected tile on the displayed objects for the player to easily see their effects
	@param categoryData  All data for that current category (cloned from EquipData)
	@param categoryName  Easy access to the category name
	@param currentTile  Tile the player selected
]]
local function displayCustomizeTileInfo(categoryData, categoryName, currentTile)
	local equipItemName = string.gsub(currentTile.TextLabel.Text, "<b>", "")
	equipItemName = string.gsub(equipItemName, "</b>", "")
	--print("VALUES: ", categoryData, equipItemName, categoryData[equipItemName])
	
	local equipItemData
	for _,item in pairs (categoryData) do
		if equipItemData == nil and item['Name'] == equipItemName then
			equipItemData = item
		end
	end
	
	-- Reset all buttons to non-selected color except for newly-selected tile
	for _,page in pairs (customizeMenu:GetChildren()) do
		if page:IsA("Frame") and string.match(page.Name, "Page") ~= nil then
			for _,tile in pairs (page:GetChildren()) do
				if tile == currentTile then
					tile.Image = selectedCustomizeTileImage
					tile.HoverImage = selectedCustomizeTileImage
					tile.TextLabel.TextColor3 = whiteTextColor
				else
					tile.Image = staticCustomizeTileImage
					tile.HoverImage = hoverCustomizeTileImage
					tile.TextLabel.TextColor3 = blueTextColor
				end
			end
		end
	end
	
	resetAllCategoryViews() -- Resets all menus to common "conrol" point where you can build up the category's required display
	customizeMenu.CategoryName.Value = categoryName
	customizeMenu.TileName.Value = equipItemName
	customizeMenu.ShipView.Visible = true
	customizeMenu.CurrentShipText.Visible = true
	
	-- See if player has the achievement/purchase to equip this item
	local achievementStatus
	local achievementName
	local achievementName = equipItemData["Required Achievement"]
	if achievementName and achievementName ~= "ShopPurchase" then
		local status,value,achievementInfo = requestAchievementDataEvent:InvokeServer(achievementName)
		achievementStatus = status
		if achievementStatus == "Locked" or achievementStatus == "Claim" then
			showLockScreen(achievementInfo["Description"])
		end
	elseif achievementName == "ShopPurchase" then
		local purchased = checkPurchaseEvent:InvokeServer(equipItemName)
		if not purchased then
			showLockScreen("Purchase this item in the shop to unlock")
			achievementStatus = "Locked"
		else
			achievementStatus = "Claimed"
		end
	elseif categoryName == 'Title' then
		if currentTile.LockedIcon.Visible then
			showLockScreen("Unlock the achievement '" .. equipItemData['Name'] .. "' to equip")
			achievementStatus = 'Locked'
		else
			achievementStatus = 'Claimed'
		end
	end
	
	-- Display the changes caused by the selected tile, as well as what the player already has equipped
	local currentlyEquippedData = getEquippedInfoEvent:InvokeServer(player)
	if categoryName == "Colors" then
		colorChoiceDisplay.CurrentColor.Value = equipItemData["Color"]
		smallShipViewport.Parent.Enabled = true
		laserDisplay.Parent.Enabled = true

		-- Actually display the laser and ship model the player has equipped 
		GuiUtility.displayPlayerShip(player, smallShipViewport, levelDisplayed, currentlyEquippedData[1]["Model"])
		local laser = currentlyEquippedData[2]["Model"]:Clone() -- Physical display of laser to see neon effect
		displayLaser(laser, shipBay.Platform.LaserViewport)
		applyColorToLaser()
		local shipModel = smallShipViewport.Physics.Model.RootPart
		applyColorToShip(shipModel, colorChoiceDisplay.CurrentColor.Value, true)
		applyColorToShip(shipModel, colorChoiceDisplay.CurrentColor.Value, false)
		applyColorToShip(shipModel, colorChoiceDisplay.CurrentColor.Value, false, true)
		
		-- Showcase additional effects of paint job
		for _,p in pairs (colorChoiceDisplay.CurrentColor.Value:GetChildren()) do
			if p:IsA("ParticleEmitter") then
				p = p:Clone()
				p.Parent = colorParticleDisplay
			end
		end
		if #colorParticleDisplay:GetChildren() > 1 then
			colorParticleDisplay.NameDisplay.SurfaceGui.Enabled = true
		end
		
		-- Leave all checks as true on first open so player can see color fully
		updateAllCheckImages("Primary") -- Makes the equip button gray since colorMatch and colorApply always == here
		if achievementStatus ~= "Locked" and achievementStatus ~= 'Claim' then
			colorChoiceDisplay.Visible = true
		else
			colorChoiceDisplay.Visible = false
		end
		
	elseif categoryName == "Trails" then
		levelDisplay.Enabled = false
		local shipTrailEffect = equipItemData["Folder"].Thruster:Clone()
		local laserTrailEffect = equipItemData["Folder"].Laser:Clone()
		
		shipTrailEffect.Parent = shipTrailDisplay
		laserTrailEffect.Parent = laserTrailDisplay
		shipTrailEffect.Acceleration = Vector3.new(0, 0, -50)
		laserTrailEffect.Acceleration = Vector3.new(0, 0, -50)
		GuiUtility.hideOtherViewPorts()
		
		shipTrailDisplay.NameDisplay.SurfaceGui.Enabled = true
		laserTrailDisplay.NameDisplay.SurfaceGui.Enabled = true
		
		-- Update the equip button
		if currentlyEquippedData[3]["Name"] == equipItemName and currentlyEquippedData[4]["Name"] == equipItemName then
			equipButton.Image = grayedOutEquipButton
			equipButton.HoverImage = grayedOutEquipButton
			equipButton.PressedImage = grayedOutEquipButton
		end
		
	elseif categoryName == "Laser" then -- LASER MENU WILL SIMPLY BE UPDATING THE MODEL OF THE LASER WITH THE PLAYER's EQUIPPED COLOR
		levelDisplay.Enabled = false
		
		-- Display physical laser in order to see neon effect
		GuiUtility.hideOtherViewPorts()
		local laser = equipItemData["Model"]:Clone()
		displayLaser(laser, shipBay.Platform.Viewport)
		
		-- Update the equip button
		if currentlyEquippedData[2]["Name"] == equipItemName then
			equipButton.Image = grayedOutEquipButton
			equipButton.HoverImage = grayedOutEquipButton
			equipButton.PressedImage = grayedOutEquipButton
		end
		
	elseif categoryName == 'Title' then
		GuiUtility.displayPlayerShip(player, shipViewport, levelDisplayed)
		
	elseif categoryName == "Ship" then -- SHIP MENU WILL SIMPLY BE UPDATING THE MODEL OF THE SHIP WITH THE PLAYER's EQUIPPED COLORS
		shipViewport.Parent.Enabled = true
		GuiUtility.displayPlayerShip(player, shipViewport, levelDisplayed, equipItemData["Model"])
		shipViewport.Parent.ShipName.Value = tostring(equipItemData["Model"])
		
		-- Update the equip button
		if currentlyEquippedData[1]["Name"] == equipItemName then
			equipButton.Image = grayedOutEquipButton
			equipButton.HoverImage = grayedOutEquipButton
			equipButton.PressedImage = grayedOutEquipButton
		end	
	end
	
	if achievementStatus == "Locked" or achievementStatus == "Claim" then
		equipButton.Image = grayedOutEquipButton
		equipButton.HoverImage = grayedOutEquipButton
		equipButton.PressedImage = grayedOutEquipButton
	end
	
	equipButton.Visible = true
end

--[[
	Display the menu that contains the possible items the player can equip
	@param categoryName  Category that will be displayed
]]
local buttonDebounce = false
local menuButtonDebounce = false
local function displayCustomizeMenu(categoryName)	
	local tweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	for _,button in pairs(myShipMenu:GetChildren()) do
		if button:IsA("ImageButton") then
			TweenService:Create(button, tweenInfo, {Position = UDim2.new(-0.5, 0, button.Position.Y.Scale, 0)}):Play()
			wait(.1)
		end
	end

	-- Create all the pages that will be required to display all the data for the category the player requested
	local categoryData, tileCount = requestEquipDataCategoryEvent:InvokeServer(categoryName)
	GuiUtility.pageLoad(customizeMenu, categoryData, tileCount)
	
	-- Display current ship
	GuiUtility.displayPlayerShip(player, customizeMenu.ShipView.ShipViewPort, levelDisplayed)
	customizeMenu.ShipView.Visible = true
	customizeMenu.CurrentShipText.Visible = true
	
	-- Add functionality to all the loaded tiles
	for _,page in pairs (customizeMenu:GetChildren()) do
		if page:IsA("Frame") and string.match(page.Name, "Page") ~= nil then
			for _,tile in pairs (page:GetChildren()) do
				if tile:IsA("ImageButton") and string.match(tile.Name, "Tile") ~= nil then
					
					-- Add lock symbol if locked
					applyLockSymbol(categoryData, tile)
					
					-- Limited-Time-Item status or not
					local equipItemName = string.gsub(tile.TextLabel.Text, "<b>", "")
					equipItemName = string.gsub(equipItemName, "</b>", "")
					local equipItemData
					for _,item in pairs (categoryData) do
						if equipItemData == nil and item['Name'] == equipItemName then
							equipItemData = item
						end
					end
					if equipItemData["Limited"] ~= nil then
						tile.Limited.Visible = true
						tile.Limited:FindFirstChild(equipItemData['Limited']).Visible = true
					else
						tile.Limited.Visible = false
					end
					
					-- Change text color on mouse enter or mouse leave
					tile.MouseEnter:Connect(function()
						tile.TextLabel.TextColor3 = whiteTextColor
						hoverSound:Play()
					end)
					tile.MouseLeave:Connect(function()
						if tile.Image ~= selectedCustomizeTileImage then
							tile.TextLabel.TextColor3 = blueTextColor
						end
					end)

					-- What occurs when each tile is pressed by the player
					tile.Activated:Connect(function()
						if buttonDebounce == false then
							buttonDebounce = true
							pressSound:Play()
							displayCustomizeTileInfo(categoryData, categoryName, tile)
							buttonDebounce = false
						end
					end)
					tile.Shade.Activated:Connect(function()
						if buttonDebounce == false then
							buttonDebounce = true
							pressSound:Play()
							displayCustomizeTileInfo(categoryData, categoryName, tile)
							buttonDebounce = false
						end
					end)
					GuiUtility.resizeButtonEffect(tile, hoverSound)
				end
			end
		end
	end
	wait(1)
	
	-- Display the Scroll Menu
	customizeMenu.Position = UDim2.new(-1, 0, 0, 0) -- off-screen
	customizeMenu.Visible = true
	tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	TweenService:Create(customizeMenu, tweenInfo, {Position = UDim2.new(0, 0, 0, 0)}):Play()
	
	-- Update the ship with the effect of Tile1 on Page1
	displayCustomizeTileInfo(categoryData, categoryName, customizeMenu.Page1.Tile1)
	
	-- Update the display on if the player has access to the equippable for Tile1 on Page1
	
	
	
	
	
	
end

------------------<< Button Functionality >>-------------------------------------
local rightLvlArrow = levelDisplay.Screen.RightArrow
local leftLvlArrow = levelDisplay.Screen.LeftArrow

--[[
	Increase the level displayed. If at 10, reset to 1
]]
rightLvlArrow.Activated:Connect(function()
	updateShipLevelDisplayed(1)
end)

--[[
	Decrease the level displayed. If at 1, reset to 10
]]
leftLvlArrow.Activated:Connect(function()
	updateShipLevelDisplayed(-1)
end)

--[[
	Go back one page. If at first page, go to the last page
	Checks if there are any pages before doing anything
]]
upArrow.Activated:Connect(function()
	GuiUtility.changePage(customizeMenu, -1)
end)
upArrow.MouseEnter:Connect(function()
	hoverSound:Play()
end)

--[[
	Go forward one page. If at last page, go to the first page
	Checks if there are any pages before doing anything
]]
downArrow.Activated:Connect(function()
	GuiUtility.changePage(customizeMenu, 1)
end)
downArrow.MouseEnter:Connect(function()
	hoverSound:Play()
end)

-- Button activations for each customization type
for _,button in pairs (myShipMenu:GetChildren()) do
	if button:IsA("ImageButton") then
		button.Activated:Connect(function()
			if not menuButtonDebounce then
				menuButtonDebounce = true
				pressSound:Play()
				displayCustomizeMenu(string.gsub(button.Name, "Button", ""))
				menuButtonDebounce = false
			end
		end)
		GuiUtility.resizeButtonEffect(button, hoverSound)
	end
end



--[[
	Updating the color-changing buttons
]]
local primaryColorButton = colorChoiceDisplay.PrimaryColor
-- updateAllCheckImages("Primary")
primaryColorButton.Activated:Connect(function()
	if primaryColorButton.Image ~= grayedOutCheckImage then
		switchSound:Play()
		colorChoiceDisplay.PrimaryApply.Value = not colorChoiceDisplay.PrimaryApply.Value
		updateAllCheckImages("Primary", true)
		
		local shipModel = smallShipViewport.Physics.Model.RootPart
		if colorChoiceDisplay.PrimaryApply.Value then
			applyColorToShip(shipModel, colorChoiceDisplay.CurrentColor.Value, true)
		else
			local primaryColor = getEquippedInfoEvent:InvokeServer(player)[5]["Color"]
			applyColorToShip(shipModel, primaryColor, true)
		end
	else
		errorSound:Play()
	end
end)
local secondaryColorButton = colorChoiceDisplay.SecondaryColor
secondaryColorButton.Activated:Connect(function()
	if secondaryColorButton.Image ~= grayedOutCheckImage then
		switchSound:Play()
		colorChoiceDisplay.SecondaryApply.Value = not colorChoiceDisplay.SecondaryApply.Value
		updateAllCheckImages("Secondary", true)
		
		local shipModel = smallShipViewport.Physics.Model.RootPart
		if colorChoiceDisplay.SecondaryApply.Value then
			applyColorToShip(shipModel, colorChoiceDisplay.CurrentColor.Value, false)
		else
			local secondaryColor = getEquippedInfoEvent:InvokeServer(player)[6]["Color"]
			applyColorToShip(shipModel, secondaryColor, false)
		end
	else
		errorSound:Play()
	end
end)
local laserColorButton = colorChoiceDisplay.LaserColor
laserColorButton.Activated:Connect(function()
	if laserColorButton.Image ~= grayedOutCheckImage then
		switchSound:Play()
		colorChoiceDisplay.LaserApply.Value = not colorChoiceDisplay.LaserApply.Value
		updateAllCheckImages("Laser", true)
		applyColorToLaser()
		
		local shipModel = smallShipViewport.Physics.Model.RootPart
		if colorChoiceDisplay.LaserApply.Value then
			applyColorToShip(shipModel, colorChoiceDisplay.CurrentColor.Value, false, true)
		else
			local laserColor = getEquippedInfoEvent:InvokeServer(player)[7]['Color']
			applyColorToShip(shipModel, laserColor, false, true)
		end
	else
		errorSound:Play()
	end
end)

--[[
	When equip button is pressed, send request to server to update the player's equipped data
]]
equipButton.Activated:Connect(function()
	if equipButton.Image == equipButtonSTATIC then
		equipSound:Play()
		local categoryName = customizeMenu.CategoryName.Value
		local tileName = customizeMenu.TileName.Value
		
		if categoryName ~= "" and tileName ~= "" then
			if categoryName == "Colors" then
				local primaryApply = colorChoiceDisplay.PrimaryApply.Value
				local secondaryApply = colorChoiceDisplay.SecondaryApply.Value
				local laserApply = colorChoiceDisplay.LaserApply.Value

				if primaryApply then
					equipItemEvent:FireServer(categoryName, tileName, "EquippedPrimaryShipColor")
				end
				if secondaryApply then
					equipItemEvent:FireServer(categoryName, tileName, "EquippedSecondaryShipColor")
				end
				if laserApply then
					equipItemEvent:FireServer(categoryName, tileName, "EquippedLaserColor")
				end
				
				-- Gray-out all the checkmarked boxes
				for _,button in pairs (colorChoiceDisplay:GetChildren()) do
					if button:IsA("ImageButton") and string.match(button.Name, "Color") ~= nil then
						if button.Image == checkImage then
							button.Image = grayedOutCheckImage
							button.HoverImage = grayedOutCheckImage
							button.PressedImage = grayedOutCheckImage
						end
					end
				end

			elseif categoryName == "Trails" then
				-- Change both the laser and ship trails
				equipItemEvent:FireServer(categoryName, tileName, "EquippedLaserTrail")
				equipItemEvent:FireServer(categoryName, tileName, "EquippedShipTrail")

			elseif categoryName == "Laser" then
				equipItemEvent:FireServer(categoryName, tileName, "EquippedLaser")

			elseif categoryName == "Ship" then
				equipItemEvent:FireServer(categoryName, tileName, "EquippedShip")
			elseif categoryName == 'Title' then
				equipItemEvent:FireServer(categoryName, tileName, 'EquippedTitle')
			end
			
			-- Reset the equip button to gray immediately
			equipButton.Image = grayedOutEquipButton
			equipButton.HoverImage = grayedOutEquipButton
			equipButton.PressedImage = grayedOutEquipButton
			
			-- Update the ship display on top-right
			GuiUtility.displayPlayerShip(player, customizeMenu.ShipView.ShipViewPort, levelDisplayed)
		end
	else -- Must be a grayed-out equip button
		errorSound:Play()
	end
end)

--[[
	Manage the visibility of menus in MyShipMenu when pressing the back button
]]
local backButtonAvailable = true
backButton.Activated:Connect(function()
	if backButtonAvailable and not menuButtonDebounce then
		backButtonAvailable = false; menuButtonDebounce = true
		pressSound:Play()
		
		if customizeMenu.Visible == true then -- go back to the myShipMenu
			levelDisplay.Enabled = true
			
			-- Display player's ship again
			GuiUtility.displayPlayerShip(player, shipViewport, 1)
			levelDisplayed = 1
			levelDisplay.Screen.Level.Text = 'Level 1'
			
			-- Ensure Trail Menu is all closed up
			resetAllCategoryViews()
			GuiUtility.hideOtherViewPorts(shipViewport)
			
			-- Move customize menu out of the way and destroy its pages since they are no longer being used
			local tweenInfo = TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			TweenService:Create(customizeMenu, tweenInfo, {Position = UDim2.new(-1, 0, 0, 0)}):Play()
			
			wait(0.6)
			
			-- Show category buttons again
			for _,button in pairs(myShipMenu:GetChildren()) do
				if button:IsA("ImageButton") then
					local normPos = button.NormalPosition.Value
					TweenService:Create(button, tweenInfo, {Position = UDim2.new(normPos.X, 0, normPos.Y, 0)}):Play()
					wait(.1)
				end
			end

			wait(0.5)
			customizeMenu.Visible = false
			customizeMenu.Position = UDim2.new(0, 0, 0, 0)
			for _,page in pairs (customizeMenu:GetChildren()) do
				if page:IsA("Frame") and string.match(page.Name, "Page") ~= nil then
					page:Destroy()
				end
			end

		else -- Close the entire myShipMenu
			menuButtonDebounce = true
			GuiUtility.blackMenuFade(true, 0.05)
			clientDisplayMainMenuEvent:Fire(true)
			wait(0.5)
			wait(GuiUtility.blackMenuFade(false, 0.05))
			menuButtonDebounce = false
		end
		
		backButtonAvailable = true; menuButtonDebounce = false
	end
end)
backButton.MouseEnter:Connect(function()
	hoverSound:Play()
end)


--[[
	First displaying the MyShipMenu from the MainMenu
]]
displayMyShipMenuEvent.Event:Connect(function()
	resetAllCategoryViews()

	-- Hide main menu and myShipMenu GUI
	clientDisplayMainMenuEvent:Fire(false)
	for _,gui in pairs (script.Parent:GetChildren()) do
		if gui:IsA("Frame") then
			gui.Visible = false
		end
	end

	-- Display level 1 ship to start
	levelDisplayed = 1
	shipViewport.Parent.Enabled = true
	levelDisplay.Enabled = true
	levelDisplay.Screen.Level.Text = "Level 1"
	GuiUtility.displayPlayerShip(player, shipViewport, levelDisplayed)
	sideDisplay.Screen.TopLabel.Visible = true
	sideDisplay.Screen.BottomLabel.Visible = true
	sideDisplay.Screen.TopLabel.Text = "Welcome Back"
	sideDisplay.Screen.BottomLabel.Text = tostring(player)

	-- Move camera to ship hangar
	local cameraTweenInfo = TweenInfo.new(5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	TweenService:Create(camera, cameraTweenInfo, {CFrame = shipBay.MyShipMenuCamera.CFrame}):Play()

	-- Open Doors
	wait(1.2)
	local doorTweenInfo = TweenInfo.new(.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local rightDoorTween = TweenService:Create(shipBay.RightDoor, doorTweenInfo, {Position = shipBay.RightDoor.Open.Value})
	local leftDoorTween = TweenService:Create(shipBay.LeftDoor, doorTweenInfo, {Position = shipBay.LeftDoor.Open.Value})
	rightDoorTween:Play()
	leftDoorTween:Play()
	script.Sound:Play()
	wait(2)

	-- Close doors
	shipBay.RightDoor.Position = shipBay.RightDoor.Closed.Value
	shipBay.LeftDoor.Position = shipBay.LeftDoor.Closed.Value

	-- Ensure buttons are in appropriate position
	shipButton.Position = UDim2.new(shipButton.NormalPosition.Value.X, 0, shipButton.NormalPosition.Value.Y, 0)
	trailsButton.Position = UDim2.new(trailsButton.NormalPosition.Value.X, 0, trailsButton.NormalPosition.Value.Y, 0)
	colorsButton.Position = UDim2.new(colorsButton.NormalPosition.Value.X, 0, colorsButton.NormalPosition.Value.Y, 0)
	titleButton.Position = UDim2.new(titleButton.NormalPosition.Value.X, 0, titleButton.NormalPosition.Value.Y, 0)

	-- Display UI
	local barriers = script.Parent.Barriers
	myShipMenu.Visible = true
	barriers.TopBarrier.Position = UDim2.new(0, 0, -0.1, 0)
	barriers.BottomBarrier.Position = UDim2.new(0, 0, 1.1, 0)
	barriers.BackButton.Position = UDim2.new(barriers.BackButton.Position.X.Scale, 0, 1.1, 0)
	barriers.MenuLabel.Position = UDim2.new(0.5, 0, -.15, 0)
	barriers.Visible = true
	for _,button in pairs (myShipMenu:GetChildren()) do
		if button:IsA("ImageButton") then
			button.Visible = true
			button.Position = UDim2.new(-0.5, 0, button.Position.Y.Scale, 0)
		end
	end
	GuiUtility.fadeMenu(myShipMenu, false)
	wait(0.5)
	TweenService:Create(barriers.BottomBarrier, doorTweenInfo, {Position = UDim2.new(0, 0, 0.905, 0)}):Play()
	TweenService:Create(barriers.TopBarrier, doorTweenInfo, {Position = UDim2.new(0, 0, -0.035, 0)}):Play()
	TweenService:Create(barriers.BackButton, doorTweenInfo, {Position = UDim2.new(barriers.BackButton.Position.X.Scale, 0, 0.887, 0)}):Play()

	-- Tween buttons into frame
	local tweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	for _,button in pairs(myShipMenu:GetChildren()) do
		if button:IsA("ImageButton") then
			TweenService:Create(button, tweenInfo, {Position = UDim2.new(button.NormalPosition.Value.X, 0, button.NormalPosition.Value.Y, 0)}):Play()
			wait(.1)
		end
	end
	TweenService:Create(barriers.MenuLabel, doorTweenInfo, {Position = UDim2.new(.5, 0, .035, 0)}):Play()
end)











