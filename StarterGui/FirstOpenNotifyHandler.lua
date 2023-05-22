local TweenService = game:GetService('TweenService')

-- What to do when script is enabled
local mainMenu = script.Parent.Parent:WaitForChild('MainMenu'):WaitForChild('MainMenu')
local notify = false-- script.Parent:WaitForChild('Notify')
local hoverSound = script.Parent.Parent:WaitForChild('ButtonHover')
local pressSound = script.Parent.Parent:WaitForChild('ButtonPress')

if notify then
	--[[
		Close the menu (function since called from button and if force closed like when game starts)
	]]
	local function closeMenu()
		script.Parent:WaitForChild('MenuClose'):Play()
		TweenService:Create(notify, TweenInfo.new(.7, Enum.EasingStyle.Quint), {Position = UDim2.new(notify.Position.X.Scale, 0, -.55, 0)}):Play()
		wait(.7)
		notify.Visible = false
	end
	notify:WaitForChild('HideMenu').Activated:Connect(function()
		closeMenu()
	end)
	notify:WaitForChild('HideMenu').MouseEnter:Connect(function()
		hoverSound:Play()
	end)


	--[[
		Display/Hide the first-open notify
		@param display: True fi the first-open notify should be displayed
	]]
	local displayDebounce = false
	function displayMenu(display)
		if not displayDebounce then
			displayDebounce = true
			if display then
				notify.Position = UDim2.new(notify.Position.X.Scale, 0, -.55, 0)
				notify.Visible = true
				TweenService:Create(notify, TweenInfo.new(0.7, Enum.EasingStyle.Quint), {Position = UDim2.new(notify.Position.X.Scale, 0, 0.5, 0)}):Play()
			else
				closeMenu()
			end
			displayDebounce = false
		end
	end
	displayMenu(true)


	-- Open script when main menu becomes visible





	-- Close the display if the main menu is invisible or the close button is pressed
end
