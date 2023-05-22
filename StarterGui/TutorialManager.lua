local player = game.Players.LocalPlayer
local UserInputService = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')

local MusicPlayer = require(script.Parent.Parent:WaitForChild('Music'):WaitForChild('MusicPlayer'))
local GuiUtility = require(script.Parent.Parent:WaitForChild('GuiUtility'))

local guiEventsFolder = game.ReplicatedStorage:WaitForChild('Events'):WaitForChild('GUI')
local tutorialScreenDoneEvent = guiEventsFolder:WaitForChild('TutorialScreenDone')

local background = script.Parent:WaitForChild('Background')
local tips = background:WaitForChild('Tips')
local loadNameDisplay = background:WaitForChild('LoadNameDisplay')
local skipNotify = background:WaitForChild('SkipNotify')
local loading = background:WaitForChild('Loading')

--[[
	Provide more 'textile' feedback to player waiting for tips menu to be hidden.
	Wave effect for tiles on the screen, small bounce for LoadNameDisplay
	@param menu: Menu that contains tiles that will be bouncing
	@param change: How tile will change with bounce effect
]]
local function menuBounceBehavior(menu, change)
	menu:WaitForChild('BounceEnabled').Value = true
	loading.Text = 'Finalizing Assets'
	coroutine.resume(coroutine.create(function()
		while menu.BounceEnabled.Value do
			wait(1.4)
			for _,tile in pairs (menu:GetChildren()) do
				if string.match(tile.Name, "Tile") then
					spawn(function()
						local startPosition = tile.Position
						TweenService:Create( -- Up
							tile,
							TweenInfo.new(.4, Enum.EasingStyle.Quint),
							{Position = startPosition + change}
						):Play()
						wait(.4)
						TweenService:Create( -- Down
							tile, 
							TweenInfo.new(.2),
							{Position = startPosition}
						):Play()
					end)
					wait(.3)
				end
			end
			loading.Text = loading.Text .. '.' -- Add another period to loading
			
			-- Bounce load name display
			local startPosition = loadNameDisplay.Position
			if menu.BounceEnabled.Value then
				TweenService:Create( -- Up
					loadNameDisplay, 
					TweenInfo.new(.2),
					{Position = startPosition + UDim2.new(0, 0, -.007, 0)}
				):Play()
			end
			wait(.2)
			if menu.BounceEnabled.Value then
				TweenService:Create( -- Down
					loadNameDisplay, 
					TweenInfo.new(.4, Enum.EasingStyle.Bounce),
					{Position = startPosition}
				):Play()
			end
		end 
	end))
end

--[[
	Once all menus have been cycled through or player has decided to skip tips, hide tutorial menu
]]
local hiding = false
local function hideTutorialMenu()
	if not hiding then
		hiding = true
		
		-- Stop all bounce loops from happening
		for _,menu in pairs (tips:GetChildren()) do
			if menu:FindFirstChild('BounceEnabled') then
				menu.BounceEnabled.Value = false
			end
		end
		
		-- Hide the overall tutorial menu
		TweenService:Create(background, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(0, 0, -1, 0)}):Play()
		tutorialScreenDoneEvent:Fire() -- Notify ControllerDetection it can check availability
		wait(1)
		background.Visible = false
		background.Position = UDim2.new(0, 0, 0, 0)
	end
end

--[[
	Move the new tiles onto the screen
	@param menu: Frame containing the tiles being showcased to the player
	@param number: Number id of the menu being displayed
]]
local function displayNewMenu(menu, number)
	local tile1 = menu:WaitForChild('Tile1')
	local tile2 = menu:WaitForChild('Tile2')
	local tile3 = menu:WaitForChild('Tile3')
	
	if number == 2 then -- Show availability of skip
		TweenService:Create(
			loading, 
			TweenInfo.new(1.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), 
			{Position = UDim2.new(loading.Position.X.Scale, 0, 1.1, 0)}
		):Play()
		wait(1.2)
		loading.Visible = false; loading.Position = UDim2.new(loading.Position.X.Scale, 0, 0.892, 0)
		skipNotify.Visible = true; skipNotify.Position = UDim2.new(skipNotify.Position.X.Scale, 0, 1.1, 0)
		TweenService:Create(
			skipNotify,
			TweenInfo.new(1.2, Enum.EasingStyle.Quint), 
			{Position = UDim2.new(skipNotify.Position.X.Scale, 0, .955, 0)}
		):Play()
		
		-- Make skipping the tutorial screen available
		UserInputService.InputBegan:Connect(function()
			if background.Visible then
				hideTutorialMenu()
			end
		end)
	end
	
	-- Move loadNameDisplay into frame
	loadNameDisplay.Position = UDim2.new(-1, 0, loadNameDisplay.Position.Y.Scale, 0)
	loadNameDisplay.Text = menu:WaitForChild('LoadLabel').Value
	loadNameDisplay.Visible = true
	TweenService:Create(loadNameDisplay, TweenInfo.new(.7, Enum.EasingStyle.Quint), {Position = UDim2.new(.045, 0, loadNameDisplay.Position.Y.Scale, 0)}):Play()
	
	-- Move tiles into frame
	if number % 2 ~= 0 then -- Tall
		tile1.Position = UDim2.new(tile1.Position.X.Scale, 0, -0.8, 0)
		tile2.Position = UDim2.new(tile2.Position.X.Scale, 0, -0.8, 0)
		tile3.Position = UDim2.new(tile3.Position.X.Scale,  0, -0.8, 0)
		
		menu.Visible = true
		
		TweenService:Create(tile1, TweenInfo.new(.5, Enum.EasingStyle.Quart), {Position = UDim2.new(tile1.Position.X.Scale, 0, .064, 0)}):Play()
		wait(.4)
		TweenService:Create(tile2, TweenInfo.new(.5, Enum.EasingStyle.Quart), {Position = UDim2.new(tile2.Position.X.Scale, 0, .064, 0)}):Play()
		wait(.4)
		TweenService:Create(tile3, TweenInfo.new(.5, Enum.EasingStyle.Quart), {Position = UDim2.new(tile3.Position.X.Scale, 0, .064, 0)}):Play()
		wait(.7)
		menuBounceBehavior(menu, UDim2.new(0, 0, -.02 ,0))
	else -- Long
		tile1.Position = UDim2.new(-.9, 0, tile1.Position.Y.Scale, 0)
		tile2.Position = UDim2.new(1.05, 0, tile2.Position.Y.Scale, 0)
		tile3.Position = UDim2.new(-.9,  0, tile3.Position.Y.Scale, 0)

		menu.Visible = true

		TweenService:Create(tile1, TweenInfo.new(.5, Enum.EasingStyle.Quart), {Position = UDim2.new(0.074, 0, tile1.Position.Y.Scale, 0)}):Play()
		wait(.4)
		TweenService:Create(tile2, TweenInfo.new(.5, Enum.EasingStyle.Quart), {Position = UDim2.new(0.074, 0, tile2.Position.Y.Scale, 0)}):Play()
		wait(.4)
		TweenService:Create(tile3, TweenInfo.new(.5, Enum.EasingStyle.Quart), {Position = UDim2.new(0.074, 0, tile3.Position.Y.Scale, 0)}):Play()
		wait(.7)
		menuBounceBehavior(menu, UDim2.new(.01, 0, 0 ,0))
	end
end

--[[
	Move the old tiles out of the way
	@param menu: Frame containing the tiles being showcased to the player
	@param number: Number id of the menu being displayed
]]	
local function hideOldMenu(menu, number)
	local tile1 = menu:WaitForChild('Tile1')
	local tile2 = menu:WaitForChild('Tile2')
	local tile3 = menu:WaitForChild('Tile3')
	menu.BounceEnabled.Value = false
	
	-- Move loadNameDisplay out of frame
	TweenService:Create(
		loadNameDisplay, 
		TweenInfo.new(.7, Enum.EasingStyle.Quint, Enum.EasingDirection.In), 
		{Position = UDim2.new(1.05, 0, loadNameDisplay.Position.Y.Scale, 0)}
	):Play()
	
	-- Move tiles up
	if number % 2 ~= 0 then -- Tall
		TweenService:Create(tile1, TweenInfo.new(.5), {Position = UDim2.new(tile1.Position.X.Scale,  0, -0.8, 0)}):Play()
		wait(.4)
		TweenService:Create(tile2, TweenInfo.new(.5), {Position = UDim2.new(tile2.Position.X.Scale,  0, -0.8, 0)}):Play()
		wait(.4)
		TweenService:Create(tile3, TweenInfo.new(.5), {Position = UDim2.new(tile3.Position.X.Scale,  0, -0.8, 0)}):Play()
	else -- Long
		TweenService:Create(tile1, TweenInfo.new(.5), {Position = UDim2.new(-.9, 0, tile1.Position.Y.Scale, 0)}):Play()
		wait(.4)
		TweenService:Create(tile2, TweenInfo.new(.5), {Position = UDim2.new(1.05, 0, tile2.Position.Y.Scale, 0)}):Play()
		wait(.4)
		TweenService:Create(tile3, TweenInfo.new(.5), {Position = UDim2.new(-.9, 0, tile3.Position.Y.Scale, 0)}):Play()
	end
	wait(.4)
end

--[[
	Start the tutorial menu once loading screen has finished, making the tutorial menu visible
]]
background.Visible = false
background:GetPropertyChangedSignal('Visible'):Connect(function()
	if background.Visible then
		-- Ensure all menus are loaded and invised
		wait(#background:WaitForChild('Tips'):GetChildren() == 4)
		for _,v in pairs (tips:GetChildren()) do
			v.Visible = false
		end
		loading.Visible = true; loadNameDisplay.Visible = false; skipNotify.Visible = false
		tips.Menu1.Position = UDim2.new(0, 0, 0, 0)
		
		-- Begin music
		coroutine.resume(coroutine.create(function()
			local MusicPlayer = require(player.PlayerGui:WaitForChild("Music"):WaitForChild("MusicPlayer"))
			MusicPlayer.playSong("MainMenu", "Christmas Lights In The Sky", 5, false, false, "MainMenu")
		end))
		
		-- Fade out black screen to display tutorial menu
		wait(1.5)
		GuiUtility.blackMenuFade(false, .05)
		
		-- Display each menu
		for i,_ in pairs (tips:GetChildren()) do
			local menu = tips:FindFirstChild("Menu" .. tostring(i))
			displayNewMenu(menu, i)
			wait(10)
			hideOldMenu(menu, i)
			wait(1)
		end
		
		hideTutorialMenu()
	end
end)
