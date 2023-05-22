local player = game.Players.LocalPlayer

local TweenService = game:GetService('TweenService')

local eventsFolder = game.ReplicatedStorage:WaitForChild('Events')
local clientDestroyPlayerShipEvent = eventsFolder:WaitForChild('ClientDestroyPlayerShip')
local doFieldUpgradeEvent = eventsFolder:WaitForChild('DoFieldUpgrade')
local getFieldUpgradeDataEvent = eventsFolder:WaitForChild('GetFieldUpgradeData')

local guiEventsFolder = eventsFolder:WaitForChild('GUI')
local displayDeathScreenEvent = guiEventsFolder:WaitForChild('DisplayDeathScreen')

local fieldUpgrades = script.Parent:WaitForChild('FieldUpgrades')
local equipSound = script.Parent.Parent:WaitForChild('Equip')
local errorSound = script.Parent.Parent:WaitForChild('Error')
local hoverSound = script.Parent.Parent:WaitForChild('ButtonHover')
local pressSound = script.Parent.Parent:WaitForChild('ButtonPress')
local grayColor = script.Parent:WaitForChild('DisabledValue')

--[[
	Display a small info menu when the player hovers over a purchase button for a field upgrad
	@param button: The button currently being hovered over
	@param display: True if the mouse is in the button
]]
local function displayHoverMenu(button, display)
	local infoView = button.Parent.InfoView
	local hoverMenuDebounce = infoView.DisplayDebounce
	if not hoverMenuDebounce.Value then
		hoverMenuDebounce.Value = true
		if display then
			local fieldUpgradeName = button.Parent.Prompt.Text
			local currentLevelBenefit = getFieldUpgradeDataEvent:InvokeServer(fieldUpgradeName)
			local nextLevelBenefit = getFieldUpgradeDataEvent:InvokeServer(fieldUpgradeName, true)
			
			-- Movement
			infoView.Position = button.Position
			TweenService:Create(infoView, TweenInfo.new(1.2, Enum.EasingStyle.Quint), {Position = UDim2.new(1.26, 0, .5, 0)}):Play()
			TweenService:Create(infoView, TweenInfo.new(1.2, Enum.EasingStyle.Quint), {Size = UDim2.new(0.388, 0, 1.18, 0)}):Play()
			
			if currentLevelBenefit == nil or nextLevelBenefit == nil then
				infoView.DoneLabel.Visible = true
				infoView.CurrentBenefit.Visible = false
				infoView.NextLevelBenefit.Visible = false
				infoView.Arrow.Visible = false
			else
				infoView.DoneLabel.Visible = false
				infoView.CurrentBenefit.Visible = true
				infoView.NextLevelBenefit.Visible = true
				infoView.Arrow.Visible = true
			end
			
			-- Appropraite labels
			if fieldUpgradeName == "Boost Regen" then
				infoView.CurrentBenefit.Text = tostring(currentLevelBenefit) .. "s"
				infoView.NextLevelBenefit.Text = tostring(nextLevelBenefit) .. "s"
			elseif fieldUpgradeName == "Camera Distance" then
				infoView.CurrentBenefit.Text = "+" .. tostring(currentLevelBenefit)
				infoView.NextLevelBenefit.Text = "+" .. tostring(nextLevelBenefit)
			else
				if currentLevelBenefit < 1 then
					infoView.CurrentBenefit.Text = tostring(currentLevelBenefit*100) .. "%"
				else
					infoView.CurrentBenefit.Text = tostring(currentLevelBenefit)
				end
				if nextLevelBenefit < 1 then
					infoView.NextLevelBenefit.Text = tostring(nextLevelBenefit*100) .. "%"
				else
					infoView.NextLevelBenefit.Text = tostring(nextLevelBenefit)
				end
			end
			wait(2)
			
			infoView.Position = UDim2.new(1.26, 0, .5, 0)
			TweenService:Create(infoView, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Position = UDim2.new(1.027, 0, .5, 0)}):Play()
			TweenService:Create(infoView, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Size = UDim2.new(.2, 0, .6, 0)}):Play()
		end
		hoverMenuDebounce.Value = false
	end
end


wait(#fieldUpgrades:GetChildren() == 6)
for _,frame in pairs (fieldUpgrades:GetChildren()) do
	if frame:IsA("Frame") then
		local button = frame:WaitForChild('TextButton')
		local levelLabel = frame:WaitForChild('Level')
		local promptLabel = frame:WaitForChild('Prompt')
		local costLabel = frame:WaitForChild('Cost')
		local infoView = frame:WaitForChild('InfoView')
		
		TweenService:Create(infoView, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Position = UDim2.new(1.027, 0, .5, 0)}):Play()
		TweenService:Create(infoView, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Size = UDim2.new(.2, 0, .6, 0)}):Play()
		
		button.Activated:Connect(function()
			if levelLabel.Text ~= '[MAX]' then
				local currentLevel = tonumber(levelLabel.Text)
				
				-- Apply upgrades unless otherwise max level
				if currentLevel < 5 and currentLevel > 0 then
					local success, newCost = doFieldUpgradeEvent:InvokeServer(frame.Prompt.Text)
					
					if success then
						local newLevel = currentLevel + 1
						if newLevel >= 5 then
							levelLabel.Text = "[MAX]"
							costLabel.Text = ""
						else
							levelLabel.Text = tostring(newLevel)
							costLabel.Text = "$" .. tostring(newCost)
						end
						equipSound:Play()
					else
						errorSound:Play()
					end
				else
					errorSound:Play()
				end
			else
				errorSound:Play()
			end
		end)
		button.MouseEnter:Connect(function()
			if button.BackgroundColor3 ~= grayColor then
				hoverSound:Play()
				displayHoverMenu(button, true)
				wait(1)
			end
		end)
	end
end

fieldUpgrades:WaitForChild('MaterialCount').Text = "..."


-- Show and hide behavior is done in LevelBarHandler.lua
