
local player = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")

local eventsFolder = game.ReplicatedStorage:WaitForChild('Events')
local guiEventsFolder = eventsFolder:WaitForChild('GUI')
local updateLevelBarEvent = guiEventsFolder:WaitForChild('UpdateLevelBar')

local levelUpBar = script.Parent:WaitForChild('LevelUpBar')
local trueBar = levelUpBar:WaitForChild('LevelUpBar')
local progressBar = trueBar:WaitForChild('Progress'):WaitForChild('Bar')
local levelProgressLabel = trueBar:WaitForChild('LevelProgress')

local MIN_LENGTH = 0.035

local fieldUpgradesUI = script.Parent.Parent:WaitForChild('FieldUpgrades')
local materialCount = fieldUpgradesUI:WaitForChild('FieldUpgrades'):WaitForChild('MaterialCount')
--[[
	Update the materials display for the field upgrades
	@param materials: The amound of materials the player has
]]
local function updateFieldUpgradesMaterialsLabel(materials)
	TweenService:Create(materialCount, TweenInfo.new(.1), {Size = UDim2.new(materialCount.Size.X.Scale, 0, 0.031, 0)}):Play()
	wait(.1)
	materialCount.Text = "$" .. tostring(materials)
	TweenService:Create(materialCount, TweenInfo.new(.1), {Size = UDim2.new(materialCount.Size.X.Scale, 0, .027, 0)}):Play()
end

--[[
	Display or hide the FieldUpgrades UI
	@param display: True if the menu should be displayed
]]
local function displayFieldUpgradesUI(display)
	local position = UDim2.new(-.32, 0, 0, 0)
	if display then
		position = UDim2.new(0, 0, 0, 0)
		materialCount.Text = "Materials:  0"
		for _,frame in pairs (fieldUpgradesUI:WaitForChild('FieldUpgrades'):GetChildren()) do
			if frame:IsA("Frame") then
				frame.Cost.Text = "$250"
				frame.Level.Text = "1"
				frame.InfoView.Visible = true
			end
		end
	else
		for _,frame in pairs (fieldUpgradesUI.FieldUpgrades:GetChildren()) do
			if frame:IsA("Frame") then
				frame.InfoView.Visible = false
			end
		end
	end
	TweenService:Create(fieldUpgradesUI.FieldUpgrades, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Position = position}):Play()
end

-- Show the exp bar when the player starts the game
script.Parent.Parent:WaitForChild('MainMenu'):WaitForChild('MainMenu'):WaitForChild('PlayButton').Activated:Connect(function()
	wait(1)
	levelUpBar.Position = UDim2.new(levelUpBar.Position.X.Scale, 0, 1.1, 0)
	levelUpBar.Visible = true
	levelProgressLabel.Text = "Lvl 1 1/74"
	progressBar.Size = UDim2.new(MIN_LENGTH, 0, 1, 0)
	TweenService:Create(levelUpBar, TweenInfo.new(0.7), {Position = UDim2.new(levelUpBar.Position.X.Scale, 0, 0.894, 0)}):Play()
	displayFieldUpgradesUI(true)
end)

--[[
	Update the level bar that the player sees
	@param materials: The amount of materials the player has
	@param minMaterials: The minimum amount of materials for the player to stay at their level
	@param totalMaterials: The amount of total materials needed to complete the player's current level
	@param level: The player's current level
]]
updateLevelBarEvent.OnClientEvent:Connect(function(materials, totalMaterials, minMaterials, level)
	if materials <= 0 then -- Hide the bar
		levelProgressLabel.Text = 'YOU DIED'
		TweenService:Create(levelUpBar, TweenInfo.new(0.7), {Position = UDim2.new(levelUpBar.Position.X.Scale, 0, 1.1, 0)}):Play()
		displayFieldUpgradesUI(false)
		wait(0.7)
		levelUpBar.Visible = false
	elseif totalMaterials and minMaterials then
		local levelProgress = (materials-minMaterials)/(totalMaterials-minMaterials)
		local barProgress = (1 - MIN_LENGTH) * levelProgress
		local newSize = UDim2.new(MIN_LENGTH + barProgress, 0, 1, 0)
		
		levelProgressLabel.Text = "Lvl " .. tostring(level) .. " " .. tostring(materials) .. "/" .. tostring(totalMaterials) -- Subtract both by minMaterials to get level-specific count
		TweenService:Create(progressBar, TweenInfo.new(.25), {Size = newSize}):Play()
	else -- Max Level
		levelProgressLabel.Text = "Lvl MAX " .. tostring(materials) .. "/42000"
		TweenService:Create(progressBar, TweenInfo.new(.25), {Size = UDim2.new(1, 0, 1, 0)}):Play()
	end
	updateFieldUpgradesMaterialsLabel(materials)
end)
levelUpBar.Visible = false

displayFieldUpgradesUI(false)
