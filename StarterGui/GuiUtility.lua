local GuiUtility = {}
local TweenService = game:GetService("TweenService")


local eventsFolder = game.ReplicatedStorage.Events
local getEquippedInfoEvent = eventsFolder:WaitForChild('GetEquippedInfo')

local guiElements = game.ReplicatedStorage:WaitForChild('GuiElements')

--[[
	Check the visiblily of all the micro menus (GemShop, CoinShop, DailyReward, CodesInput)
	@return True if all of the micro menus are invisible 
]]
function GuiUtility.checkVisOfMicroMenus()
	local microMenus = {
		script.Parent.CoinShop.CoinShop,
		script.Parent.GemShop.GemShop,
		script.Parent.CodesInput.CodeMenu,
		script.Parent.DailyReward.DailyReward,
		script.Parent.BoostMenu.BoostMenu
	}
	local ret = true
	for _,menu in pairs (microMenus) do
		if menu.Visible then
			ret = false
		end
	end
	return ret
end

--[[
	Assign part-ownership to each effect and enable
	@param ship: Ship containing the effects
]]
local function applyColorScriptEffects(ship)
	for _,part in pairs (ship:GetChildren()) do
		if part:FindFirstChild("ShipEffect") then
			local shipEffectScript = part.ShipEffect
			shipEffectScript.Part.Value = shipEffectScript.Parent
			shipEffectScript.Enabled = true
		end
	end
end

--------------------<< Effect Applications >>----------------------------------------

--[[
	Enlarge button when hovering over, revert back when mouse leaves
	@param button  Button receiving effect
	@param hoverSound  Sound if sound should play while hovering over button
]]
function GuiUtility.resizeButtonEffect(button, hoverSound)
	local startXSize, startYSize = button.Size.X.Scale, button.Size.Y.Scale
	local sizeTweenInfo = TweenInfo.new(.5, Enum.EasingStyle.Quint)
	button.MouseEnter:Connect(function()
		if hoverSound then hoverSound:Play() end
		TweenService:Create(button, sizeTweenInfo, {Size = UDim2.new(startXSize+.007, 0, startYSize+.007, 0)}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, sizeTweenInfo, {Size = UDim2.new(startXSize, 0, startYSize, 0)}):Play()					
	end)
end

--[[
	Given a part, apply the property changes from given colorInfo
	@param part  Part that will be changing
	@param colorPart  Reference from replicated storage of block with all color info
]]
function GuiUtility.applyColorData(part, colorPart)
	part.Color = colorPart.Color
	part.Material = colorPart.Material
	part.Transparency = colorPart.Transparency
	
	-- Apply Advanced properties (gradients, scripts, etc...)
	if #colorPart:GetChildren() > 0 then
		for _,v in pairs (colorPart:GetChildren()) do
			v = v:Clone()
			v.Parent = part
		end
	end
end

--[[
	Shake the button to emphasize its location
]]

function GuiUtility.buttonHopEffect(button, intensity)
	coroutine.resume(coroutine.create(function()
		local startY = button.Position.Y.Scale
		local upTween = TweenService:Create(
			button, 
			TweenInfo.new(.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), 
			{Position = UDim2.new(button.Position.X.Scale, 0, startY - intensity, 0)}
		)
		local downTween = TweenService:Create(
			button, 
			TweenInfo.new(.6, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), 
			{Position = UDim2.new(button.Position.X.Scale, 0, startY, 0)}
		)
		while button do
			upTween:Play()
			wait(.4)
			downTween:Play()
			wait(.6)
		end
	end))
end

-------------------<< Fade Functions >>------------------------
local blackScreen = script.Parent:WaitForChild("BlackScreen").BlackScreen

--[[
	Faster and more-manipulateable function for fading rather than fadeMenu()
	@param display  True if black screen should appear
	@param amount  Rate at which transparency is changed **[0.05 is frequently used]**
	@return  Boolean to tell other programs fade was successful
]]
function GuiUtility.blackMenuFade(display, amount)
	-- Set intitial values
	if not display then
		blackScreen.BackgroundTransparency = 0
	else
		blackScreen.BackgroundTransparency = 1
	end
	
	-- Change background transparency over time
	for t = 1,1/amount,1 do
		wait(.02)
		if not display then
			blackScreen.BackgroundTransparency += 0.05
		else
			blackScreen.BackgroundTransparency -= 0.05
		end
	end
	return true
end

--[[
	Helper method for fading a menu in and out, common functionality
	@param ui Menu being affected
	@param initialSet Making sure menu is initially this transparency
	@param change How Much we change transparency per second step
]]
local function fade(ui, initialSet, change)
	if ui:IsA("ImageButton") or ui:IsA("ImageLabel") then -- Images and ImageButtons
		ui.ImageTransparency = initialSet
	elseif ui:IsA("TextLabel") then
		ui.TextTransparency = initialSet
	else
		ui.BackgroundTransparency = initialSet
	end

	for t = 1,20,1 do
		--print(ui, ui.BackgroundTransparency, ui.Visible)
		wait(.02)

		if ui:IsA("ImageButton") or ui:IsA("ImageLabel") then
			ui.ImageTransparency += change
		elseif ui:IsA("TextLabel") then
			ui.TextTransparency += change
		else
			ui.BackgroundTransparency += change
		end
	end
end

--[[
	Fades a selected menu in or out, accounts for children UI
	@param menu Menu to be affected
	@param fadeOut True if menu should be faded out
]]
function GuiUtility.fadeMenu(menu, fadeOut)
	if fadeOut then
		if (#menu:GetChildren() == 0) then
			fade(menu, 0, 0.05)
		else
			for _,v in pairs (menu:GetChildren()) do
				coroutine.resume(coroutine.create(function()
					fade(v, 0, 0.05)
				end))
			end
		end

	else
		if (#menu:GetChildren() == 0) then
			fade(menu, 1, -0.05)
		else
			for _,v in pairs (menu:GetChildren()) do
				coroutine.resume(coroutine.create(function()
					fade(v, 1, -0.05)
				end))
			end
		end
	end
end

-----------------------<< Page Management >>------------------------------

--[[
	Create the common 5-page orientation of pages in a particular menu
	@param menu  Menu that the pages will be put into
	@param data  Cloned table of the data these pages are representing
	@param tileCount  Number of tiles summed throughout the pages
]]
local TILES_PER_PAGE = 5
function GuiUtility.pageLoad(menu, data, tileCount)
	-- Delete any previous pages
	for _,page in pairs (menu:GetChildren()) do
		if page:IsA("Page") and string.match(page.Name, "Page") ~= nil then
			page:Destroy()
		end
	end
	
	-- Create all pages to display the requested data
	local pageCount = math.ceil(tileCount/TILES_PER_PAGE)
	for p = 1,pageCount,1 do
		local page = guiElements.CustomizeMenuPage:Clone()
		page.Parent = menu
		page.Name = "Page" .. tostring(p)
		
		-- Give each page the appropriate number of tiles (last page may have <5)
		local tilesOnThisPage = TILES_PER_PAGE
		if tileCount < 5 then
			tilesOnThisPage = tileCount
			
			-- Remove tiles that won't be used on this page
			for t = 0,TILES_PER_PAGE-(tilesOnThisPage+1),1 do
				if page:FindFirstChild("Tile" .. tostring(TILES_PER_PAGE-t)) then
					page:FindFirstChild("Tile" .. tostring(TILES_PER_PAGE-t)):Destroy()
				end
			end
		end
		tileCount -= tilesOnThisPage
		page.Visible = p == 1
	end
	
	-- Add the basic info required on each tile
	if menu:FindFirstChild("Page1") then
		local pageNum = 0
		local itr = 0
		for _,d in pairs (data) do
			itr += 1
			if (itr-1)%TILES_PER_PAGE == 0 then
				pageNum += 1
			end
			local tileNum = itr-(TILES_PER_PAGE*(pageNum-1))
			local currentTile = menu:FindFirstChild("Page" .. tostring(pageNum)):FindFirstChild("Tile" .. tostring(tileNum))
			
			-- Change tiles for particular menu
			if menu.Name == "AchievementMenu" then
				local replacementTile = guiElements.AchievementTile:Clone()
				replacementTile.Parent = currentTile.Parent
				replacementTile.Name = currentTile.Name
				replacementTile.Position = currentTile.Position
				replacementTile.Size = currentTile.Size
				currentTile:Destroy()
				currentTile = replacementTile
				
				-- Adding extra data
				currentTile.Description.Text = d["Description"]
			end
			wait() -- Has to be preset for fonts to load correctly
			currentTile.TextLabel.Text = "<b>" .. d["Name"] .. "</b>"
			
			-- TODO:
			-- Font glitch again
			-- Some of the descriptions really have to squish in there
			
			
			
		end
	end
	
	local pageDisplay = menu:FindFirstChild('PageDisplay')
	if pageDisplay then
		pageDisplay.Text = '<b>1/' .. tostring(pageCount) .. '</b>'
	end
end

--[[
	Utility function for changing the pages of top-down scrolling menus
	@param menu  Menu that will have its pages changed
	@param direction  1 for down and -1 for up
	@param xMove  True if pages should move horizontally instead
]]
local pageChangeAvailable = true -- Acts as a debounce
function GuiUtility.changePage(menu, direction, xMove)
	if pageChangeAvailable then
		pageChangeAvailable = false
		script.Parent.Switch:Play()
		
		local currentPage = 0
		local pageCount = 0
		local nextPageNumber = 0
		for _,page in pairs(menu:GetChildren()) do
			if page:IsA("Frame") and string.match(page.Name, "Page") ~= nil then
				if page.Visible == true then
					currentPage = page
				end
				pageCount += 1
			end
		end
		
		local x, x2 = 0, 0
		local y, y2 = 0.9*direction, .02*direction
		if xMove then
			x = y; x2 = y2
			y = 0; y2 = 0
		end
		
		if pageCount > 1 then
			-- Determine what page needs to be displayed next
			local pageNumber = string.gsub(currentPage.Name, "Page", "")
			nextPageNumber = tonumber(pageNumber) + direction
			if nextPageNumber < 1 then
				nextPageNumber = pageCount
			elseif nextPageNumber > pageCount then
				nextPageNumber = 1
			end
			
			-- Update the page display
			local pageDisplay = menu:FindFirstChild('PageDisplay')
			if pageDisplay then
				pageDisplay.Text = '<b>' .. tostring(nextPageNumber) .. '/' .. tostring(pageCount) .. '</b>'
			end
			
			if menu:FindFirstChild("Page" .. tostring(nextPageNumber)) then
				local newPage = menu:FindFirstChild("Page" .. tostring(nextPageNumber))
				local pageChangeTweenInfo = TweenInfo.new(.9, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				TweenService:Create(currentPage, pageChangeTweenInfo, {Position = UDim2.new(-x, 0, -y, 0)}):Play()
				newPage.Position = UDim2.new(x, 0, y, 0)
				newPage.Visible = true
				TweenService:Create(newPage, pageChangeTweenInfo, {Position = UDim2.new(0, 0, 0, 0)}):Play()

				-- Fix all the fonts on the newly-displayed page (since Roblox's new fonts are glitchy)
				for _,tile in pairs (newPage:GetChildren()) do
					if tile:FindFirstChild("TextLabel") then
						tile.TextLabel.Font = Enum.Font.Code
						tile.TextLabel.Font = Enum.Font.Michroma
					end
				end

				wait(.6)
				currentPage.Visible = false
				currentPage.Position = UDim2.new(0, 0, 0, 0)
			end
		else -- Bounce effect
			local bounceTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
			TweenService:Create(currentPage, bounceTweenInfo, {Position = UDim2.new(-x2, 0, -y2, 0)}):Play()
			wait(.15)
			bounceTweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
			TweenService:Create(currentPage, bounceTweenInfo, {Position = UDim2.new(0, 0, 0, 0)}):Play()
			wait(.35)
		end
		
		pageChangeAvailable = true
	end
end

--------------------<< 3D-Model Viewport Functions >>-----------------------------

--[[
	Some viewports must ensure that other viewports are disabled
	@param viewPort  Viewport that will still be displayed
]]
function GuiUtility.hideOtherViewPorts(viewPort)
	local myShipMenu = script.Parent.MyShipMenu
	if viewPort == nil then
		myShipMenu.LaserView.Enabled = false
		myShipMenu.MyShipView.Enabled = false
		myShipMenu.SmallMyShipView.Enabled = false
		
	elseif viewPort.Parent:IsA("SurfaceGui") then
		viewPort.Parent.Enabled = true
		if viewPort.Name == "ShipViewPort" then
			myShipMenu.SmallMyShipView.Enabled = false
			myShipMenu.LaserView.Enabled = false
		else
			myShipMenu.LaserView.Enabled = true
			myShipMenu.MyShipView.Enabled = false
		end
	end
end

--[[
	Display a particular level of the player's equipped ship as a rotating model in a viewport
	@param player  Need to have reference so can get their EquipData
	@param viewPort  viewPort that is displaying the player's ship
	@param level  Level the player wishes to see of their ship
	@param equipData  Data about a ship if displaying something other than what player has currently equipped
]]
function GuiUtility.displayPlayerShip(player, viewPort, level, shipModelInfo)
	local equipData = getEquippedInfoEvent:InvokeServer(player)
	if shipModelInfo == nil then
		shipModelInfo = equipData[1]["Model"]
	end
	local ship = shipModelInfo:FindFirstChild("Level" .. tostring(level)).Handle:Clone()
	
	-- Appropriately color the player's ship (w/ colors they have equipped)
	for _,part in pairs (ship:GetChildren()) do
		if part.Name == "PrimaryColorPart" then
			GuiUtility.applyColorData(part, equipData[5]["Color"])
		elseif part.Name == "SecondaryColorPart" then
			GuiUtility.applyColorData(part, equipData[6]["Color"])
		elseif part.Name == "Number" then
			part.Color = equipData[7]['Color'].Color
		end
	end
	applyColorScriptEffects(ship)
	
	ship.GUI_Display:Destroy() -- Don't want this getting in way of 3D display
	-- ship.Hitbox:Destroy()
	GuiUtility.display3DModels(viewPort, ship, true, -35)
end

--[[
	Give a spinning 3D Render of a model in a viewport frame
	@param viewport  Viewport object will be displayed in
	@param displayModel  Model that will be displayed in the view port
	@param bool  True if model is being displayed
	@param displayAngle  How tilted the camera should be looking at the object
]]
function GuiUtility.display3DModels(viewPort, displayModel, bool, displayAngle)
	--possibly clear all viewports once menu is closed? (or once viewport is not visible?)
	--print("Display3DModels: ", Player, viewport, displayModel, bool, displayAngle)
	if bool == true then
		GuiUtility.display3DModels(viewPort, displayModel:Clone(), false) --reset current viewPort

		local ParentModel = Instance.new("Model", viewPort.Physics)
		displayModel.Parent = ParentModel
		
		local rootPart
		if displayModel:IsA("Model") then --Multi-part item
			rootPart = displayModel.Target

			if displayModel:FindFirstChild("GenerationPosition") then
				displayModel.GenerationPosition:Destroy()
			end

		else
			rootPart = displayModel
		end

		displayModel = ParentModel

		if viewPort:FindFirstChild("Camera") then
			viewPort.Camera:Destroy()
		end
		local vpCamera = Instance.new("Camera",viewPort)

		rootPart.Name = "RootPart"
		rootPart.Anchored = true
		viewPort.CurrentCamera = vpCamera

		--Move Camera Around Object & Auto FOV
		local referenceAngle = Instance.new("NumberValue", rootPart)
		referenceAngle.Name = "ReferenceAngle"
		referenceAngle.Value = displayAngle

		if viewPort.Physics:FindFirstChild("Model") then
			local parentModel = viewPort.Physics.Model
			parentModel.PrimaryPart = rootPart
			parentModel:SetPrimaryPartCFrame(parentModel:GetPrimaryPartCFrame()*CFrame.fromEulerAnglesXYZ(math.rad(referenceAngle.Value),0,0))
		end

		local modelCenter, modelSize = displayModel:GetBoundingBox()	

		local rotInv = (modelCenter - modelCenter.p):inverse()
		modelCenter = modelCenter * rotInv
		modelSize = rotInv * modelSize
		modelSize = Vector3.new(math.abs(modelSize.x), math.abs(modelSize.y), math.abs(modelSize.z))

		local diagonal = 0
		local maxExtent = math.max(modelSize.x, modelSize.y, modelSize.z)
		local tan = math.tan(math.rad(vpCamera.FieldOfView/2))

		if (maxExtent == modelSize.x) then
			diagonal = math.sqrt(modelSize.y*modelSize.y + modelSize.z*modelSize.z)/2
		elseif (maxExtent == modelSize.y) then
			diagonal = math.sqrt(modelSize.x*modelSize.x + modelSize.z*modelSize.z)/2
		else
			diagonal = math.sqrt(modelSize.x*modelSize.x + modelSize.y*modelSize.y)/2
		end
		
		-- Change number dividing maxExtent to bring model closer or farther away
		local minDist = (maxExtent/10)/tan + diagonal
		game:GetService("RunService").RenderStepped:Connect(function(dt)
			referenceAngle.Value += (1*dt*60)/3
			vpCamera.CFrame = modelCenter * CFrame.fromEulerAnglesYXZ(0, math.rad(referenceAngle.Value + 180), 0) * CFrame.new(0, 0, minDist + 3)
			-- +180 is present to have ship facing the camera when it is first spawned into the viewport
		end)
	else
		viewPort.CurrentCamera = nil
		for _,view in pairs (viewPort.Physics:GetChildren()) do
			view:Destroy()
		end
	end
end


--[[
	Clicking on the viewPort currently displaying an object will reset the viewport
	@param viewPort  Viewport currently displaying an object
	@param displayModel  Object currently being displayed in the viewport
	@param angle  Angle of the camera while viewing the object in the viewport
]]
function GuiUtility.Reset3DObject(viewPort, displayModel, angle)
	viewPort.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1) then
			if displayModel == nil then
				local differentDisplayModel = viewPort.Physics.Model.RootPart
				local differentAngle = viewPort.Physics.Model.RootPart.ReferenceAngle.Value
				if differentDisplayModel ~= nil then
					GuiUtility.display3DModels(viewPort, differentDisplayModel:Clone(), true, differentAngle)
				end
			else
				GuiUtility.display3DModels(viewPort, displayModel:Clone(), true, angle)
			end
		end
	end)
end


------------------<< Dealing with Numbers >>------------------------------------

--[[
	Convert seconds to days, hours, and minutes display
	(Display to 2 places unless extraTimePreview; then display 3)
]]
function GuiUtility.ToDHMS(sec, extraTimePreview)
	local Days = math.floor(sec/(24*3600))
	local Hours = math.floor((sec/3600) % 24)
	local Minutes = math.round((sec/60) % 60) -- Minimum display

	local TimeTable = {Days, "d", Hours, "h", Minutes, "m"}
	local FormatString = ""

	local Display1
	local Display2
	local Display3
	for i,t in pairs (TimeTable) do
		if type(t) == "number" and t ~= 0 then
			local LetterRefernece = TimeTable[i+1]
			if Display1 == nil then
				FormatString = FormatString .. "%01i" .. LetterRefernece
				Display1 = t
			elseif Display2 == nil then
				FormatString = FormatString .. " %01i" .. LetterRefernece
				Display2 = t
			elseif Display3 == nil and extraTimePreview then -- extraTimePreview requires more exact display
				FormatString = FormatString .. " %01i" .. LetterRefernece
				Display3 = t
			end
		end
	end

	if Display1 then
		return string.format(FormatString, Display1, Display2, Display3)
	else
		return string.format("%01im", 0) -- 0 seconds
	end
end

--[[
	Simplify a number to be displayed in decimal form
	@param num  Number to be simplified
	@return  Simplified text-version of the passed-in number
]]
function GuiUtility.simplifyNumber(num)
	local x = tostring(num)

	if #x>=10 then
		local important = (#x-9)
		local decimal = (x:sub(#x-7,(#x-7)))
		if decimal == '0' then
			return x:sub(0,(important)).."B"
		else
			return x:sub(0,(important))..".".. decimal .."B"
		end
	elseif #x>=7 then
		local important = (#x-6)
		local decimal = (x:sub(#x-5,(#x-5)))
		if decimal == '0' then
			return x:sub(0,(important)).."M"
		else
			return x:sub(0,(important)).."."..decimal.."M"
		end
		
	elseif #x>=4 then
		local important = (#x-3)
		local decimal = (x:sub(#x-2,(#x-2)))..(x:sub(#x-1,(#x-1)))
		if decimal == '00' then
			return x:sub(0,(important)).."K"
		else
			return x:sub(0,(important))..".".. decimal .. "K"
		end
	else
		return num
	end
end


return GuiUtility
